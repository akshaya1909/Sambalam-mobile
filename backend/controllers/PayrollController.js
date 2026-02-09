import mongoose from "mongoose";
import Employee from "../models/employeeModel.js";
import { SalaryDetails } from "../models/salaryDetailsModel.js";
import Attendance from "../models/attendanceModel.js";
import AdvanceLedger from "../models/advanceLedgerModel.js";
import EarningTransaction from "../models/earningTransactionModel.js";
import { PenaltyAndOvertime } from "../models/penaltyAndOvertimeModel.js";
import { LeaveAndBalance } from "../models/leaveBalanceModel.js";
import Company from "../models/companyModel.js";
import PayrollResult from "../models/payrollResultModel.js";
// Optional: Import TDS model if needed later
// import TdsDeclaration from "../models/tdsDeclarationModel.js";

// === UTILS ===
const safeNum = (val) => {
    const num = Number(val);
    return isNaN(num) ? 0 : num;
};

// =========================================================
// === HELPER: PAYROLL CALCULATOR (CORE LOGIC)
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

        // -------------------------------------------------------------
        // ✅ MANAGEMENT CHECK (Partners/MDs get full salary)
        // -------------------------------------------------------------
        const depts = employee.basic?.departments || [];
        const singleDept = employee.basic?.department || ""; // Some schemas use singular
        const isManagement = depts.some(d => d.toLowerCase().includes('management')) 
                             || singleDept.toLowerCase().includes('management');

        if (isManagement) {
            // Force Full Attendance
            stats.presentDays = totalDaysInMonth; 
            stats.payableDays = totalDaysInMonth;
            stats.weekOffs = 0; 
            stats.holidays = 0;
            stats.lateCount = 0;
            stats.earlyCount = 0;
        } else {
            // === STANDARD ATTENDANCE CALCULATION ===
            const attendanceMap = {};
            if (attendanceDoc) {
                let records = [];
                // Handle both structures (monthly array vs flat)
                if (attendanceDoc.monthlyAttendance && Array.isArray(attendanceDoc.monthlyAttendance)) {
                    const mRecord = attendanceDoc.monthlyAttendance.find(m => m.month === Number(month) && m.year === Number(year));
                    if (mRecord) records = mRecord.records;
                } else if (attendanceDoc.month === Number(month) && attendanceDoc.year === Number(year)) {
                    records = attendanceDoc.records;
                }
                if (records) records.forEach(r => { attendanceMap[new Date(r.date).toDateString()] = r; });
            }

            const dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
            // Helper to get work timings
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
                
                // Skip days before joining
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
                    
                    // OT Calc
                    if (record.punchOut?.status === "Over Time" && record.punchIn?.time && record.punchOut?.time) {
                        const hrs = (new Date(record.punchOut.time) - new Date(record.punchIn.time)) / 36e5;
                        // Assuming 9 hours standard shift
                        if(hrs > 9) stats.overtimeHours += (hrs - 9);
                    }
                } else {
                    // No record? Check if it was a week off
                    if (dayConfig && dayConfig.isWeekoff) stats.weekOffs++;
                }
            }
            stats.payableDays = stats.presentDays + stats.weekOffs + stats.holidays + stats.paidLeaves;
        }
        
        stats.totalPayableHours = stats.payableDays * 9;

        // 6. Calculate Earnings
        let earningsMap = { Basic: 0, HRA: 0, Special: 0, Travel: 0, Other: 0 };
        let grossEarned = 0;
        let baseSalary = 0;

        if (salaryDetails?.earnings) {
            // Factor is 1 if management or full attendance, else prorated
            const salaryFactor = (salaryDetails.salaryType === "Per Month") 
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
        if (penaltyPolicy && !isManagement) { // ✅ Skip for Management
            if (penaltyPolicy.lateComingPolicy && stats.lateCount > (penaltyPolicy.lateComingPolicy.allowedLateDays || 0)) {
                const excess = stats.lateCount - penaltyPolicy.lateComingPolicy.allowedLateDays;
                lateFine = excess * (penaltyPolicy.lateComingPolicy.amount || 0);
            }
            if (penaltyPolicy.earlyLeavingPolicy && stats.earlyCount > (penaltyPolicy.earlyLeavingPolicy.allowedEarlyLeavingDays || 0)) {
                const excess = stats.earlyCount - penaltyPolicy.earlyLeavingPolicy.allowedEarlyLeavingDays;
                earlyFine = excess * (penaltyPolicy.earlyLeavingPolicy.amount || 0);
            }
            if (penaltyPolicy.overtimePolicy && stats.overtimeHours > 0) {
                // Calculate Hourly Rate based on Basic (30 days / 8 hours)
                const hourlyRate = (earningsMap.Basic > 0) ? (earningsMap.Basic / 30 / 8) : 0; 
                overtimePay = stats.overtimeHours * hourlyRate;
            }
        }

        // 8. Variable Pay (Incentives/Reimbursements from Transactions)
        let incentives = 0, reimbursements = 0, bonus = 0;
        earningsTx.forEach(tx => {
            if(tx.type === 'Incentive') incentives += (tx.amount || 0);
            if(tx.type === 'Reimbursement') reimbursements += (tx.amount || 0);
            if(tx.type === 'Bonus') bonus += (tx.amount || 0);
        });

        // 9. Compliances (PF/ESI/PT) - ✅ CORRECTED LOGIC
        let pfEmployee = 0, pfEmployer = 0, esiEmployee = 0, esiEmployer = 0, pt = 0;
        let employerLwf = 0;

        if (salaryDetails?.compliances) {
            const comp = salaryDetails.compliances;

            // A. PF
            if (comp.pfEmployee?.enabled && comp.pfEmployee?.type !== 'None') {
                let pfWage = earningsMap.Basic || 0;
                if (comp.pfEmployee.type === "Limit ₹1,800" && pfWage > 15000) {
                    pfWage = 15000;
                }
                pfEmployee = Math.round(pfWage * 0.12);
                
                if (comp.pfEmployer?.enabled && comp.pfEmployer?.type !== 'None') {
                    pfEmployer = Math.round(pfWage * 0.12);
                }
            }

            // B. ESI
            if (comp.esiEmployee?.enabled && comp.esiEmployee?.type !== 'None') {
                if (grossEarned <= 21000 && grossEarned > 0) {
                    esiEmployee = Math.ceil(grossEarned * 0.0075);
                    if (comp.esiEmployer?.enabled && comp.esiEmployer?.type !== 'None') {
                        esiEmployer = Math.ceil(grossEarned * 0.0325);
                    }
                }
            }

            // C. PT
            if (comp.professionalTax?.enabled && comp.professionalTax?.type !== 'None') {
                if (grossEarned > 15000) pt = 200; // Standard 200 (Adjust logic if state-specific)
            }
        }

        // 10. Loans/Advances
        let loanDeduction = 0, loanOutstanding = 0;
        advanceLedgers.forEach(adv => {
            loanDeduction += (adv.monthlyDeduction || 0);
            loanOutstanding += (adv.outstandingBalance || 0);
        });

        // 11. Final Aggregation
        const totalEarnings = grossEarned + overtimePay + incentives + reimbursements + bonus;
        const totalDeductions = pfEmployee + esiEmployee + pt + loanDeduction + lateFine + earlyFine;
        const netSalary = totalEarnings - totalDeductions;
        const leaveString = leaveBalanceDoc?.leaveBalance 
            ? `PL:${leaveBalanceDoc.leaveBalance.priviledgeLeave?.current || 0}, SL:${leaveBalanceDoc.leaveBalance.sickLeave?.current || 0}`
            : "N/A";

        // Resolve Branch Name
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
            pan: employee.personal?.panNumber || "",
            uan: employee.personal?.uanNumber || "",
            pfNumber: employee.personal?.pfNumber || "",
            bankAcc: employee.personal?.bankAccountNumber || "",
            bankName: employee.personal?.bankName || "",
            bankIfsc: employee.personal?.ifscCode || "",
            
            salaryAmount: salaryDetails?.CTCAmount || 0,
            salaryType: salaryDetails?.salaryType || "",
            daysInMonth: stats.daysInMonth,
            payPerDay: ((salaryDetails?.CTCAmount || 0) / stats.daysInMonth) || 0,
            
            presentDays: stats.presentDays, weekOffs: stats.weekOffs, holidays: stats.holidays,
            paidLeaves: stats.paidLeaves, unpaidLeaves: stats.unpaidLeaves, totalPayableDays: stats.payableDays,
            
            baseSalary: baseSalary, overTimeHours: stats.overtimeHours, overTimeDays: stats.overtimeHours / 9,
            overtimePay: overtimePay, otherEarnings: earningsMap.Other, bonus: bonus,
            workBasisEarnings: grossEarned, incentives: incentives, reimbursements: reimbursements,
            specialAllowance: earningsMap.Special, hra: earningsMap.HRA, travelAllowance: earningsMap.Travel,
            totalEarnings: totalEarnings,
            
            epf: pfEmployee, esi: esiEmployee, professionalTax: pt, loanDeducted: loanDeduction,
            earlyLeavingFine: earlyFine, lateComingFine: lateFine, totalDeductions: totalDeductions,
            
            monthNetSalary: netSalary,
            salaryPaid: 0, 
            salaryPending: netSalary, 
            
            employerEpf: pfEmployer, employerEsi: esiEmployer, employerLwf: employerLwf,
            loanOutstanding: loanOutstanding, leaveBalance: leaveString
        };

    } catch (err) {
        console.error("Payroll Calc Error:", err);
        return { id: employee._id, name: "Error", error: true };
    }
};

