import mongoose from "mongoose";

const componentSchema = new mongoose.Schema({
  name: { type: String, required: true },
  type: { type: String, enum: ["earning", "deduction"], required: true },
  calculationType: { 
    type: String, 
    enum: ["percentage", "flat"], 
    default: "percentage" 
  },
  value: { type: Number, required: true }, // Percentage or Flat Amount
  isStatutory: { type: Boolean, default: false } // To mark PF, ESI etc.
}, { _id: false });

const salaryTemplateSchema = new mongoose.Schema({
  companyId: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'Company', 
    required: true 
  },
  name: { type: String, required: true },
  description: { type: String },
  components: [componentSchema],
  isActive: { type: Boolean, default: true }
}, { timestamps: true });

const SalaryTemplate = mongoose.model("SalaryTemplate", salaryTemplateSchema);
export default SalaryTemplate;