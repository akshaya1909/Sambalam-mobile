import mongoose from "mongoose";

const shiftSchema = new mongoose.Schema({
  name: { type: String, required: true },
  start: { type: String, required: true }, 
  end: { type: String, required: true },   
}, { _id: false });


const dayShiftSchema = new mongoose.Schema({
  day: { type: String, required: true },  // "Mon", "Tue", "2025-11-01", etc.
  isWeekoff: { type: Boolean, default: false },
  // shifts: [shiftSchema],                  
  selectedShift: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'Shift',
    default: null 
  },       
}, { _id: false });


const fixedWorkTimingSchema = new mongoose.Schema({
  type: { type: String, enum: ["Fixed"], required: true, default: "Fixed" },
  days: { type: [dayShiftSchema], required: true }
}, { _id: false });


const flexibleWorkTimingSchema = new mongoose.Schema({
  type: { type: String, enum: ["Flexible"], required: true, default: "Flexible" },
  month: { type: String, required: true },     // "2025-11"
  days: { type: [dayShiftSchema], required: true }
}, { _id: false });


const workTimingsSchema = new mongoose.Schema({
  scheduleType: { type: String, enum: ["Fixed", "Flexible"], required: true },
  fixed: fixedWorkTimingSchema,
  flexibles: [flexibleWorkTimingSchema],
}, { _id: false });

const attendanceModesSchema = new mongoose.Schema({
  enableSmartphoneAttendance: { type: Boolean, default: false },
  smartphone: {
    selfieAttendance: { type: Boolean, default: false },
    qrAttendance: { type: Boolean, default: false },
    gpsAttendance: { type: Boolean, default: false },
    markAttendanceFrom: { type: String, enum: ["Office", "Anywhere"], default: "Anywhere" },
    branchId: { type: mongoose.Schema.Types.ObjectId, ref: 'Branch' }, // ADD
  },
  biometric: {
    enabled: { type: Boolean, default: false },
    deviceId: { type: mongoose.Schema.Types.ObjectId, ref: 'BiometricDevice' }, // <--- ONLY AN ID, company-level
  },
  attendanceKiosk: {
    enabled: { type: Boolean, default: false },
    kioskId: { type: mongoose.Schema.Types.ObjectId, ref: 'AttendanceKiosk' },
  }
}, { _id: false });

const automationRuleDurationSchema = new mongoose.Schema({
  hours: { type: Number, default: 0 },
  minutes: { type: Number, default: 0 }
}, { _id: false });

const automationRulesSchema = new mongoose.Schema({
  autoPresentAtDayStart: { type: Boolean, default: false },
  presentOnPunchIn: { type: Boolean, default: false },
  autoHalfDayIfLateBy: automationRuleDurationSchema,
  mandatoryHalfDayHours: automationRuleDurationSchema,
  mandatoryFullDayHours: automationRuleDurationSchema
}, { _id: false });

const punchInSchema = new mongoose.Schema({
  time: { type: Date, required: true },
  status: { type: String, enum: ["Late", "On Time", "Early"], required: true },
  punchedInFrom: { type: String }, // e.g. "Web", "Mobile", "Biometric"
  punchInPhoto: { type: String }, // URL or filename of photo
  location: {
    lat: { type: Number, default: null },     // ✅ Stores even if null
    lng: { type: Number, default: null },
    address: { type: String, default: null },
  },
}, { _id: false });

const punchOutSchema = new mongoose.Schema({
  time: { type: Date, required: true },
  status: { type: String, enum: ["Early", "Normal", "Over Time"], required: true },
  punchedOutFrom: { type: String }, // e.g. "Web", "Mobile", "Biometric"
  punchOutPhoto: { type: String }, // URL or filename of photo
  location: {
    lat: { type: Number, default: null },     // ✅ Stores even if null
    lng: { type: Number, default: null },
    address: { type: String, default: null },
  },
}, { _id: false });

const dailyAttendanceSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User", // Reference to employee
    required: true,
  },

  companyId: { type: mongoose.Schema.Types.ObjectId, ref: "Company", required: true },

  year: {
    type: Number,
    required: true,
  },

  month: {
    type: Number, // 1 = Jan, 12 = Dec
    required: true,
  },

  // Array of attendance entries for the month
  records: [
    {
      date: {
        type: Date,
        required: true,
      },
      status: {
        type: String,
        enum: ["Present", "Double Present", "Absent", "Half Day", "Leave", "Paid Leave", "Sunday", "Week Off", "Holiday", "Half Day Leave", "Unpaid Leave",], // 4 possible types
        default: "Absent",
      },
      leaveType: { 
        type: mongoose.Schema.Types.ObjectId, 
        ref: 'LeaveType', 
        default: null 
      },
      punchIn: { type: punchInSchema, default: null },
    punchOut: { type: punchOutSchema, default: null },
      remarks: {
        type: String,
        default: "",
      },
    },
  ],

  createdAt: {
    type: Date,
    default: Date.now,
  },
});

const alarmSchema = new mongoose.Schema(
  {
    type: {
      type: String,
      enum: ["PunchIn", "PunchOut"],
      required: true,
    },
    hour: { type: Number, required: true },   // 0-23
    minute: { type: Number, required: true }, // 0-59
    enabled: { type: Boolean, default: true },
  },
  { _id: false }
);


const attendanceSchema = new mongoose.Schema({
  employeeId: { type: mongoose.Schema.Types.ObjectId, ref: 'Employee' },
  // companyId: { type: mongoose.Schema.Types.ObjectId, ref: 'Company' },
  workTimings: workTimingsSchema,
  attendanceModes: attendanceModesSchema,
  automationRules: automationRulesSchema,
  staffCanViewOwnAttendance: { type: Boolean, default: false },
  monthlyAttendance: [dailyAttendanceSchema],
  mobileAlarms: [alarmSchema],
  // currentDate: { type: Date, required: true, default: null },
  // isPunchedIn: { type: Boolean, default: false },
  // punchIn: { type: punchInSchema },
  // punchOut: { type: punchOutSchema },
  // dailyAttendance: dailyAttendanceSchema,
  date: Date,
  check_in_time: Date,
  check_out_time: Date,
  attendance_mode: String,
  biometric_used: Boolean,
  qr_scanned: Boolean,
  location_marked: Boolean,
}, { timestamps: true });

const Attendance = mongoose.model('Attendance', attendanceSchema);
export default Attendance;

// const DailyAttendance = mongoose.model('DailyAttendance', dailyAttendanceSchema);
// export { DailyAttendance };