import mongoose from 'mongoose';

const incentiveTypeSchema = new mongoose.Schema(
  {
    company: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Company',
      required: true,
      index: true,
    },
    name: {
      type: String,
      required: true,
      trim: true,
    },
    description: {
      type: String,
      trim: true,
      default: "",
    },
    isTaxable: {
      type: Boolean,
      default: true,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  { timestamps: true }
);

// Ensure names are unique per company
incentiveTypeSchema.index({ company: 1, name: 1 }, { unique: true });

const IncentiveType = mongoose.model('IncentiveType', incentiveTypeSchema);
export default IncentiveType;