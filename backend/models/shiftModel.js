// models/shiftModel.js
import mongoose from 'mongoose';

const shiftSchema = new mongoose.Schema(
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
    // store as "HH:MM AM/PM" like your UI,
    // or change to Date/Number if you prefer
    startTime: {
      type: String,
      required: true,
    },
    endTime: {
      type: String,
      required: true,
    },
    punchInRule: {
        type: String,
        enum: ['Anytime', 'Add Limit'],
        default: 'Anytime',
      },
      
      punchOutRule: {
        type: String,
        enum: ['Anytime', 'Add Limit'],
        default: 'Anytime',
      },
    // optional: numeric limits if "Add Limit" is used
    punchInHours: {
      type: Number,
      default: 0,
    },
    punchInMinutes: {
      type: Number,
      default: 0,
    },
    punchOutHours: {
      type: Number,
      default: 0,
    },
    punchOutMinutes: {
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

const Shift = mongoose.model('Shift', shiftSchema);
export default Shift;
