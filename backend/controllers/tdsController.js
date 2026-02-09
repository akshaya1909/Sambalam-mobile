import TdsRecord from '../models/tdsRecordModel.js';
import Employee from '../models/employeeModel.js';
import { SalaryDetails } from '../models/salaryDetailsModel.js';
import PayrollResult from '../models/payrollResultModel.js';
import EarningTransaction from '../models/EarningTransactionModel.js';
import AdvanceLedger from '../models/advanceLedgerModel.js';
import Attendance from '../models/attendanceModel.js';
import { PenaltyAndOvertime } from '../models/penaltyAndOvertimeModel.js';
import BgVerification from '../models/bgVerificationModel.js'; 
import Company from '../models/companyModel.js'; 

// =====================================================================
// === HELPERS: TAX CALCULATORS & FINES
// =====================================================================
const calcNewRegime = (income) => {
    if (income <= 300000) return 0;
    if (income <= 700000) return 0; // Rebate u/s 87A

    let tax = 0;
    if (income > 300000) tax += Math.min(income - 300000, 400000) * 0.05;   // 3L-7L
    if (income > 700000) tax += Math.min(income - 700000, 300000) * 0.10;   // 7L-10L
    if (income > 1000000) tax += Math.min(income - 1000000, 200000) * 0.15; // 10L-12L
    if (income > 1200000) tax += Math.min(income - 1200000, 300000) * 0.20; // 12L-15L
    if (income > 1500000) tax += (income - 1500000) * 0.30;                 // >15L
    
    return Math.round(tax * 1.04); // Cess 4%
};

const calcOldRegime = (income) => {
    if (income <= 250000) return 0;
    if (income <= 500000) return 0; // Rebate u/s 87A

    let tax = 0;
    if (income > 250000) tax += Math.min(income - 250000, 250000) * 0.05;   // 2.5L-5L
    if (income > 500000) tax += Math.min(income - 500000, 500000) * 0.20;   // 5L-10L
    if (income > 1000000) tax += (income - 1000000) * 0.30;                 // >10L
    
    return Math.round(tax * 1.04); // Cess 4%
};

const calculateFinesAndOT = (attendance, penaltyPolicy, month, year) => {
    let lateFine = 0, earlyFine = 0, overtimeHours = 0;
    let records = [];
    if (attendance?.monthlyAttendance) {
        const mRecord = attendance.monthlyAttendance.find(m => m.month === month && m.year === year);
        if (mRecord) records = mRecord.records;
    } else if (attendance?.month === month && attendance?.year === year) {
        records = attendance.records;
    }
    if (!records || records.length === 0) return { lateFine, earlyFine, overtimeHours };

    let lateCount = 0, earlyCount = 0;
    records.forEach(r => {
        if (r.punchIn?.status === "Late") lateCount++;
        if (r.punchOut?.status === "Early") earlyCount++;
        if (r.punchOut?.status === "Over Time" && r.punchIn?.time && r.punchOut?.time) {
             const hrs = (new Date(r.punchOut.time) - new Date(r.punchIn.time)) / 36e5;
             if(hrs > 9) overtimeHours += (hrs - 9);
        }
    });

    if (penaltyPolicy) {
        if (penaltyPolicy.lateComingPolicy && lateCount > (penaltyPolicy.lateComingPolicy.allowedLateDays || 0)) {
            lateFine = (lateCount - penaltyPolicy.lateComingPolicy.allowedLateDays) * (penaltyPolicy.lateComingPolicy.amount || 0);
        }
        if (penaltyPolicy.earlyLeavingPolicy && earlyCount > (penaltyPolicy.earlyLeavingPolicy.allowedEarlyLeavingDays || 0)) {
            earlyFine = (earlyCount - penaltyPolicy.earlyLeavingPolicy.allowedEarlyLeavingDays) * (penaltyPolicy.earlyLeavingPolicy.amount || 0);
        }
    }
    return { lateFine, earlyFine, overtimeHours };
};