// =========================================================
// === 1. GET EMPLOYEES BY COMPANY (READ LIVE PREVIEW)
// =========================================================
export const getEmployeesByCompany = async (req, res) => {
    try {
        const { companyId, month, year } = req.query;
        if (!companyId) return res.status(400).json({ message: "companyId required" });

        const employees = await Employee.find({ "basic.branches": { $in: [companyId] } }).lean();
        if (!employees.length) return res.json({ message: "No employees found", employees: [] });

        const numMonth = Number(month);
        const numYear = Number(year);

        // 1. Get Company Map
        const branchIds = [...new Set(employees.map(e => e.basic?.branches?.[0]).filter(Boolean))];
        const companies = await Company.find({ _id: { $in: branchIds } }).select("name company_code").lean();
        const companyMap = {};
        companies.forEach(c => companyMap[String(c._id)] = { name: c.name, code: c.company_code });

        // 2. Fetch Existing Payroll Records
        const employeeIds = employees.map(e => e._id);
        const savedPayrolls = await PayrollResult.find({
            employeeId: { $in: employeeIds },
            month: numMonth,
            year: numYear
        }).lean();

        const payrollMap = {};
        savedPayrolls.forEach(p => { payrollMap[String(p.employeeId)] = p; });

        // 3. Calculate Live Data
        const payrollData = await Promise.all(employees.map(async (emp) => {
            const calculated = await calculatePayrollForEmployee(emp, numMonth, numYear, companyMap);
            
            const saved = payrollMap[String(emp._id)];
            if (saved) {
                // ✅ Overwrite with persisted Payment Status
                calculated.salaryPaid = safeNum(saved.paidAmount);
                calculated.salaryPending = safeNum(saved.pendingAmount);
                calculated.payrollFinalized = true; 
                // Optional: Use saved calculations if you want to freeze numbers
                // calculated.monthNetSalary = safeNum(saved.netPay);
            } else {
                calculated.payrollFinalized = false;
            }
            return calculated;
        }));

        res.json({ message: "Success", employees: payrollData });
    } catch (error) {
        console.error("Error:", error);
        res.status(500).json({ message: "Server error", error: error.message });
    }
};

