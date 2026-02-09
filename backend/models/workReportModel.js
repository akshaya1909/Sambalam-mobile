import mongoose from "mongoose";

const reportEntrySchema = new mongoose.Schema({
  templateId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'WorkReportTemplate',
    required: true
  },
  date: { type: Date, required: true },
  entries: [
    {
      data: [
        {
          fieldLabel: String,
          value: mongoose.Schema.Types.Mixed
        }
      ],
      submittedAt: { type: Date, default: Date.now }
    }
  ],
  status: {
    type: String,
    enum: ['submitted', 'reviewed', 'flagged'],
    default: 'submitted'
  },
  adminRemarks: String,
  reviewedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }
}, { _id: true });

const monthlyWorkReportSchema = new mongoose.Schema({
  companyId: { type: mongoose.Schema.Types.ObjectId, ref: 'Company', required: true },
  employeeId: { type: mongoose.Schema.Types.ObjectId, ref: 'Employee', required: true },
  year: { type: Number, required: true },
  month: { type: Number, required: true }, // 1-12
  reports: [reportEntrySchema]
}, { timestamps: true });

// Ensure one document per employee per month
monthlyWorkReportSchema.index({ companyId: 1, employeeId: 1, year: 1, month: 1 }, { unique: true });

export const WorkReport = mongoose.model('WorkReport', monthlyWorkReportSchema);

