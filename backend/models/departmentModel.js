// models/departmentModel.js
import mongoose from 'mongoose';

const departmentSchema = new mongoose.Schema(
  {
    company: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Company',
      required: true,
    },
    // null means “applies to all branches”; otherwise link to one branch
    branch: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Branch',
      default: null,
    },
    name: {
      type: String,
      required: true,
      trim: true,
    },
    // optional description / notes
    description: {
      type: String,
      trim: true,
    },
    // store staff as user references; can be empty
    staff: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Employee',
      },
    ],
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  { timestamps: true }
);

const Department = mongoose.model('Department', departmentSchema);
export default Department;
