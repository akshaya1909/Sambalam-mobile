import mongoose from "mongoose";

const addonSchema = new mongoose.Schema({
    label: { type: String, required: true },
    price: { type: Number, required: true, min: 0 },
    billingCycle: { 
        type: String, 
        enum: ["monthly", "quarterly", "halfyearly", "annual", "custom"], 
        default: "annual" 
    },
    durationMonths: { type: Number, min: 0 }
}, { timestamps: true });

const Addon = mongoose.model("Addon", addonSchema);
export default Addon;