// =========================================================
// === 2. RUN PAYROLL (FINALIZE & SAVE)
// =========================================================
export const runPayroll = async (req, res) => {
    try {
        const { companyId, month, year } = req.body;

        if (!companyId || !month || !year) {
            return res.status(400).json({ message: "companyId, month, year required" });
        }

        const employees = await Employee.find({ "basic.branches": { $in: [companyId] } }).lean();
        if (employees.length === 0) {
             return res.json({ message: `No employees found.`, count: 0, payroll: [] });
        }
        
        // Fetch Company Map
        const branchIds = [...new Set(employees.map(e => e.basic?.branches?.[0]).filter(Boolean))];
        const companies = await Company.find({ _id: { $in: branchIds } }).select("name company_code").lean();
        const companyMap = {};
        companies.forEach(comp => { companyMap[String(comp._id)] = { name: comp.name, code: comp.company_code }; });

        const results = [];

        for (const emp of employees) {
            // 1. Calculate Live
            const calc = await calculatePayrollForEmployee(emp, Number(month), Number(year), companyMap);

            if (calc.error) {
                console.warn(`Skipping payroll save for ${emp._id} due to calc error.`);
                continue;
            }

            const payPeriodStart = new Date(year, month - 1, 1);
            const payPeriodEnd = new Date(year, month, 0);

            // 2. Check Existing (Preserve Payment)
            const existingRecord = await PayrollResult.findOne({ 
                employeeId: emp._id, 
                month: Number(month), 
                year: Number(year) 
            }).lean();

            const currentPaid = existingRecord ? (existingRecord.paidAmount || 0) : 0;
            const newNetPay = safeNum(calc.monthNetSalary);
            
            // Recalculate Pending
            let newPending = newNetPay - currentPaid;
            if (newPending < 0) newPending = 0; 

            // Status
            let status = 'Pending';
            if (newPending <= 0 && newNetPay > 0) status = 'Paid';
            else if (currentPaid > 0) status = 'Partial';
            else status = 'Pending';

            const payrollData = {
                employeeId: emp._id,
                month: Number(month),
                year: Number(year),
                payPeriodStart,
                payPeriodEnd,
                payrollDate: new Date(),

                attendance: {
                    daysInMonth: safeNum(calc.daysInMonth),
                    payableDays: safeNum(calc.totalPayableDays),
                    presentDays: safeNum(calc.presentDays),
                    weekOffs: safeNum(calc.weekOffs),
                    holidays: safeNum(calc.holidays),
                    paidLeaves: safeNum(calc.paidLeaves),
                    unpaidLeaves: safeNum(calc.unpaidLeaves),
                    overtimeHours: safeNum(calc.overTimeHours)
                },

                earnings: {
                    baseSalary: safeNum(calc.baseSalary),
                    hra: safeNum(calc.hra),
                    specialAllowance: safeNum(calc.specialAllowance),
                    travelAllowance: safeNum(calc.travelAllowance),
                    otherEarnings: safeNum(calc.otherEarnings),
                    overtimePay: safeNum(calc.overtimePay),
                    incentives: safeNum(calc.incentives),
                    reimbursements: safeNum(calc.reimbursements),
                    bonus: safeNum(calc.bonus),
                    grossEarned: safeNum(calc.workBasisEarnings),
                    totalEarnings: safeNum(calc.totalEarnings)
                },

                deductions: {
                    epf: safeNum(calc.epf),
                    esi: safeNum(calc.esi),
                    professionalTax: safeNum(calc.professionalTax),
                    loanDeducted: safeNum(calc.loanDeducted),
                    lateFine: safeNum(calc.lateComingFine),
                    earlyFine: safeNum(calc.earlyLeavingFine),
                    // TDS field will be 0 initially, updated by TDS Module
                    tds: existingRecord?.deductions?.tds || 0, 
                    totalDeductions: safeNum(calc.totalDeductions)
                },

                employer: {
                    epf: safeNum(calc.employerEpf),
                    esi: safeNum(calc.employerEsi),
                    lwf: safeNum(calc.employerLwf)
                },

                netPay: newNetPay,
                
                // ✅ Preserved Fields
                paymentStatus: status,
                paidAmount: currentPaid,
                pendingAmount: newPending,
                
                slipShared: existingRecord?.slipShared || false,
                bankVerified: !!emp.personal?.bankAccountNumber
            };

            const savedRecord = await PayrollResult.findOneAndUpdate(
                { employeeId: emp._id, month: Number(month), year: Number(year) },
                payrollData,
                { new: true, upsert: true, setDefaultsOnInsert: true }
            );

            results.push(savedRecord);
        }

        res.json({
            message: `Payroll finalized successfully for ${results.length} employees.`,
            count: results.length,
            payroll: results,
        });

    } catch (error) {
        console.error("Payroll run error:", error);
        res.status(500).json({ message: "Server error", error: error.message });
    }
};

