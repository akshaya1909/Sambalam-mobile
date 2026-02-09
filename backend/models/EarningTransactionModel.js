import mongoose from "mongoose";

const EarningTransactionSchema = new mongoose.Schema({
    // Employee Link
    employeeId: { 
        type: String, 
        required: true, 
        index: true 
    }, 
    
    // Transaction Details
    type: {
        type: String,
        enum: ['Incentive', 'Reimbursement', 'Commission', 'Bonus'],
        required: true
    },
    amount: { 
        type: Number, 
        required: true, 
        min: 0 
    },
    description: {
        type: String,
        required: true,
        trim: true
    },
    transactionDate: {
        type: Date,
        required: true    // required or optional based on your needs
    },
    // Payroll Processing Context (When this amount should be paid)
    payMonth: { 
        type: Number, 
        required: true,
        min: 1, 
        max: 12
    },
    payYear: { 
        type: Number, 
        required: true 
    },
    
    // Status
    processed: {
        type: Boolean,
        default: false,
        // True if this transaction has been successfully included in a PayrollResult record
    },
    processedPayrollResultId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'PayrollResult'
    }

}, { timestamps: true });

// ✅ FIX: Check if model exists in mongoose.models before compiling
const EarningTransaction = mongoose.models.EarningTransaction || mongoose.model("EarningTransaction", EarningTransactionSchema);

export default EarningTransaction;