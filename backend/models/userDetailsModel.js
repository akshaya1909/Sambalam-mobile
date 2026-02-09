import mongoose from "mongoose";

const userDetailsSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    basic_info: {
      name: String,
      phone: String,
      gender: String,
      dob: Date,
      doj: Date,
      jobTitle: String,
      department: String,
      employeeId: String,
      email: String,
      securePin: String,
      profilePic: String,
    },
  },
  { timestamps: true }
);

// userDetailsSchema.index({ user: 1, company: 1 }, { unique: true });

// ✅ Prevent OverwriteModelError (must be *after* index)
const UserDetails =
  mongoose.models.UserDetails ||
  mongoose.model("UserDetails", userDetailsSchema);

export default UserDetails;
