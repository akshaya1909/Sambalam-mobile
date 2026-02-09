import mongoose from "mongoose";

const documentSchema = new mongoose.Schema({
  status: {
    type: String,
    enum: ["Not Started", "Pending", "Verified", "Rejected"],
    default: "Not Started"
  },
  docNumber: { type: String }, // To store Aadhaar/PAN number
  uploadedUrl: { type: String },
  remarks: { type: String }
}, { _id: false });

const bgVerificationSchema = new mongoose.Schema({
  employee: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Employee",
    required: true,
    unique: true
  },
  companyId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Company",
    required: true
  },
  
  // Document Categories
  aadhaar: documentSchema,
  pan: documentSchema,
  drivingLicense: documentSchema,
  voterId: documentSchema,
  uan: documentSchema,
  face: documentSchema,
  address: documentSchema,
  pastEmployment: documentSchema,

  // Overall Status
  overallStatus: {
    type: String,
    enum: ["Not Started", "In Progress", "Completed", "Failed"],
    default: "Not Started"
  }
}, { timestamps: true });

const BgVerification = mongoose.model("BgVerification", bgVerificationSchema);
export default BgVerification;