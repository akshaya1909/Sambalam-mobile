import mongoose from "mongoose";

const companySchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true
  },
  company_code: {
    type: String,
    required: true,
    unique: true
  },
  logo: {
    type: String,
    },
    staffCount: {
      type: Number, // optional
    },
    category: {
      type: String, // optional
    },
    sendWhatsappAlerts: {
      type: Boolean,
      default: true,
    },
    address: { type: String },                        // NEW
    gstNumber: { type: String },                      // NEW
    udyamNumber: { type: String },
  users: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }],
  admins: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }],
  advertiseDetails: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "AdvertiseDetails",
  },
  newJoinRequests: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'NewJoinRequest'
  }],
  branches: [
    {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Branch',
    },
  ],
  departments: [
    {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Department',
    },
  ],
  shifts: [
    {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Shift',
    },
  ],
  breaks: [
    {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'CompanyBreak',
    },
  ],
  attendanceKiosks: [
    {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'AttendanceKiosk',
    },
  ],
  biometricDevices: [
    {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'BiometricDevice',
    },
  ],
  companyHolidays: [
    {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'CompanyHoliday',
    },
  ],
  leaveTypes: [
    {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'LeaveType',
    },
  ],
  incentiveTypes: [
    {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'IncentiveType',
    },
  ],
  customFields: [
    {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'CustomField',
    },
  ],
  workReportTemplates: [
    {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'WorkReportTemplate'
    }
  ],
  salarySettings: {
    monthCalculation: {
      type: String,
      enum: ["calendar", "30-day", "26-day"],
      default: "calendar"
    },
    attendanceCycle: {
      type: String,
      enum: ["1-end", "21-20", "26-25"],
      default: "1-end"
    },
    roundOff: {
      type: Boolean,
      default: false
    }
  },

  appNotifications: {
    type: Boolean,
    default: true
  },
  leaveRequests: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'LeaveAndBalance.leaveRequests'  // reference the subdoc _id
  }],
  created_by: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  subscriptionId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Subscription',
    default: null // Will be null for Free Plan users initially
  },
  isPrimaryBillingAccount: {
    type: Boolean,
    default: false // Set to true for the first company created by the admin
  },
  referredBy: {
    partnerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'PartnerDetails', // Links to your PartnerDetails model
      index: true
    },
    referralCode: {
      type: String,
      trim: true,
      index: true
    },
    referredAt: {
      type: Date,
      default: Date.now
    }
  },
}, {
  timestamps: true
});

const Company = mongoose.model('Company', companySchema);

export default Company;