// =========================================================
// === 3. SAVE PAYMENT (PARTIAL OR FULL)
// =========================================================
export const savePayment = async (req, res) => {
    try {
        const { companyId, payments, records } = req.body || {};
        let transactions = payments || records;

        // Unwrap logic
        if (transactions && !Array.isArray(transactions) && typeof transactions === 'object') {
            if (Array.isArray(transactions.records)) transactions = transactions.records;
            else if (Array.isArray(transactions.payments)) transactions = transactions.payments;
        }

        if (!transactions || !Array.isArray(transactions) || transactions.length === 0) {
            return res.status(400).json({ message: "Invalid payload: Payment data must be array." });
        }

        const updatedPayments = [];

        for (const p of transactions) {
            if (!p) continue;
            const employeeId = p.employeeId;
            const paymentAmount = Number(p.paymentAmount); 
            const month = Number(p.month || p.payMonth);
            const year = Number(p.year || p.payYear);
            
            if (!employeeId || isNaN(paymentAmount) || paymentAmount <= 0) continue;

            // 1. Try Find Existing
            let result = await PayrollResult.findOne({ employeeId, month, year });

            let newPaidAmount = 0;
            let newPendingAmount = 0;
            let totalNet = 0;

            if (result) {
                // Update Existing
                const currentPaid = Number(result.paidAmount || 0);
                totalNet = Number(result.netPay || 0);
                newPaidAmount = Number((currentPaid + paymentAmount).toFixed(2));
                newPendingAmount = Number((totalNet - newPaidAmount).toFixed(2));
                if (newPendingAmount < 0) newPendingAmount = 0;
            } else {
                // Create NEW (Auto-Finalize on Pay)
                const employee = await Employee.findById(employeeId).lean();
                if (!employee) continue;

                const calc = await calculatePayrollForEmployee(employee, month, year, {});
                if (calc.error) continue;

                totalNet = safeNum(calc.monthNetSalary);
                newPaidAmount = Number(paymentAmount.toFixed(2));
                newPendingAmount = Number((totalNet - newPaidAmount).toFixed(2));
                if (newPendingAmount < 0) newPendingAmount = 0;

                const payPeriodStart = new Date(year, month - 1, 1);
                const payPeriodEnd = new Date(year, month, 0);

                result = new PayrollResult({
                    employeeId, month, year, payPeriodStart, payPeriodEnd,
                    attendance: { daysInMonth: calc.daysInMonth, payableDays: calc.totalPayableDays, presentDays: calc.presentDays, weekOffs: calc.weekOffs, holidays: calc.holidays, paidLeaves: calc.paidLeaves, unpaidLeaves: calc.unpaidLeaves, overtimeHours: calc.overTimeHours },
                    earnings: { baseSalary: calc.baseSalary, hra: calc.hra, specialAllowance: calc.specialAllowance, travelAllowance: calc.travelAllowance, otherEarnings: calc.otherEarnings, overtimePay: calc.overtimePay, incentives: calc.incentives, reimbursements: calc.reimbursements, bonus: calc.bonus, grossEarned: calc.workBasisEarnings, totalEarnings: calc.totalEarnings },
                    deductions: { epf: calc.epf, esi: calc.esi, professionalTax: calc.professionalTax, loanDeducted: calc.loanDeducted, lateFine: calc.lateComingFine, earlyFine: calc.earlyLeavingFine, tds: calc.tds, totalDeductions: calc.totalDeductions },
                    employer: { epf: calc.employerEpf, esi: calc.employerEsi, lwf: calc.employerLwf },
                    netPay: totalNet
                });
            }

            const newPaymentStatus = newPendingAmount <= 0 ? 'Paid' : 'Partial';

            // Save
            result.paidAmount = newPaidAmount;
            result.pendingAmount = newPendingAmount;
            result.paymentStatus = newPaymentStatus;
            result.payrollDate = new Date();
            await result.save();

            updatedPayments.push({ employeeId: result.employeeId, status: result.paymentStatus, paid: result.paidAmount });
        }

        res.json({ message: "Success", count: updatedPayments.length, payments: updatedPayments });

    } catch (error) {
        console.error("Save Error:", error);
        res.status(500).json({ message: "Server error", error: error.message });
    }
};


