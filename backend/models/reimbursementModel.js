import mongoose from "mongoose";

const reimbursementSchema = new mongoose.Schema({
  employeeId: {
    type: String, // String ID as per your pattern or ObjectId if strict ref
    required: true,
    ref: 'Employee'
  },
  companyId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Company',
    required: true
  },
  amount: {
    type: Number,
    required: true
  },
  dateOfPayment: {
    type: Date,
    default: Date.now
  },
  notes: {
    type: String,
    trim: true
  },
  attachments: [
    {
      name: { type: String },
      url: { type: String },
      type: { type: String }
    }
  ],
  status: {
    type: String,
    enum: ['pending', 'approved', 'rejected'],
    default: 'pending'
  },
  requestedOn: {
    type: Date,
    default: Date.now
  },
  processedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  processedOn: {
    type: Date
  }
}, { timestamps: true });

const Reimbursement = mongoose.model("Reimbursement", reimbursementSchema);
export default Reimbursement;