import mongoose from "mongoose";

const planSchema = new mongoose.Schema({
    name: { type: String, required: true },
    description: { type: String }, // The short subtitle
    price: { type: Number, required: true, min: 0 },
    billingCycle: { 
        type: String, 
        enum: ["monthly", "quarterly", "annual", "custom"], 
        default: "annual" 
    },
    durationMonths: { type: Number, min: 0 }, // Used if cycle is custom
    maxCompanies: { type: Number, default: 1, min: 0 },
    maxEmployees: { type: Number, default: 20, min: 0 },
    features: [{ type: String }], // Array of bullet points
    isPopular: { type: Boolean, default: false },
    isActive: { type: Boolean, default: true }
}, { timestamps: true });

const Plan = mongoose.model("Plan", planSchema);
export default Plan;