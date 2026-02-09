import mongoose from "mongoose";

const auditLogSchema = new mongoose.Schema({
  user: { type: String, required: true }, // Full Name or "System/Unknown"
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'InternalUser' }, 
  action: { 
    type: String, 
    enum: ['login', 'update', 'export', 'delete', 'create'], 
    required: true 
  },
  resource: { type: String, required: true }, // e.g., "TechCorp Solutions (Company)"
  description: { type: String }, // e.g., "Updated subscription to Enterprise"
  ip: { type: String },
  status: { type: String, enum: ['success', 'failed'], default: 'success' },
}, { timestamps: true });

export default mongoose.model("AuditLog", auditLogSchema);