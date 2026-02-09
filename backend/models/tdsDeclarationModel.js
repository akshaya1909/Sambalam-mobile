import mongoose from "mongoose";

const TDSDeclarationSchema = new mongoose.Schema({
    // Employee Link
    employeeId: { 
        type: String, 
        required: true, 
    }, 
    
    // Financial Year Details
    assessmentYear: { 
        type: String, 
        required: true,
        default: '2025-2026' // Example format
    }, 
    
    // Regime Choice
    taxScheme: {
        type: String,
        enum: ['New Regime', 'Old Regime'],
        required: true
    },
    
    // Declared Investment Details (Used for Old Regime tax calculation)
    declaredInvestments: { 
        type: Number, 
        default: 0 
    }, 
    
    // Optional: Exemptions claimed (like HRA or LTA proof)
    exemptions: [{
        section: String,
        amount: Number,
        description: String
    }],
    
    // Calculated/Projected Monthly TDS (Can be stored here after annual projection)
    projectedMonthlyTDS: {
        type: Number,
        default: 0
    },

    dateOfDeclaration: {
        type: Date,
        default: Date.now
    }

}, { timestamps: true });

const TDSDeclaration = mongoose.model("TDSDeclaration", TDSDeclarationSchema);
export default TDSDeclaration;