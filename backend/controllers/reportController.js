import mongoose from "mongoose";
import Employee from "../models/employeeModel.js";
import Attendance from "../models/attendanceModel.js";
import Branch from "../models/branchModel.js"
import PayrollResult from "../models/payrollResultModel.js";
import { SalaryDetails } from "../models/salaryDetailsModel.js";
import { LeaveAndBalance } from "../models/leaveBalanceModel.js";
import EarningTransaction from "../models/EarningTransactionModel.js";
import AdvanceLedger from "../models/advanceLedgerModel.js";
import { PenaltyAndOvertime } from "../models/penaltyAndOvertimeModel.js";
import Company from "../models/companyModel.js";
import ReportHistory from "../models/reportHistoryModel.js";

// === UTILS ===
const formatDate = (date) => date ? new Date(date).toISOString().split('T')[0] : "-";
const formatTime = (date) => date ? new Date(date).toLocaleTimeString('en-IN', { hour: '2-digit', minute: '2-digit', hour12: true }) : "-";
const safeNum = (val) => {
    const num = Number(val);
    return isNaN(num) ? 0 : num;
};

// =========================================================
// === HELPER: EXACT PAYROLL CALCULATOR (From Your Code)
// =========================================================
const calculatePayrollForEmployee = async (employee, month, year, companyMap) => {
    try {
        const employeeId = employee._id;

        // 1. Fetch Related Data
        const [salaryDetails, attendanceDoc, penaltyPolicy, advanceLedgers, earningsTx, leaveBalanceDoc] = await Promise.all([
            SalaryDetails.findOne({ employeeId }).lean() || {},
            Attendance.findOne({ employeeId }).lean(),
            PenaltyAndOvertime.findOne({ employeeId }).lean(),
            AdvanceLedger.find({ employeeId, status: 'Active' }).lean() || [],
            EarningTransaction.find({ 
                employeeId, 
                payMonth: Number(month), 
                payYear: Number(year), 
                processed: false 
            }).lean() || [],
            LeaveAndBalance.findOne({ employeeId }).lean()
        ]);

        // 2. Initialize Stats
        const totalDaysInMonth = new Date(year, month, 0).getDate();
        let doj = new Date("1900-01-01"); 
        if (employee.employment?.[0]?.dateOfJoining) {
            doj = new Date(employee.employment[0].dateOfJoining);
        }

        let stats = {
            daysInMonth: totalDaysInMonth,
            presentDays: 0, weekOffs: 0, holidays: 0, paidLeaves: 0, unpaidLeaves: 0, 
            lateCount: 0, earlyCount: 0, overtimeHours: 0, payableDays: 0, totalPayableHours: 0
        };

        // 3. Build Attendance Map
        const attendanceMap = {};
        if (attendanceDoc) {
            let records = [];
            if (attendanceDoc.monthlyAttendance && Array.isArray(attendanceDoc.monthlyAttendance)) {
                const mRecord = attendanceDoc.monthlyAttendance.find(m => m.month === Number(month) && m.year === Number(year));
                if (mRecord) records = mRecord.records;
            } else if (attendanceDoc.month === Number(month) && attendanceDoc.year === Number(year)) {
                records = attendanceDoc.records;
            }
            if (records) records.forEach(r => { 
                if(r.date) attendanceMap[new Date(r.date).toDateString()] = r; 
            });
        }

        // 4. DAY-BY-DAY ITERATION
        const dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
        const getDayConfig = (dayName) => {
            const workTimings = attendanceDoc?.workTimings || {};
            if (workTimings.scheduleType === "Fixed" && workTimings.fixed?.days) {
                return workTimings.fixed.days.find(d => d.day === dayName);
            }
            return null;
        };

        for (let day = 1; day <= totalDaysInMonth; day++) {
            const currentDate = new Date(year, month - 1, day);
            const dateKey = currentDate.toDateString();
            const dayName = dayNames[currentDate.getDay()];
            
            currentDate.setHours(0,0,0,0);
            const dojCompare = new Date(doj);
            dojCompare.setHours(0,0,0,0);

            if (currentDate < dojCompare) continue; 

            const record = attendanceMap[dateKey];
            const dayConfig = getDayConfig(dayName);

            if (record) {
                if (["Present", "Late", "On Time"].includes(record.status)) stats.presentDays++;
                else if (record.status === "Half Day") stats.presentDays += 0.5;
                else if (["Week Off", "Sunday"].includes(record.status)) stats.weekOffs++;
                else if (record.status === "Holiday") stats.holidays++;
                else if (record.status === "Leave") stats.paidLeaves++;
                else if (record.status === "Absent") stats.unpaidLeaves++;

                if (record.punchIn?.status === "Late") stats.lateCount++;
                if (record.punchOut?.status === "Early") stats.earlyCount++;
                if (record.punchOut?.status === "Over Time" && record.punchIn?.time && record.punchOut?.time) {
                    const hrs = (new Date(record.punchOut.time) - new Date(record.punchIn.time)) / 36e5;
                    if(hrs > 9) stats.overtimeHours += (hrs - 9);
                }
            } else {
                if (dayConfig && dayConfig.isWeekoff) stats.weekOffs++;
            }
        }

        stats.payableDays = stats.presentDays + stats.weekOffs + stats.holidays + stats.paidLeaves;
        
        // 6. Calculate Earnings
        let earningsMap = { Basic: 0, HRA: 0, Special: 0, Travel: 0, Other: 0 };
        let grossEarned = 0;
        let baseSalary = 0;

        if (salaryDetails?.earnings) {
            const salaryFactor = salaryDetails.salaryType === "Per Month" 
                ? (stats.payableDays / stats.daysInMonth) 
                : stats.payableDays;

            salaryDetails.earnings.forEach(earn => {
                const amount = earn.calculation === "Flat Rate" ? (earn.amount || 0) : ((earn.amount || 0) * salaryFactor);
                grossEarned += amount;
                const head = (earn.head || "").toLowerCase();
                if (head.includes('basic')) { earningsMap.Basic += amount; baseSalary += amount; }
                else if (head.includes('hra')) earningsMap.HRA += amount;
                else if (head.includes('travel') || head.includes('conveyance')) earningsMap.Travel += amount;
                else if (head.includes('special')) earningsMap.Special += amount;
                else earningsMap.Other += amount;
            });
        }

        // 7. Penalties & Overtime
        let lateFine = 0, earlyFine = 0, overtimePay = 0;
        if (penaltyPolicy) {
            if (penaltyPolicy.lateComingPolicy && stats.lateCount > (penaltyPolicy.lateComingPolicy.allowedLateDays || 0)) {
                const excess = stats.lateCount - penaltyPolicy.lateComingPolicy.allowedLateDays;
                lateFine = excess * (penaltyPolicy.lateComingPolicy.amount || 0);
            }
            if (penaltyPolicy.earlyLeavingPolicy && stats.earlyCount > (penaltyPolicy.earlyLeavingPolicy.allowedEarlyLeavingDays || 0)) {
                const excess = stats.earlyCount - penaltyPolicy.earlyLeavingPolicy.allowedEarlyLeavingDays;
                earlyFine = excess * (penaltyPolicy.earlyLeavingPolicy.amount || 0);
            }
            if (penaltyPolicy.overtimePolicy && stats.overtimeHours > 0) {
                const hourlyRate = (earningsMap.Basic > 0) ? (earningsMap.Basic / 30 / 8) : 0; 
                overtimePay = stats.overtimeHours * hourlyRate;
            }
        }

        // 8. Variable Pay
        let incentives = 0, reimbursements = 0, bonus = 0;
        earningsTx.forEach(tx => {
            if(tx.type === 'Incentive') incentives += (tx.amount || 0);
            if(tx.type === 'Reimbursement') reimbursements += (tx.amount || 0);
            if(tx.type === 'Bonus') bonus += (tx.amount || 0);
        });

        // 9. Compliances
        let pfEmployee = 0, pfEmployer = 0, esiEmployee = 0, esiEmployer = 0, pt = 0;
        if (salaryDetails?.compliances) {
            const comp = salaryDetails.compliances;
            if (comp.pfEmployee?.enabled) {
                let pfWage = earningsMap.Basic;
                if (comp.pfEmployee.type === "Limit ₹1,800" && pfWage > 15000) pfWage = 15000;
                pfEmployee = pfWage * 0.12;
                pfEmployer = pfWage * 0.12;
            }
            if (comp.esiEmployee?.enabled && grossEarned <= 21000 && grossEarned > 0) {
                esiEmployee = Math.ceil(grossEarned * 0.0075);
                esiEmployer = Math.ceil(grossEarned * 0.0325);
            }
            if (comp.professionalTax?.enabled && grossEarned > 15000) pt = 200;
        }

        // 10. Loans
        let loanDeduction = 0, loanOutstanding = 0;
        advanceLedgers.forEach(adv => {
            loanDeduction += (adv.monthlyDeduction || 0);
            loanOutstanding += (adv.outstandingBalance || 0);
        });

        const totalEarnings = grossEarned + overtimePay + incentives + reimbursements + bonus;
        const totalDeductions = pfEmployee + esiEmployee + pt + loanDeduction + lateFine + earlyFine;
        const netSalary = totalEarnings - totalDeductions;
        const leaveString = leaveBalanceDoc?.leaveBalance 
            ? `PL:${leaveBalanceDoc.leaveBalance.priviledgeLeave?.current || 0}, SL:${leaveBalanceDoc.leaveBalance.sickLeave?.current || 0}`
            : "N/A";

        // --- RESOLVE BRANCH ---
        const branchId = employee.basic?.branches?.[0];
        const branchInfo = companyMap[String(branchId)] || {};
        const branchName = branchInfo.name ? `${branchInfo.name}` : "Main Branch";

        return {
            id: employee._id,
            employeeId: employee.employment?.[0]?.employeeId || "N/A", 
            name: employee.basic?.fullName || "Unknown",
            branch: branchName, 
            department: employee.basic?.departments?.[0] || "",
            designation: employee.basic?.jobTitle || "",
            doj: employee.employment?.[0]?.dateOfJoining ? new Date(employee.employment[0].dateOfJoining).toLocaleDateString() : "",
            
            // Personal
            pan: employee.personal?.panNumber || "",
            uan: employee.personal?.uanNumber || "",
            pfNumber: employee.personal?.pfNumber || "",
            esiNumber: employee.personal?.esiNumber || "", // Adjusted from employment to personal/employment
            bankAcc: employee.personal?.bankAccountNumber || "", // Or from bankDetails
            bankName: employee.personal?.bankName || "",
            bankIfsc: employee.personal?.ifscCode || "",
            
            // CTC Info
            ctcAmount: salaryDetails?.CTCAmount || 0,
            salaryType: salaryDetails?.salaryType || "",
            
            // Attendance
            daysInMonth: stats.daysInMonth,
            presentDays: stats.presentDays, weekOffs: stats.weekOffs, holidays: stats.holidays,
            paidLeaves: stats.paidLeaves, unpaidLeaves: stats.unpaidLeaves, totalPayableDays: stats.payableDays,
            
            // Earnings
            baseSalary: baseSalary, 
            hra: earningsMap.HRA, 
            travelAllowance: earningsMap.Travel,
            specialAllowance: earningsMap.Special, 
            otherEarnings: earningsMap.Other, 
            overtimePay: overtimePay, 
            incentives: incentives, 
            reimbursements: reimbursements,
            bonus: bonus,
            totalEarnings: totalEarnings,
            
            // Deductions
            epf: pfEmployee, 
            esi: esiEmployee, 
            professionalTax: pt, 
            loanDeducted: loanDeduction,
            lateFine: lateFine, 
            earlyFine: earlyFine, 
            totalDeductions: totalDeductions,
            
            // Net
            netSalary: netSalary,
            
            // Employer
            employerEpf: pfEmployer, 
            employerEsi: esiEmployer,
            
            // Meta
            leaveBalance: leaveString
        };

    } catch (err) {
        console.error("Payroll Calc Error:", err);
        return { id: employee._id, name: "Error", error: true };
    }
};

