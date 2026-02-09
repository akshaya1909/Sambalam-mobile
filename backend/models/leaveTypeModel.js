// models/leaveTypeModel.js
import mongoose from 'mongoose';

const leaveTypeSchema = new mongoose.Schema(
  {
    company: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Company',
      required: true,
      index: true,
    },
    // Display name shown in UI, e.g. "Casual Leave", "Sick Leave", "Birthday Leave"
    name: {
      type: String,
      required: true,
      trim: true,
    },
    // Marks system defaults
    code: {
      type: String,
      enum: ['CASUAL', 'SICK', 'CUSTOM'],
      default: 'CUSTOM',
    },
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  { timestamps: true }
);

// Ensure a company cannot have two leave types with same name
leaveTypeSchema.index({ company: 1, name: 1 }, { unique: true });

const LeaveType = mongoose.model('LeaveType', leaveTypeSchema);
export default LeaveType;
