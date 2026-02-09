import mongoose from "mongoose";

const payrollResultSchema = new mongoose.Schema({
  employeeId: { type: mongoose.Schema.Types.ObjectId, ref: 'Employee', required: true },
  
  // Period Details
  month: { type: Number, required: true },
  year: { type: Number, required: true },
  payPeriodStart: { type: Date, required: true },
  payPeriodEnd: { type: Date, required: true },
  payrollDate: { type: Date, default: Date.now },

  // --- ATTENDANCE SNAPSHOT ---
  attendance: {
    daysInMonth: { type: Number, default: 0 },
    payableDays: { type: Number, default: 0 },
    presentDays: { type: Number, default: 0 },
    weekOffs: { type: Number, default: 0 },
    holidays: { type: Number, default: 0 },
    paidLeaves: { type: Number, default: 0 },
    unpaidLeaves: { type: Number, default: 0 },
    overtimeHours: { type: Number, default: 0 }
  },

  // --- EARNINGS ---
  earnings: {
    baseSalary: { type: Number, default: 0 },
    hra: { type: Number, default: 0 },
    specialAllowance: { type: Number, default: 0 },
    travelAllowance: { type: Number, default: 0 },
    otherEarnings: { type: Number, default: 0 },
    
    overtimePay: { type: Number, default: 0 },
    incentives: { type: Number, default: 0 },
    reimbursements: { type: Number, default: 0 },
    bonus: { type: Number, default: 0 },
    
    grossEarned: { type: Number, default: 0 },     
    totalEarnings: { type: Number, default: 0 }    
  },

  // --- DEDUCTIONS ---
  deductions: {
    epf: { type: Number, default: 0 },
    esi: { type: Number, default: 0 },
    professionalTax: { type: Number, default: 0 },
    loanDeducted: { type: Number, default: 0 },
    lateFine: { type: Number, default: 0 },
    earlyFine: { type: Number, default: 0 },
    tds: { type: Number, default: 0 }, // <--- The field causing error
    otherDeductions: { type: Number, default: 0 },
    
    totalDeductions: { type: Number, default: 0 }
  },

  // --- EMPLOYER CONTRIBUTIONS ---
  employer: {
    epf: { type: Number, default: 0 },
    esi: { type: Number, default: 0 },
    lwf: { type: Number, default: 0 }
  },

  // --- FINAL PAY ---
  netPay: { type: Number, required: true },

  // --- STATUS ---
  paymentStatus: { 
    type: String, 
    enum: ['Pending', 'Partial', 'Paid'], 
    default: 'Pending' 
  },
  paidAmount: { type: Number, default: 0 },
  pendingAmount: { type: Number, default: 0 },
  
  slipShared: { type: Boolean, default: false },
  bankVerified: { type: Boolean, default: false }

}, { timestamps: true });

// Prevent duplicate payrolls for same month/year
payrollResultSchema.index({ employeeId: 1, month: 1, year: 1 }, { unique: true });

const PayrollResult = mongoose.model('PayrollResult', payrollResultSchema);
export default PayrollResult;