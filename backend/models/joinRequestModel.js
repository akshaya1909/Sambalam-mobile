import mongoose from "mongoose";

const joinRequestSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: true
  },
  companyId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Company",
    required: true
  },
  requestedAt: {
    type: Date,
    default: Date.now
  },
  status: {
    type: String,
    enum: ["pending", "approved", "rejected"],
    default: "pending"
  },
  name: {
    type: String,
    required: true
  }, 
  dob: {
    type: Date,
    required: true
  },
  address: {
    type: String,
    required: true
  },
  email: {
    type: String
  },
  profilePic: {
    type: String
  },
  reviewedAt: {
    type: Date
  },
  reviewedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User" // The admin/manager who approved/rejected
  }
});

const JoinRequest = mongoose.model("JoinRequest", joinRequestSchema);
export default JoinRequest;
