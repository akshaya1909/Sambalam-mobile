import mongoose from "mongoose";

const bankDetailsSchema = new mongoose.Schema({
  employeeId: { type: mongoose.Schema.Types.ObjectId, ref: 'Employee' },
  type: { type: String, enum: ['Bank Account', 'UPI'], required: true },
  // Bank Account fields
  accountHolderName: { type: String }, // required only if type is 'Bank Account'
  accountNumber: { type: String },     // required only if type is 'Bank Account'
  bankName: { type: String },          // required only if type is 'Bank Account'
  ifscCode: { type: String },          // required only if type is 'Bank Account'
  branch: { type: String }, // New Field
  accountType: { 
    type: String, 
    enum: ['Savings', 'Current', 'Salary', 'NRE/NRO', 'Overdraft'], 
    default: 'Savings' 
  },
  // UPI field
  upiId: { type: String },            // required only if type is 'UPI'
  linkedMobileNumber: { type: String },
  isAccnVerified: { type: Boolean, default: false },
  isUpiVerified: { type: Boolean, default: false },
}, { timestamps: true });

export const BankDetails = mongoose.model('BankDetails', bankDetailsSchema);
