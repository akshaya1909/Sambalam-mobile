import mongoose from "mongoose";

const featureSchema = new mongoose.Schema({
    name: { type: String, required: true, unique: true },
    // Array of Plan ObjectIds that include this feature
    enabledPlans: [{ 
        type: mongoose.Schema.Types.ObjectId, 
        ref: 'Plan' 
    }]
}, { timestamps: true });

const Feature = mongoose.model("Feature", featureSchema);
export default Feature;