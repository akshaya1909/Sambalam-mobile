import mongoose from "mongoose";

// Subschema for policy details (allowed, carryForward)
const LeavePolicyDetailSchema = new mongoose.Schema({
  leaveTypeId: { type: mongoose.Schema.Types.ObjectId, ref: 'LeaveType', required: true },
  allowedLeaves: { type: Number, required: true, min: 0 },
  carryForwardLeaves: { type: Number, required: true, min: 0 },
}, { _id: false });

// Subschema for balance details (current balance, taken)
const LeaveBalanceDetailSchema = new mongoose.Schema({
  leaveTypeId: { type: mongoose.Schema.Types.ObjectId, ref: 'LeaveType', required: true },
  current: { type: Number, default: 0 }, // Total available (Opening + New - Taken)
  taken: { type: Number, default: 0 },   // Taken in this period
}, { _id: false });


const LeaveRequestSchema = new mongoose.Schema({
  leaveTypeId: { type: mongoose.Schema.Types.ObjectId, ref: 'LeaveType', required: true },
  fromDate: { type: Date, required: true },
  toDate: { type: Date, required: true },
  isHalfDay: { type: Boolean, default: false },
  reason: { type: String, required: true },
  documentUrl: { type: String, default: null },
  status: { 
    type: String, 
    enum: ["pending", "approved", "rejected"], 
    default: "pending" 
  },
  requestedAt: { type: Date, default: Date.now },
  decidedAt: { type: Date, default: null },
    decidedBy: { type: mongoose.Schema.Types.ObjectId, ref: "AdminDetails" },
}, { _id: true });

// Main Schema
const LeaveAndBalanceSchema = new mongoose.Schema({
  employeeId: { type: mongoose.Schema.Types.ObjectId, ref: "Employee", required: true, unique: true },
  
  // Policy Configuration
  policyType: { type: String, enum: ["Monthly", "Yearly"], required: true, default: "Monthly" },
  policies: [LeavePolicyDetailSchema], // Array of policy rules per leave type

  // Balance Data
  balances: [LeaveBalanceDetailSchema], // Array of balances per leave type
  leaveRequests: [LeaveRequestSchema],
  lastProcessed: { type: Date, default: Date.now } // For carry forward calculation
}, { timestamps: true });

export const LeaveAndBalance = mongoose.model("LeaveAndBalance", LeaveAndBalanceSchema);