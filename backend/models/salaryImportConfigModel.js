import mongoose from "mongoose";

const fieldSchema = new mongoose.Schema({
  id: { type: String, required: true }, // e.g., "basic", "hra"
  name: { type: String, required: true }, // e.g., "Basic Salary"
  enabled: { type: Boolean, default: true },
  required: { type: Boolean, default: false }
}, { _id: false });

const salaryImportConfigSchema = new mongoose.Schema({
  companyId: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'Company', 
    required: true,
    unique: true 
  },
  fields: [fieldSchema]
}, { timestamps: true });

const SalaryImportConfig = mongoose.model("SalaryImportConfig", salaryImportConfigSchema);
export default SalaryImportConfig;