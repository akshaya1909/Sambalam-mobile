import mongoose from "mongoose";

const reportHistorySchema = mongoose.Schema({
    companyId: { type: mongoose.Schema.Types.ObjectId, ref: 'Company', required: true },
    generatedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }, // HR/Admin who generated it
    reportType: { type: String, required: true }, // e.g., "Salary Sheet", "PF Challan"
    branch: { type: String, default: "All Branches" },
    department: { type: String, default: "All Departments" },
    duration: { type: String }, // e.g., "Dec 2025" or "01 Dec - 31 Dec"
    format: { type: String, default: "XLSX" },
    status: { type: String, default: "Ready" }, // Ready, Processing, Failed
    fileUrl: { type: String }, // Optional: If you upload to AWS S3
}, { timestamps: true });

const ReportHistory = mongoose.model('ReportHistory', reportHistorySchema);
export default ReportHistory;