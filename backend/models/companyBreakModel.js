// models/companyBreakModel.js
import mongoose from 'mongoose';

const companyBreakSchema = new mongoose.Schema(
  {
    company: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Company',
      required: true,
    },
    name: {
      type: String,
      required: true,
      trim: true,
    },
    type: {
      type: String,
      enum: ['Paid', 'Unpaid'],
      required: true,
      default: 'Unpaid',
    },
    durationHours: {
      type: Number,
      default: 0,
    },
    durationMinutes: {
      type: Number,
      default: 0,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  { timestamps: true }
);

const CompanyBreak = mongoose.model('CompanyBreak', companyBreakSchema);
export default CompanyBreak;
