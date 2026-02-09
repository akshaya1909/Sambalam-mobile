import mongoose from "mongoose";

const AdvanceLedgerSchema = new mongoose.Schema({
    // Employee Link
    employeeId: { 
        type: String, 
        required: true, 
        index: true 
    }, 
    
    // Loan Details
    advanceType: {
        type: String,
        enum: ['Salary Advance', 'Loan'],
        default: 'Salary Advance'
    },
    advanceAmount: { 
        type: Number, 
        required: true, 
        min: 0 
    },
    
    // Repayment Schedule
    monthlyDeduction: { 
        type: Number, 
        required: true, 
        min: 0 
    },
    outstandingBalance: { 
        type: Number, 
        required: true, 
        default: 0 
    },
    
    // Status and Dates
    issueDate: { 
        type: Date, 
        required: true 
    },
    status: { 
        type: String, 
        enum: ['Active', 'Closed', 'On Hold'], 
        default: 'Active' 
    },
    
    // Audit log (to track manual adjustments or repayments)
    repaymentHistory: [{
        date: Date,
        amount: Number,
        payrollMonth: Number,
        payrollYear: Number,
        transactionType: String // 'Monthly Deduction', 'Manual Payment'
    }]

}, { timestamps: true });

const AdvanceLedger = mongoose.model("AdvanceLedger", AdvanceLedgerSchema);
export default AdvanceLedger;