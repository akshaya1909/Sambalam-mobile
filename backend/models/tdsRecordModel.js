import mongoose from 'mongoose';

const tdsRecordSchema = mongoose.Schema({
    employee: { type: mongoose.Schema.Types.ObjectId, ref: 'Employee', required: true },
    financialYear: { type: String, required: true },
    name: { type: String }, 
    
    // --- Header Summaries ---
    regime: { type: String, default: 'New Regime' }, 
    
    // ✅ COMPARISON FIELDS
    taxLiabilityNew: { type: Number, default: 0 },
    taxLiabilityOld: { type: Number, default: 0 },
    
    totalEarnings: { type: Number, default: 0 },
    standardDeduction: { type: Number, default: 75000 },
    exemptions: { type: Number, default: 0 },
    deductions: { type: Number, default: 0 },
    grossTaxableIncome: { type: Number, default: 0 },
    totalTaxLiability: { type: Number, default: 0 },
    taxPaidSoFar: { type: Number, default: 0 },
    
    // --- The 12-Month Matrix ---
    monthlyBreakdown: [{
        month: { type: String },
        monthIndex: { type: Number },
        year: { type: Number },
        isActual: { type: Boolean, default: false },
        
        // Earnings
        basic: { type: Number, default: 0 },
        hra: { type: Number, default: 0 },
        special: { type: Number, default: 0 },
        bonus: { type: Number, default: 0 },
        travel: { type: Number, default: 0 },       
        overtime: { type: Number, default: 0 },     
        incentives: { type: Number, default: 0 },   
        reimbursement: { type: Number, default: 0 },
        other: { type: Number, default: 0 },
        
        totalMonthEarnings: { type: Number, default: 0 },
        
        // Deductions
        pf: { type: Number, default: 0 },
        pt: { type: Number, default: 0 },
        esi: { type: Number, default: 0 }, 
        
        // Recoveries
        fineDeduction: { type: Number, default: 0 },
        advanceDeduction: { type: Number, default: 0 },
        
        // Tax
        taxPaid: { type: Number, default: 0 },
        taxPayable: { type: Number, default: 0 }
    }],

    status: { type: String, default: 'Active' }
}, { timestamps: true });

export default mongoose.model('TdsRecord', tdsRecordSchema);