// =========================================================
// === GET ADVANCE LEDGER LIST (Corresponds to useGetAdvanceLedgerQuery)
// =========================================================
export const getAdvanceLedger = async (req, res) => {
    try {
        const { companyId } = req.query;

        if (!companyId) {
            return res.status(400).json({ message: "companyId is required" });
        }

        // 1. Get Employee IDs affiliated with the company
        const employees = await Employee.find({ "basic.branches": { $in: [companyId] } });
        const employeeIds = employees.map((e) => e._id);

        // 2. Fetch all ACTIVE advances/loans for these employees
        const advances = await AdvanceLedger.find({ 
            employeeId: { $in: employeeIds },
            status: 'Active' 
        }).lean();

        res.json({
            message: "Advance ledger fetched successfully",
            count: advances.length,
            advances: advances,
        });

    } catch (error) {
        console.error("Advance ledger list error:", error);
        res.status(500).json({ message: "Server error", error: error.message });
    }
};

// =========================================================
// === SAVE ADVANCE (Corresponds to useSaveAdvanceMutation)
// =========================================================
export const saveAdvance = async (req, res) => {
    // Expected Payload: { records: [{ employeeId, advanceAmount, monthlyDeduction, issueDate, description, month, year }], companyId }
    try {
        const { records, companyId } = req.body; 
        
        if (!records || records.length === 0 || !companyId) {
            return res.status(400).json({ message: "Advance records and companyId are required." });
        }

        const newAdvanceRecords = [];

        for (const record of records) {
            const { employeeId, advanceAmount, monthlyDeduction, issueDate, description, month, year } = record;

            // Validation: advanceAmount and monthlyDeduction are required and positive
            if (!employeeId || advanceAmount <= 0 || monthlyDeduction <= 0) continue;

            // 1. Create a new Advance Ledger entry
            const newLedgerEntry = await AdvanceLedger.create({
                employeeId: employeeId,
                advanceAmount: advanceAmount,
                // In your React UI, monthlyDeduction is set to advanceAmount for simplicity,
                // meaning the full loan is expected to be deducted in the next payroll run.
                monthlyDeduction: monthlyDeduction,
                outstandingBalance: advanceAmount, 
                issueDate: issueDate || new Date(),
                status: 'Active',
            });
            
            newAdvanceRecords.push({ ...newLedgerEntry.toObject(), month, year });
        }

        // Return records with month/year context for RTKQ invalidation
        res.json({
            message: `Processed ${newAdvanceRecords.length} new advance grants.`,
            count: newAdvanceRecords.length,
            records: newAdvanceRecords 
        });

    } catch (error) {
        console.error("Save Advance error:", error);
        res.status(500).json({ message: "Server error saving advance", error: error.message });
    }
};

// --------------------------------------
// GET PAYROLL LIST FOR COMPANY
// --------------------------------------
export const getCompanyPayrolls = async (req, res) => {
    try {
        const { companyId } = req.query;

        if (!companyId) {
            return res.status(400).json({ message: "companyId is required" });
        }

        const employees = await Employee.find({ "basic.branches": { $in: [companyId] } });
        const employeeIds = employees.map((e) => e._id);

        // Fetch finalized payroll results
        const payrolls = await PayrollResult.find({ employeeId: { $in: employeeIds } });

        res.json({
            count: payrolls.length,
            payrolls,
        });

    } catch (error) {
        console.error("Payroll list error:", error);
        res.status(500).json({ message: "Server error", error: error.message });
    }
};



