import mongoose from "mongoose";

const newDeviceVerificationRequestSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  employeeId: { type: mongoose.Schema.Types.ObjectId, ref: 'Employee', required: true },
  companyId: { type: mongoose.Schema.Types.ObjectId, ref: 'Company', required: true },
  name: { type: String, required: true },
  phoneNumber: { type: String, required: true },
  newDeviceId: { type: String, required: true },
  newDeviceModel: { type: String, required: true },
  status: { type: String, enum: ['pending', 'approved', 'rejected'], default: 'pending' },
  requestedAt: { type: Date, default: Date.now }
});

export default mongoose.model('newDeviceVerificationRequestModel', newDeviceVerificationRequestSchema);