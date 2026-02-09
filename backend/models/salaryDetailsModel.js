import mongoose from "mongoose";

// --- NESTED SCHEMAS ---

// effectiveMonthOfChangeSchema (No change)
const effectiveMonthOfChangeSchema = new mongoose.Schema({
    month: { type: Number, required: true }, // e.g. 1 = January, 12 = December
    year: { type: Number, required: true }
}, { _id: false });

// Earnings schema (No change)
const earningsSchema = new mongoose.Schema({
    head: { type: String, required: true },
    calculation: { type: String, enum: ["On Attendance", "Flat Rate"], required: true },
    amount: { type: Number, required: true }
}, { _id: false });

// Deduction schema (No change)
const deductionSchema = new mongoose.Schema({
    head: { type: String, required: true }, 
    calculation: { 
        type: String, 
        enum: ["On Attendance", "Flat Rate"], 
        required: true 
    },
    amount: { type: Number, required: true }
}, { _id: false });

// --- NEW/CORRECTED COMPLIANCE SCHEMAS ---

// 1. Schema for an individual compliance setting (e.g., PF Employee)
// This mirrors the structure of the state object sent from the frontend: {enabled: true, includedInCTC: false, type: "Statutory (12%)"}
const ComplianceSettingSchema = new mongoose.Schema({
    enabled: { type: Boolean, default: true },
    // Only relevant for employer contributions, but included for all for consistency
    includedInCTC: { type: Boolean, default: true }, 
    type: { type: String, required: true, default: 'Statutory' }
}, { _id: false });

// 2. Main Compliance Configuration Schema (The critical fix: defines keys as objects)
// This replaces the old 'complianceSchema' which used arrays.
const ComplianceConfigurationSchema = new mongoose.Schema({
    // Employee Contributions (Deductions from Net Pay)
    pfEmployee: ComplianceSettingSchema,
    esiEmployee: ComplianceSettingSchema,
    professionalTax: ComplianceSettingSchema,
    
    // Employer Contributions (Added to Gross Pay for CTC)
    pfEmployer: ComplianceSettingSchema,
    esiEmployer: ComplianceSettingSchema,
    
    // Add placeholders for other contributions if needed, e.g.,
    // edliAdminCharges: ComplianceSettingSchema,
    // lwf: ComplianceSettingSchema, 

}, { _id: false });


// --- MAIN SALARY DETAILS SCHEMA ---
const salaryDetailsSchema = new mongoose.Schema({
    employeeId: { type: mongoose.Schema.Types.ObjectId, ref: "Employee", required: true },
    effectiveMonthOfChange: { type: effectiveMonthOfChangeSchema, required: true },
    salaryType: { type: String, enum: ["Per Month", "Per Day", "Per Hour"], required: true },
    salaryStructure: { type: String, enum: ["Sambalam Provided", "Custom"], required: true },
    CTCAmount: { type: Number, default: 0 },

    // Show these only if salaryType === "Per Month"
    earnings: [{
        type: earningsSchema
    }],

    // FIX: Compliances should be a single embedded OBJECT, not an array.
    // This allows the keys (pfEmployee, esiEmployer) to be stored directly.
    compliances: { 
        type: ComplianceConfigurationSchema 
    },

    deductions: [{
        type: deductionSchema
    }]
}, { timestamps: true });

export const SalaryDetails = mongoose.model("SalaryDetails", salaryDetailsSchema);