// --------------------------------------
// SAVE INCENTIVES
// --------------------------------------
export const saveIncentives = async (req, res) => {
    try {
        const { records, companyId } = req.body;

        // 1. Validate Input
        if (!companyId) {
            return res.status(400).json({ message: "Company ID is required." });
        }
        
        // Ensure records is an array (handles single object or array)
        const recordsArray = Array.isArray(records) ? records : [records];

        if (recordsArray.length === 0) {
            return res.status(400).json({ message: "Incentive records are required." });
        }

        const processedRecords = [];

        // 2. Loop through records (Same pattern as your working Reimbursement function)
        for (const record of recordsArray) {
            const {
                employeeId,
                amount,
                month,
                year,
                description,
                transactionDate,
            } = record;

            // Basic Validation
            if (!employeeId || !amount || Number(amount) <= 0) {
                console.warn("Skipping invalid incentive record:", record);
                continue;
            }

            const finalDate = transactionDate ? new Date(transactionDate) : new Date();

            // A. Create Transaction Log
            const newTransaction = await EarningTransaction.create({
                employeeId,
                companyId, // Add companyId to transaction for easier filtering later
                type: "Incentive",
                amount: Number(amount),
                description: description || "One-time Incentive",
                payMonth: Number(month),
                payYear: Number(year),
                processed: false,
                transactionDate: finalDate,
            });

            processedRecords.push(newTransaction);

        
        }

        // 3. Success Response
        return res.json({
            message: `Successfully processed ${processedRecords.length} incentive records.`,
            count: processedRecords.length,
            records: processedRecords
        });

    } catch (error) {
        console.error("Save Incentives Error:", error);
        return res.status(500).json({ 
            message: "Server error saving incentives", 
            error: error.message 
        });
    }
};

// --------------------------------------
// SAVE REIMBURSEMENTS (EARNING TRANSACTION)
// --------------------------------------
export const saveReimbursements = async (req, res) => {
    try {
        const { records, companyId } = req.body; 
         
        console.log("Incoming Payload:", JSON.stringify(req.body, null, 2));

        // 1. Validation: Ensure Company ID exists
        if (!companyId) {
            return res.status(400).json({ message: "companyId is required." });
        }

        // 2. Validation: Ensure Records exists
        if (!records) {
            return res.status(400).json({ message: "No reimbursement records provided." });
        }

        // 3. FIX: Force 'records' to be an array to prevent "not iterable" error
        // If frontend sends a single object { ... }, this wraps it in [ { ... } ]
        const recordsArray = Array.isArray(records) ? records : [records];

        if (recordsArray.length === 0) {
            return res.status(400).json({ message: "Records array is empty." });
        }

        const newReimbursementRecords = [];

        // 4. Iterate over the safe array
        for (const record of recordsArray) {
            const { employeeId, amount, payMonth, payYear, description, transactionDate } = record;

            // Validate individual fields
            if (!employeeId || amount <= 0 || !payMonth || !payYear) {
                console.warn("Skipping invalid record:", record);
                continue;
            }

            const finalTransactionDate = transactionDate
                ? new Date(transactionDate)
                : new Date();

            if (isNaN(finalTransactionDate.getTime())) {
                console.warn("Skipping: Invalid transactionDate", record);
                continue;
            }

            const newTransaction = await EarningTransaction.create({
                employeeId: employeeId,
                companyId: companyId,
                type: 'Reimbursement',
                amount: amount,
                description: description || 'Expense Reimbursement Claim',
                payMonth: payMonth,
                payYear: payYear,
                processed: false,
                transactionDate: finalTransactionDate,
            });
            
            newReimbursementRecords.push(newTransaction.toObject());
        }
        
        return res.json({
            message: `Processed ${newReimbursementRecords.length} reimbursement records.`,
            count: newReimbursementRecords.length,
            records: newReimbursementRecords
        });

    } catch (error) {
        console.error("Save Reimbursements error:", error);
        res.status(500).json({ message: "Server error saving reimbursements", error: error.message });
    }
};

/**
 * ======================================================
 * 1. SAVE TDS DECLARATION
 * ======================================================
 */
export const saveTdsDeclaration = async (req, res) => {
  try {
    const { employeeId, financialYear, declarations } = req.body;

    if (!employeeId || !financialYear) {
      return res.status(400).json({ error: "Missing required fields" });
    }

    let record = await TdsDeclaration.findOne({ employeeId, financialYear });

    if (record) {
      // Update
      record.declarations = declarations;
      await record.save();
    } else {
      // Create
      record = await TdsDeclaration.create({
        employeeId,
        financialYear,
        declarations,
      });
    }

    return res.status(200).json({
      message: "TDS Declaration saved successfully",
      data: record,
    });
  } catch (error) {
    console.error("saveTdsDeclaration error:", error);
    res.status(500).json({ error: "Server Error" });
  }
};

