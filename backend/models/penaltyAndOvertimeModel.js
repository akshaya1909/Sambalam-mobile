import mongoose from "mongoose";

// --------- Early Leaving Policy Schema ---------
const EarlyLeavingPolicySchema = new mongoose.Schema({
  allowedEarlyLeavingDays: { type: Number, required: true, min: 0 },
  onlyDeductIfEarlierThan: { type: Number, required: true, min: 0 },
  deductionMode: {
    type: String,
    enum: [
      "No, use a fixed deduction for early leaving",
      "Yes, deduct based on how early they left"
    ],
    required: true
  },
  deductionType: {
    type: String,
    enum: [
      "Half Day Salary",
      "Full Day Salary",
      "1.5x Daily Salary",
      "Custom Multiplier",
      "Fixed Daily Rate"
    ],
    required: true
  },
  amount: { type: Number, required: true, min: 0 },
}, { _id: false });

// --------- Late Coming Policy Schema ---------
const LateComingPolicySchema = new mongoose.Schema({
  allowedLateDays: { type: Number, required: true, min: 0 },
  onlyDeductIfLateByMoreThan: { type: Number, required: true, min: 0 },
  deductionMode: {
    type: String,
    enum: [
      "No, use a fixed deduction for late arrival",
      "Yes, deduct based on how late they arrived"
    ],
    required: true
  },
  deductionType: {
    type: String,
    enum: [
      "Half Day Salary",
      "Full Day Salary",
      "1.5x Daily Salary",
      "Custom Multiplier",
      "Fixed Daily Rate"
    ],
    required: true
  },
  amount: { type: Number, required: true, min: 0 },
}, { _id: false });

// --------- Overtime Policy: Subschemas ---------
// Working Days Subschema
const WorkingDaysSchema = new mongoose.Schema({
  overtimeConsideredAfter: { type: Number, required: true, min: 0 },
  extraHoursPay: {
    type: String,
    enum: [
      "0.5x Hourly Salary",
      "1.0x Hourly Salary",
      "1.5x Hourly Salary",
      "Custom Multiplier",
      "Fixed Hourly Rate"
    ],
    required: true
  },
  amount: { type: Number, required: true, min: 0 },
}, { _id: false });

// Week Offs and Holidays Subschema
const WeekoffsAndHolidaysSchema = new mongoose.Schema({
  publicHolidayPay: {
    type: String,
    enum: [
      "Half Day Salary",
      "Full Day Salary",
      "1.5x Daily Salary",
      "Custom Multiplier",
      "Fixed Daily Rate"
    ],
    required: true
  },
  amountPublicHolidayPay: { type: Number, required: true, min: 0 },
  weekOffPay: {
    type: String,
    enum: [
      "Half Day Salary",
      "Full Day Salary",
      "1.5x Daily Salary",
      "Custom Multiplier",
      "Fixed Daily Rate"
    ],
    required: true
  },
  amountWeekOffPay: { type: Number, required: true, min: 0 }
}, { _id: false });

// OvertimePolicy parent subschema
const OvertimePolicySchema = new mongoose.Schema({
  workingDays: { type: WorkingDaysSchema, required: true },
  weekoffsAndHolidays: { type: WeekoffsAndHolidaysSchema, required: true }
}, { _id: false });

// --------- Main PenaltyAndOvertime Schema ---------
const PenaltyAndOvertimeSchema = new mongoose.Schema({
  employeeId: { type: mongoose.Schema.Types.ObjectId, ref: "Employee", required: true, unique: true },
  earlyLeavingPolicy: { type: EarlyLeavingPolicySchema, required: true },
  lateComingPolicy: { type: LateComingPolicySchema, required: true },
  overtimePolicy: { type: OvertimePolicySchema, required: true }
}, { timestamps: true });

export const PenaltyAndOvertime = mongoose.model("PenaltyAndOvertime", PenaltyAndOvertimeSchema);