// =========================================================
// GENERATE REPORT CONTROLLER
// =========================================================
export const getReportData = async (req, res) => {
    try {
        let { companyId, month, year, reportType, branch, userId, format } = req.query;
        console.log(`>>> START REPORT GEN: Type: ${reportType}, Month: ${month}, Year: ${year}`);

        if (!companyId || !reportType) {
            return res.status(400).json({ message: "Missing Company ID or Report Type" });
        }

        // 1. VALIDATE USER ID (Prevents "Cast to ObjectId failed" error)
        const validUserId = (userId && mongoose.Types.ObjectId.isValid(userId)) ? userId : null;

        const company = await Company.findById(companyId).lean();
        if (!company) return res.status(404).json({ message: "Company not found" });

        // 2. FETCH EMPLOYEES
        const companyBranches = await Branch.find({ company: companyId }).select('_id').lean();
        const branchIds = companyBranches.map(b => b._id);
        console.log(`[DEBUG 1] Branches found for Company: ${branchIds.length}`);
        
        // 2. Build the query
        let employeeQuery;
        
        if (branch && branch !== 'All Branches') {
            // If a specific branch is selected in the UI, only get employees for that branch
            employeeQuery = { "basic.branches": { $in: [branch] } };
        } else {
            // Otherwise, get all employees belonging to ANY of the company's branches
            employeeQuery = { "basic.branches": { $in: branchIds } };
        }
        
        const employees = await Employee.find(employeeQuery).lean();
        const employeeIds = employees.map(e => e._id);
        console.log(`[DEBUG 2] Employees found for query: ${employees.length}`);

        if (employees.length === 0) {
            console.warn("!!! No employees found. Check if Branch IDs match Employee.basic.branches.");
        }
        
        let reportData = [];

        // Pre-fetch Company Map for Branch Names
        // const branchIds = [...new Set(employees.map(e => e.basic?.branches?.[0]).filter(Boolean))];
        const companies = await Company.find({ _id: { $in: branchIds } }).select("name company_code").lean();
        const companyMap = {};
        companies.forEach(c => companyMap[String(c._id)] = { name: c.name, code: c.company_code });

        // Helpers for formatting
        const formatTime = (date) => date ? new Date(date).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : "-";
        // const formatDate = (date) => date ? new Date(date).toLocaleDateString('en-GB') : "-";

        // =========================================================
        // SWITCH CASE: MATCHING FLUTTER UI CATEGORIES
        // =========================================================
        switch (reportType) {

            // ----------------------------------------------------
            // 📊 ATTENDANCE CATEGORY
            // ----------------------------------------------------
            case 'Daily Attendance Report':
            case 'Detailed Attendance Report':
            case 'Attendance Summary Report':
            case 'Late Arrival Report':
                const attendanceDocs = await Attendance.find({ employeeId: { $in: employeeIds } }).lean();
                console.log(`[DEBUG 3] Attendance Docs fetched from DB: ${attendanceDocs.length}`);
    
                for (const emp of employees) {
                    console.log(`[DEBUG] Fetching attendance for: ${emp.basic?.fullName}`);
                
                    // Now await is allowed because getReportData is an async function
                    const attDoc = await Attendance.findOne({ 
                        employeeId: emp._id,
                        "monthlyAttendance.month": Number(month),
                        "monthlyAttendance.year": Number(year)
                    }).lean();
                
                    // Find the specific monthly record from the array based on your schema
                    const mRec = attDoc?.monthlyAttendance?.find(m => 
                        Number(m.month) === Number(month) && 
                        Number(m.year) === Number(year)
                    );
                
                    if (attDoc && !mRec) {
                        console.log(`[DEBUG] Found doc for ${emp.basic?.fullName}, but NO match for Month ${month}.`);
                    }
                
                    const records = mRec?.records || [];
        const daysInMonth = new Date(year, month, 0).getDate();
        
        for (let d = 1; d <= daysInMonth; d++) {
            const dayRecord = records.find(r => {
                if (!r.date) return false;
                const rDate = new Date(r.date);
                
                // FIX: Match Year, Month, and Day specifically to avoid timezone shifts
                return rDate.getUTCFullYear() === Number(year) &&
                       (rDate.getUTCMonth() + 1) === Number(month) &&
                       rDate.getUTCDate() === d;
            });

            // DEBUG: Log if we actually find a record for today (Feb 4)
            if (dayRecord && d === 4 && month == 2) {
                console.log(`[MATCH FOUND] Found record for ${emp.basic.fullName} on Feb 4! Status: ${dayRecord.status}`);
            }

            reportData.push({
                "Date": `${d.toString().padStart(2, '0')}-${month.toString().padStart(2, '0')}-${year}`,
                "Employee ID": emp.employment?.[0]?.employeeId || "-",
                "Name": emp.basic?.fullName || "-",
                "Branch": companyMap[String(emp.basic?.branches?.[0])]?.name || company.name,
                "Status": dayRecord?.status || "Absent",
                "In Time": dayRecord?.punchIn?.time ? new Date(dayRecord.punchIn.time).toLocaleTimeString('en-IN', { hour: '2-digit', minute: '2-digit' }) : "-",
                "Out Time": dayRecord?.punchOut?.time ? new Date(dayRecord.punchOut.time).toLocaleTimeString('en-IN', { hour: '2-digit', minute: '2-digit' }) : "-",
                "Late By": dayRecord?.punchIn?.lateBy || "0 mins",
                "Remarks": dayRecord?.remarks || ""
            });
        }
    }
    break;

            // ----------------------------------------------------
            // 💰 PAYROLL CATEGORY
            // ----------------------------------------------------
            case 'Pay Slips':
            case 'Salary Sheet':
            case 'CTC Breakdown Report':
            case 'Reimbursement Report':
                // Note: calculatePayrollForEmployee should be imported from your helpers
                const payrollResults = await Promise.all(employees.map(async (emp) => {
                    try {
                        // Assuming calculatePayrollForEmployee exists in your service layer
                        // return await calculatePayrollForEmployee(emp, Number(month), Number(year), companyMap);
                        return { name: emp.basic.fullName, netSalary: "See History" }; 
                    } catch (e) {
                        return { name: emp.basic.fullName, netSalary: "Error" };
                    }
                }));

                reportData = payrollResults.map(p => ({
                    "Name": p.name,
                    "Month": `${month}-${year}`,
                    "Net Salary": p.netSalary
                }));
                break;

            // ----------------------------------------------------
            // 👤 EMPLOYEE CATEGORY
            // ----------------------------------------------------
            case 'Employee List Report':
                reportData = employees.map(emp => ({
                    "Employee ID": emp.employment?.[0]?.employeeId || "-", 
                    "Name": emp.basic?.fullName || "-",
                    "Job Title": emp.basic?.jobTitle || "-", 
                    "Official Email": emp.basic?.officialEmail || "-",
                    "Joining Date": formatDate(emp.basic?.dateOfJoining),
                    "Branch": companyMap[String(emp.basic?.branches?.[0])]?.name || company.name
                }));
                break;

            case 'Leave Report':
                const leaveDocs = await LeaveAndBalance.find({ employeeId: { $in: employeeIds } }).lean();
                reportData = employees.map(emp => {
                    const lb = leaveDocs.find(l => String(l.employeeId) === String(emp._id))?.leaveBalance || {};
                    return {
                        "Employee ID": emp.employment?.[0]?.employeeId || "-",
                        "Name": emp.basic?.fullName || "-",
                        "Casual Leave": lb.casualLeave?.current || 0,
                        "Sick Leave": lb.sickLeave?.current || 0,
                        "Privilege Leave": lb.priviledgeLeave?.current || 0
                    };
                });
                break;

            default:
                console.log("Unhandled reportType:", reportType);
                reportData = []; 
        }
        console.log(`[DEBUG FINAL] Total report rows generated: ${reportData.length}`);

        // =========================================================
        // 3. SAVE TO HISTORY (Triggers visible list in History Tab)
        // =========================================================
        // if (reportData.length > 0) {
        //     await ReportHistory.create({
        //         companyId,
        //         generatedBy: validUserId, 
        //         reportType,
        //         branch: branch || "All Branches", 
        //         duration: `${month}-${year}`,
        //         format: format || "XLSX", 
        //         status: "Ready"
        //     });
        // }


    

// 2. Add a fallback to ensure history is created for testing
if (reportData.length === 0 && employees.length > 0) {
    // Add at least one entry so the user knows the report was run but was empty
    reportData.push({ "Status": "No data found for selected period" });
}

// 3. Move History Creation ABOVE the check if you want to record "Empty" reports
await ReportHistory.create({
    companyId,
    generatedBy: validUserId,
    reportType,
    branch: branch || "All Branches",
    duration: `${month}-${year}`,
    status: reportData.length > 0 ? "Ready" : "No Data"
});

        res.json({ message: "Success", data: reportData });

    } catch (error) {
        console.error("Report Generation Error:", error);
        res.status(500).json({ message: "Server error", error: error.message });
    }
};

// ... keep getReportHistory ...
export const getReportHistory = async (req, res) => {
    try {
        const { companyId } = req.query;
        if(!companyId) return res.status(400).json({ message: "Company ID required" });

        const history = await ReportHistory.find({ companyId })
            .sort({ createdAt: -1 })
            .limit(20);
            
        res.json(history);
    } catch (error) {
        res.status(500).json({ message: "Server error", error: error.message });
    }
};