/**
 * ======================================================
 * 2. CALCULATE MONTHLY TDS
 * ======================================================
 * Formula (simple):
 * Annual Taxable Income = Annual Gross - Exemptions - Declarations
 * Tax = Slab-wise tax calculation
 * Monthly TDS = Tax / Remaining Months
 */
export const calculateMonthlyTds = async (req, res) => {
  try {
    const { employeeId, month, year } = req.body;

    if (!employeeId || !month || !year) {
      return res.status(400).json({ error: "Required fields missing" });
    }

    const salary = await SalaryDetails.findOne({ employeeId });
    if (!salary) return res.status(404).json({ error: "Salary details not found" });

    const tdsDecl = await TdsDeclaration.findOne({
      employeeId,
      financialYear: year,
    });

    const annualGross = salary.annualCTC || 0;
    const declarations = tdsDecl?.declarations?.total || 0;

    const taxableIncome = Math.max(annualGross - declarations, 0);

    // Simple TAX slab (replace with new regime if needed)
    let tax = 0;
    if (taxableIncome > 500000) tax = (taxableIncome - 500000) * 0.20;
    if (taxableIncome > 1000000) tax += (taxableIncome - 1000000) * 0.30;

    const remainingMonths = 12 - month + 1;
    const monthlyTds = Math.round(tax / remainingMonths);

    return res.status(200).json({
      employeeId,
      annualGross,
      declarations,
      taxableIncome,
      monthlyTds,
      remainingMonths,
    });
  } catch (error) {
    console.error("calculateMonthlyTds error:", error);
    res.status(500).json({ error: "Server Error" });
  }
};

/**
 * ======================================================
 * 3. SAVE MONTHLY TDS INTO PAYROLL RESULT MODEL
 * ======================================================
 */
export const saveMonthlyTds = async (req, res) => {
  try {
    const { employeeId, month, year, tdsAmount } = req.body;

    if (!employeeId || !month || !year || !tdsAmount) {
      return res.status(400).json({ error: "Missing required fields" });
    }

    let result = await PayrollResult.findOne({ employeeId, month, year });

    if (result) {
      result.tds = tdsAmount;
      await result.save();
    } else {
      result = await PayrollResult.create({
        employeeId,
        month,
        year,
        tds: tdsAmount,
      });
    }

    return res.status(200).json({
      message: "Monthly TDS saved successfully",
      data: result,
    });
  } catch (error) {
    console.error("saveMonthlyTds error:", error);
    res.status(500).json({ error: "Server Error" });
  }
};

/**
 * ======================================================
 * 4. GET EMPLOYEE TDS DETAILS (Declaration + Monthly + Salary)
 * ======================================================
 */
export const getEmployeeTds = async (req, res) => {
  try {
    const { employeeId, year } = req.params;

    const declaration = await TdsDeclaration.findOne({
      employeeId,
      financialYear: year,
    });

    const salary = await SalaryDetails.findOne({ employeeId });

    const monthlyTds = await PayrollResult.find({
      employeeId,
      year,
    });

    return res.status(200).json({
      message: "TDS record fetched",
      declaration,
      salary,
      monthlyTds,
    });
  } catch (error) {
    console.error("getEmployeeTds error:", error);
    res.status(500).json({ error: "Server Error" });
  }
};


