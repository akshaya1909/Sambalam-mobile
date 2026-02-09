import mongoose from "mongoose";

// BASIC DETAILS SCHEMA
const basicDetailsSchema = new mongoose.Schema({
  fullName: { type: String, required: true },
  initials: String,
  jobTitle: String,
  branches: [
    {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Branch",
      required: true,
    },
  ],

  // store Department document ids
  departments: [
    {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Department",
    },
  ],
  phone: { type: String, required: true },
  loginOtp: { type: String, required: true },
  gender: { type: String, enum: ["Male", "Female", "Other"], default: null },
  officialEmail: String,
  dateOfJoining: Date,
  currentAddress: String
}, { _id: false });

// PERSONAL DETAILS SCHEMA
const personalDetailsSchema = new mongoose.Schema({
  personalEmail: String,
  dob: Date,
  maritalStatus: { type: String, enum: ["Married", "Unmarried", "Divorced", "Widow"], default: null },
  bloodGroup: { type: String, enum: ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"], default: null },
  guardianName: String,
  emergencyContactName: String,
  emergencyContactNumber: String,
  emergencyContactRelationship: String,
  emergencyContactAddress: String,
  aadharNumber: String,
  panNumber: String,
  drivingLicenseNumber: String,
  voterIdNumber: String,
  uanNumber: String,
  permanentAddress: String,
  employeeProfile: String
}, { _id: false });

const pastEmploymentSchema = new mongoose.Schema({
  companyName: String,
  designation: String,
  dateOfJoining: Date,
  dateOfLeaving: Date,
  currency: {
    type: String,
    enum: ["INR", "IDR", "MYR", "MUR", "PHP", "ZAR", "AED", "SGD", "USD", "MXN", "THB"],
    default: null
  },
  salary: Number,
  companyGst: String
}, { _id: false });

// EMPLOYMENT DETAILS SCHEMA (for multiple jobs/history)
const employmentDetailsSchema = new mongoose.Schema({
  employeeType: { type: String, enum: ["Full Time", "Permanent", "Part Time", "Consultant", "Temporary", "Probation", "Intern", "Contract"], default: null },
  dateOfLeaving: Date,
  employeeId: String,
  esiNumber: String,
  pfNumber: String,
  probationPeriod: {
      type: Number, // store months, e.g. 0,1,3,6,9,12
      default: 0,
    },
    probationStatus: {
      type: String,
      enum: ["No Probation", "Ongoing", "Completed"],
      default: "No Probation",
    },
    probationEndDate: {
      type: Date,           // date when probation completes
      default: null,
    },
  pastEmployments: [pastEmploymentSchema]
  
}, { _id: false });

const customFieldValueSchema = new mongoose.Schema(
  {
    customField: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'CustomField',
      required: true,
    },
    value: {
      type: String, // or Mixed if you support multiple types
      required: true,
    },
  },
  { _id: false }
);

const documentSchema = new mongoose.Schema({
  name: { type: String, required: true },
  category: { type: String, required: true }, // 'Identity Proof', 'Education', etc.
  type: { type: String, required: true },     // 'pdf', 'image'
  size: { type: String, required: true },     // e.g. '1.2 MB'
  filePath: { type: String, required: true }, // Path to file on server
  uploadedOn: { type: Date, default: Date.now },
  verified: { type: Boolean, default: false }
}, { _id: true }); // Ensure each doc has a unique _id

// NEW: Schema to track verification status per category
const verificationStatusSchema = new mongoose.Schema({
  status: { 
    type: String, 
    enum: ["not-submitted", "pending", "in-progress", "verified", "failed"], 
    default: "not-submitted" 
  },
  verifiedOn: { type: Date, default: null },
  remarks: { type: String, default: null } // Reason for failure or notes
}, { _id: false });

// MASTER EMPLOYEE SCHEMA
const employeeSchema = new mongoose.Schema({
  basic: basicDetailsSchema,
  personal: personalDetailsSchema,
  employment: [employmentDetailsSchema], // as array for employment history
  companyId: {                           // add this field
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Company',
    required: true,                     
  },
  customFieldValues: [customFieldValueSchema],
  employmentStatus: {
    type: String,
    enum: ['active', 'inactive'],
    default: 'active',
    index: true,
  },
  documents: [documentSchema],

  verification: {
    aadhar: { type: verificationStatusSchema, default: () => ({}) },
    pan: { type: verificationStatusSchema, default: () => ({}) },
    drivingLicense: { type: verificationStatusSchema, default: () => ({}) },
    voterId: { type: verificationStatusSchema, default: () => ({}) },
    uan: { type: verificationStatusSchema, default: () => ({}) },
    face: { type: verificationStatusSchema, default: () => ({}) },
    address: { type: verificationStatusSchema, default: () => ({}) },
    pastEmployment: { type: verificationStatusSchema, default: () => ({}) },
  },
  device: { 
    status: { 
      type: String, 
      enum: ["not-submitted", "pending", "verified", "failed"], 
      default: "not-submitted" 
    },
    newDeviceId: { type: String, default: null }, // ID of the phone awaiting approval
  newDeviceModel: { type: String, default: null },
    verifiedOn: { type: Date, default: null },
    remarks: { type: String, default: null }
  },
  workReports: [
    {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'WorkReport'
    }
  ],
  // for extra fields or sections, add here in future
}, { timestamps: true });

const Employee = mongoose.model('Employee', employeeSchema);

export default Employee;