// =====================================================================
// === CONTROLLER 1: GENERATE TDS MATRIX
// =====================================================================
export const generateTdsMatrix = async (req, res) => {
    try {
        console.log("🚀 Starting Full TDS Calculation...");
        const { financialYear, companyId } = req.body;
        
        if (!financialYear || !companyId) {
            return res.status(400).json({ message: "Financial Year and Company ID are required." });
        }

        const [startYearStr, endYearStr] = financialYear.split('-');
        const startYear = parseInt(startYearStr);
        const endYear = parseInt(endYearStr);
        const currentProcessingMonth = new Date(new Date().getFullYear(), new Date().getMonth(), 1); 

        const employees = await Employee.find({ "basic.branches": { $in: [companyId] } });
        const bulkOps = [];

        for (const emp of employees) {
            const empId = emp._id;
            
            // --- 1. FETCH DATA ---
            const [salaryParams, attendanceDoc, penaltyPolicy, advanceLedgers, earningsTx, bgData] = await Promise.all([
                SalaryDetails.findOne({ employeeId: empId }).sort({ createdAt: -1 }),
                Attendance.findOne({ employeeId: empId }),
                PenaltyAndOvertime.findOne({ employeeId: empId }),
                AdvanceLedger.find({ employeeId: empId, status: 'Active' }),
                EarningTransaction.find({ 
                    employeeId: empId, 
                    transactionDate: { $gte: new Date(`${startYear}-04-01`), $lte: new Date(`${endYear}-03-31`) }
                }),
                BgVerification.findOne({ employee: empId }) 
            ]);

            // --- 2. DETERMINE EMPLOYEE TYPE & STATUS ---
            const employmentDetails = emp.employment?.[0] || {}; 
            const employeeType = employmentDetails.employeeType || "Permanent";
            const entityType = employmentDetails.entityType || "Individual"; 
            
            const designation = (emp.basic?.jobTitle || "").toLowerCase();
            const depts = emp.basic?.departments || [];
            const singleDept = emp.basic?.department || "";
            const departmentStr = (depts[0] || singleDept).toLowerCase();

            // 1. Check Partner (194T - Top Priority)
            const isPartner = designation.includes("partner"); 

            // 2. Check Management (Broad Definition for Privileges like skipping fines)
            // Includes Department "Management", or Titles MD/CEO/Director
            const isManagementPrivilege = departmentStr.includes('management') 
                                 || isPartner 
                                 || designation.includes("director") 
                                 || designation.includes("ceo") 
                                 || designation.includes("md")
                                 || designation.includes("managing");

            // PAN Check
            const panNumber = bgData?.pan?.docNumber || emp.personal?.panNumber;
            const hasValidPan = panNumber && panNumber.length === 10;

            const loanBalances = {};
            advanceLedgers.forEach(adv => { loanBalances[adv._id.toString()] = Number(adv.outstandingBalance || 0); });

            const monthsOrder = [
                { name: "April", m: 4, y: startYear }, { name: "May", m: 5, y: startYear },
                { name: "June", m: 6, y: startYear }, { name: "July", m: 7, y: startYear },
                { name: "August", m: 8, y: startYear }, { name: "September", m: 9, y: startYear },
                { name: "October", m: 10, y: startYear }, { name: "November", m: 11, y: startYear },
                { name: "December", m: 12, y: startYear }, { name: "January", m: 1, y: endYear },
                { name: "February", m: 2, y: endYear }, { name: "March", m: 3, y: endYear }
            ];

            const monthlyBreakdown = [];
            let totalAnnualEarnings = 0;
            let totalTaxPaidSoFar = 0;
            let totalPF = 0, totalPT = 0;

            // --- 3. CALCULATE MONTHLY INCOME ---
            for (const period of monthsOrder) {
                const actualPayroll = await PayrollResult.findOne({
                    employeeId: empId, month: period.m, year: period.y
                });

                let monthData = {
                    month: period.name, monthIndex: period.m, year: period.y, isActual: false,
                    basic: 0, hra: 0, special: 0, bonus: 0, travel: 0, overtime: 0, incentives: 0, reimbursement: 0, other: 0,
                    totalMonthEarnings: 0, pf: 0, pt: 0, esi: 0, 
                    advanceDeduction: 0, fineDeduction: 0, 
                    taxPaid: 0, taxPayable: 0
                };

                const periodStart = new Date(period.y, period.m - 1, 1);
                const periodEnd = new Date(period.y, period.m, 0); 
                const isPast = periodStart < currentProcessingMonth;

                if (actualPayroll) {
                    // === ACTUALS ===
                    monthData.isActual = true;
                    const e = actualPayroll.earnings || {};
                    const d = actualPayroll.deductions || {};

                    monthData.basic = e.baseSalary || 0;
                    monthData.hra = e.hra || 0;
                    monthData.special = e.specialAllowance || 0;
                    monthData.bonus = e.bonus || 0;
                    monthData.travel = e.travelAllowance || 0;
                    monthData.overtime = e.overtimePay || 0;
                    monthData.incentives = e.incentives || 0;
                    monthData.reimbursement = e.reimbursements || 0;
                    monthData.other = e.otherEarnings || 0;
                    monthData.totalMonthEarnings = e.grossEarned || 0;

                    monthData.pf = d.epf || 0;
                    monthData.esi = d.esi || 0;
                    monthData.pt = d.professionalTax || 0;
                    monthData.taxPaid = d.tds || 0;
                    monthData.fineDeduction = (d.lateFine || 0) + (d.earlyFine || 0);
                    
                    const actualDeduction = Number(d.loanDeducted || 0);
                    monthData.advanceDeduction = actualDeduction;

                    let deductionToDistribute = actualDeduction;
                    for (const loanId in loanBalances) {
                        if (deductionToDistribute <= 0) break;
                        if (loanBalances[loanId] > 0) {
                            const taken = Math.min(loanBalances[loanId], deductionToDistribute);
                            loanBalances[loanId] -= taken;
                            deductionToDistribute -= taken;
                        }
                    }

                } else {
                    // === PROJECTIONS ===
                    if (!isPast && salaryParams) {
                        const doj = emp.employment?.[0]?.dateOfJoining ? new Date(emp.employment[0].dateOfJoining) : new Date('1990-01-01');
                        
                        if (periodEnd >= doj) {
                            const earnings = salaryParams.earnings || [];
                            let monthlyGross = 0;
                            
                            earnings.forEach(item => {
                                let amt = item.amount || 0; 
                                if(salaryParams.salaryType === 'Per Annum') amt = amt / 12;
                                
                                // Full Salary for Management, Prorated otherwise? (Assuming full for projection)
                                const head = (item.head || "").toLowerCase();
                                if (head.includes('basic')) monthData.basic += amt;
                                else if (head.includes('hra')) monthData.hra += amt;
                                else if (head.includes('special')) monthData.special += amt;
                                else if (head.includes('travel')) monthData.travel += amt;
                                else monthData.other += amt;
                                monthlyGross += amt;
                            });

                            const monthTx = earningsTx.filter(t => t.payMonth === period.m && t.payYear === period.y);
                            monthTx.forEach(tx => {
                                if(tx.type === 'Incentive') monthData.incentives += tx.amount;
                                if(tx.type === 'Reimbursement') monthData.reimbursement += tx.amount;
                                if(tx.type === 'Bonus') monthData.bonus += tx.amount;
                            });

                            // ✅ SKIP PENALTIES FOR MANAGEMENT (Use Privilege Flag)
                            if (!isManagementPrivilege) {
                                const { lateFine, earlyFine, overtimeHours } = calculateFinesAndOT(attendanceDoc, penaltyPolicy, period.m, period.y);
                                if (overtimeHours > 0) {
                                    const hourlyRate = (monthData.basic > 0) ? (monthData.basic / 30 / 8) : 0;
                                    monthData.overtime = Math.round(overtimeHours * hourlyRate);
                                }
                                monthData.fineDeduction = lateFine + earlyFine;
                            }

                            advanceLedgers.forEach(adv => {
                                const loanId = adv._id.toString();
                                const currentBal = loanBalances[loanId];
                                if (new Date(adv.issueDate) <= periodEnd && currentBal > 0) {
                                    const deduction = Math.min(adv.monthlyDeduction, currentBal);
                                    monthData.advanceDeduction += deduction;
                                    loanBalances[loanId] -= deduction; 
                                }
                            });

                            monthData.totalMonthEarnings = monthData.basic + monthData.hra + monthData.special + 
                                                           monthData.bonus + monthData.travel + monthData.overtime + 
                                                           monthData.incentives + monthData.reimbursement + monthData.other;

                            // ✅ SKIP STATUTORY DEDUCTIONS FOR MANAGEMENT & CONTRACTORS
                            if (!isManagementPrivilege && employeeType !== "Contract" && employeeType !== "Consultant") {
                                if (monthData.totalMonthEarnings > 15000) monthData.pt = 200;
                                monthData.pf = Math.min(monthData.basic, 15000) * 0.12; 
                                if (monthData.totalMonthEarnings <= 21000 && monthData.totalMonthEarnings > 0) {
                                    monthData.esi = Math.ceil(monthData.totalMonthEarnings * 0.0075);
                                }
                            }
                        }
                    }
                }

                totalAnnualEarnings += monthData.totalMonthEarnings;
                totalTaxPaidSoFar += monthData.taxPaid;
                totalPF += monthData.pf;
                totalPT += monthData.pt;
                
                monthlyBreakdown.push(monthData);
            }

            // =============================================================================
            // --- 4. TAX CALCULATION LOGIC (REORDERED PRIORITY) ---
            // =============================================================================
            
            let finalTaxLiability = 0;
            let taxNew = 0;
            let taxOld = 0;
            let regimeName = "New Regime";
            let standardDeduction = 0;
            let grossTaxable = 0;

            if (isPartner) {
                // === PRIORITY 1: PARTNER (194T) ===
                regimeName = "194T Partner";
                standardDeduction = 0;
                grossTaxable = totalAnnualEarnings;

                if (totalAnnualEarnings > 20000) {
                    finalTaxLiability = Math.round(totalAnnualEarnings * (hasValidPan ? 0.10 : 0.20));
                }
                taxNew = finalTaxLiability;
                taxOld = finalTaxLiability;

            } else if (employeeType === "Contract") {
                // === PRIORITY 2: CONTRACTOR (194C) ===
                // Moves ABOVE Management check to solve Aakash's case (MD + Contract)
                regimeName = `194C (${entityType})`;
                standardDeduction = 0;
                grossTaxable = totalAnnualEarnings;
                
                let isTaxable = totalAnnualEarnings > 100000 || monthlyBreakdown.some(m => m.totalMonthEarnings > 30000);
                
                if (isTaxable) {
                    let rate = (entityType === "Individual" || entityType === "HUF") ? 0.01 : 0.02;
                    if (!hasValidPan) rate = 0.20;
                    finalTaxLiability = Math.round(totalAnnualEarnings * rate);
                }
                taxNew = finalTaxLiability;
                taxOld = finalTaxLiability;

            } else if (employeeType === "Consultant") {
                // === PRIORITY 3: CONSULTANT (194J) ===
                regimeName = "194J Professional";
                standardDeduction = 0;
                grossTaxable = totalAnnualEarnings;
                if (totalAnnualEarnings > 30000) {
                    finalTaxLiability = Math.round(totalAnnualEarnings * (hasValidPan ? 0.10 : 0.20));
                }
                taxNew = finalTaxLiability;
                taxOld = finalTaxLiability;

            } else if (isManagementPrivilege) {
                // === PRIORITY 4: MANAGEMENT (194T) ===
                // Applies to MDs/Directors/Management Dept who are NOT Contract/Consultant/Partner
                
                regimeName = "194T (Management)";
                standardDeduction = 0;
                grossTaxable = totalAnnualEarnings;

                if (totalAnnualEarnings > 20000) {
                    finalTaxLiability = Math.round(totalAnnualEarnings * (hasValidPan ? 0.10 : 0.20));
                }
                taxNew = finalTaxLiability;
                taxOld = finalTaxLiability;

            } else {
                // === PRIORITY 5: SALARY (192) ===
                const stdDedAmt = 75000; 
                standardDeduction = stdDedAmt;
                
                const taxableNew = Math.max(totalAnnualEarnings - stdDedAmt, 0); 
                taxNew = calcNewRegime(taxableNew);

                const ded80C = Math.min(totalPF, 150000); 
                const totalDedOld = ded80C + totalPT; 
                const taxableOld = Math.max(totalAnnualEarnings - 50000 - totalDedOld, 0); 
                taxOld = calcOldRegime(taxableOld);

                finalTaxLiability = taxNew <= taxOld ? taxNew : taxOld;
                regimeName = taxNew <= taxOld ? 'New Regime' : 'Old Regime';
                grossTaxable = taxableNew;
            }

            // --- 5. DISTRIBUTE REMAINING TAX ---
            const remainingTax = Math.max(finalTaxLiability - totalTaxPaidSoFar, 0);
            const futureMonths = monthlyBreakdown.filter(m => !m.isActual && m.totalMonthEarnings > 0);
            
            if (futureMonths.length > 0) {
                const taxPerMonth = remainingTax / futureMonths.length;
                monthlyBreakdown.forEach(m => {
                    if (!m.isActual && m.totalMonthEarnings > 0) m.taxPayable = Math.round(taxPerMonth);
                });
            }

            // --- 6. SAVE RECORD ---
            bulkOps.push({
                updateOne: {
                    filter: { employee: empId, financialYear },
                    update: {
                        $set: {
                            name: emp.basic?.fullName,
                            regime: regimeName,
                            taxLiabilityNew: taxNew, 
                            taxLiabilityOld: taxOld, 
                            totalEarnings: Math.round(totalAnnualEarnings),
                            standardDeduction: standardDeduction,
                            deductions: Math.round(totalPF + totalPT), 
                            grossTaxableIncome: Math.round(grossTaxable),
                            totalTaxLiability: finalTaxLiability,
                            taxPaidSoFar: totalTaxPaidSoFar,
                            panAvailable: hasValidPan,
                            monthlyBreakdown, 
                            status: 'Active'
                        }
                    },
                    upsert: true
                }
            });
        }

        if (bulkOps.length > 0) await TdsRecord.bulkWrite(bulkOps);
        res.json({ message: "TDS Calculation Completed Successfully", count: bulkOps.length });

    } catch (error) {
        console.error("TDS Calculation Error:", error);
        res.status(500).json({ message: error.message });
    }
};