// =========================================================
// === GET SINGLE EMPLOYEE PAYROLL
// =========================================================
export const getSingleEmployeePayroll = async (req, res) => {
    try {
        const { employeeId } = req.params;
        const { month, year } = req.query;

        if (!month || !year) {
            return res.status(400).json({ message: "Month and Year are required query parameters" });
        }

        const numMonth = Number(month);
        const numYear = Number(year);

        const employee = await Employee.findById(employeeId).select("basic personal employment").lean();
        if (!employee) return res.status(404).json({ message: "Employee not found" });

        const salary = await SalaryDetails.findOne({ employeeId }).sort({ createdAt: -1 }).lean();

        // Robust Attendance Check
        const attendance = await Attendance.findOne({
            employeeId,
            $or: [
                { "monthlyAttendance.month": numMonth, "monthlyAttendance.year": numYear },
                { month: numMonth, year: numYear }
            ]
        }).lean();

        let specificMonthAttendance = attendance;
        if (attendance?.monthlyAttendance) {
            specificMonthAttendance = attendance.monthlyAttendance.find(m => m.month === numMonth && m.year === numYear) || attendance;
        }

        const payrollResult = await PayrollResult.findOne({
            employeeId,
            month: numMonth, 
            year: numYear
        }).lean();

        const advanceLedgers = await AdvanceLedger.find({ employeeId }).lean();
        
        const advanceInfo = advanceLedgers.reduce((acc, ledger) => {
            acc.totalAdvanced += (ledger.advanceAmount || 0);
            acc.history.push({
                type: ledger.advanceType,
                amount: ledger.advanceAmount || 0,
                issueDate: ledger.issueDate,
                status: ledger.status,
                balance: ledger.outstandingBalance
            });
            if (ledger.status === "Active") {
                acc.outstandingBalance += (ledger.outstandingBalance || 0);
                acc.activeCount += 1;
            }
            return acc;
        }, { totalAdvanced: 0, outstandingBalance: 0, activeCount: 0, history: [] });

        let pendingEarningsInfo = { pendingIncentiveAmount: 0, pendingReimbursementAmount: 0 };
        const earningTx = await EarningTransaction.find({
            employeeId,
            processed: false,
            payMonth: numMonth,
            payYear: numYear,
            type: { $in: ["Incentive", "Reimbursement"] }
        }).lean();

        earningTx.forEach(tx => {
            if (tx.type === "Incentive") pendingEarningsInfo.pendingIncentiveAmount += (tx.amount || 0);
            if (tx.type === "Reimbursement") pendingEarningsInfo.pendingReimbursementAmount += (tx.amount || 0);
        });

        // ✅ Corrected History Fetch (Sort Descending by Date)
        const salaryHistory = await PayrollResult.find({ employeeId })
            .sort({ year: -1, month: -1 })
            .limit(12)
            .lean();

        return res.json({
            message: "Single employee payroll fetched successfully",
            data: {
                employee,
                salaryStructure: salary,
                attendanceSummary: specificMonthAttendance,
                payslip: payrollResult,
                advances: advanceInfo,
                pendingEarnings: pendingEarningsInfo,
                history: salaryHistory 
            }
        });

    } catch (error) {
        console.error("Error fetching single employee payroll:", error);
        return res.status(500).json({ message: "Server error", error: error.message });
    }
};

// Example Controller to add to your backend
export const getPaymentHistory = async (req, res) => {
  try {
    const { companyId } = req.params;
    const { year, month } = req.query;

    // This depends on where you saved the data in 'savePayment'
    // Assuming you have a Payment collection
    const payments = await Payment.find({ 
        companyId,
        year: Number(year),
        month: Number(month)
    }).populate('employeeId', 'basic.fullName basic.jobTitle basic.branches basic.departments');

    const formatted = payments.map(p => ({
        id: p._id,
        name: p.employeeId?.basic?.fullName || "Unknown",
        paymentDate: p.paymentDate || p.createdAt,
        paymentType: p.paymentMode || "Bank Transfer", // Default if not saved
        amountPaid: p.amount,
        status: "completed", // If it's in payment history, it's done
        branch: p.employeeId?.basic?.branches?.[0], // For filtering
        department: p.employeeId?.basic?.departments?.[0] // For filtering
    }));

    res.json(formatted);
  } catch (err) {
    res.status(500).json({ message: "Failed to fetch history" });
  }
};

export const getPayrollTrend = async (req, res) => {
  try {
    const { companyId } = req.params;
    
    // 1. Get all Employees belonging to this Company
    // We check if the employee's branch array contains the companyId
    const employees = await Employee.find({ 
        "basic.branches": { $in: [companyId] } 
    }).select('_id');

    const employeeIds = employees.map(e => e._id);

    if (employeeIds.length === 0) {
        return res.json([]); // No employees, no trend
    }

    // 2. Get date 6-12 months ago to filter recent data
    const d = new Date();
    d.setMonth(d.getMonth() - 11); // Last 12 months
    d.setDate(1);

    // 3. Aggregate Payroll Results based on Employee IDs
    const trend = await PayrollResult.aggregate([
      {
        $match: {
          employeeId: { $in: employeeIds }, // ✅ Match Employees, not Company field
          createdAt: { $gte: d }
        }
      },
      {
        $group: {
          _id: { 
            month: "$month", // ✅ Group by the stored payroll month (e.g., 12)
            year: "$year"    // ✅ Group by the stored payroll year (e.g., 2025)
          },
          totalSalary: { $sum: "$netPay" }, // ✅ Matches schema: netPay
          totalDeductions: { $sum: "$deductions.totalDeductions" } // ✅ Matches schema: deductions nested object
        }
      },
      { $sort: { "_id.year": 1, "_id.month": 1 } }
    ]);

    // 4. Format for Frontend (Recharts)
    const formattedStats = trend.map(item => {
        // Create date object for Label (Month Name)
        // JS Date month is 0-indexed (0=Jan), but DB stored 1-indexed (1=Jan)
        const date = new Date(item._id.year, item._id.month - 1); 
        
        return {
            month: date.toLocaleString('default', { month: 'short' }), // e.g. "Jan"
            fullDate: date,
            salary: item.totalSalary || 0,
            deductions: item.totalDeductions || 0
        };
    });

    res.status(200).json(formattedStats);
  } catch (error) {
    console.error("Payroll Trend Error:", error);
    res.status(500).json({ message: "Failed to fetch payroll trend" });
  }
};