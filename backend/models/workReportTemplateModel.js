import mongoose from "mongoose";

const workReportTemplateSchema = new mongoose.Schema({
  companyId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Company',
    required: true
  },
  isForAllDepartments: { type: Boolean, default: false },
  departmentIds: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Department'
  }],
  title: { type: String, default: "Daily Work Report" },
  fields: [
    {
      label: { type: String, required: true }, // e.g., "Work Done", "Percentage Completed"
      fieldType: { 
        type: String, 
        enum: ["text", "number", "date", "dropdown", "boolean","image", "file"], 
        required: true 
      },
      isRequired: { type: Boolean, default: true },
      options: [String], // Only used if fieldType is "dropdown"
      placeholder: String
    }
  ],
  isActive: { type: Boolean, default: true },
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }
}, { timestamps: true });

// Ensure one template per department per company
workReportTemplateSchema.index({ companyId: 1, departmentIds: 1 }, { unique: true, partialFilterExpression: { isForAllDepartments: false } });

export const WorkReportTemplate = mongoose.model('WorkReportTemplate', workReportTemplateSchema);