// ... (getTdsRecords remains same) ...
export const getTdsRecords = async (req, res) => {
    try {
        const { financialYear } = req.query;
        const records = await TdsRecord.find({ financialYear }).populate({ path: 'employee', select: 'basic.fullName basic.jobTitle basic.branches basic.departments' }).lean();
        const branchIds = [...new Set(records.map(r => r.employee?.basic?.branches?.[0]).filter(Boolean))];
        const companies = await Company.find({ _id: { $in: branchIds } }).select("name").lean();
        const companyMap = {};
        companies.forEach(c => companyMap[String(c._id)] = c.name);

        const formatted = records.map(rec => {
            const empBasic = rec.employee?.basic || {};
            const branchId = empBasic.branches?.[0];
            const branchName = companyMap[String(branchId)] || "Main Branch";
            const department = empBasic.departments?.[0] || "General";

            return {
                id: rec._id,
                name: empBasic.fullName || rec.name,
                role: empBasic.jobTitle || 'N/A',
                branch: branchName,       
                department: department,   
                regime: rec.regime,
                totalEarnings: rec.totalEarnings || 0,
                taxNew: rec.taxLiabilityNew || 0,
                taxOld: rec.taxLiabilityOld || 0,
                stdDeduction: rec.standardDeduction || 0,
                taxable: rec.grossTaxableIncome || 0,
                taxLiability: rec.totalTaxLiability || 0,
                monthlyBreakdown: rec.monthlyBreakdown || [], 
                initials: (empBasic.fullName || "A").substring(0,2).toUpperCase(),
                color: 'bg-primary text-white'
            };
        });
        res.json(formatted);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};