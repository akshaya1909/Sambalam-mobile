import mongoose from "mongoose";

const adminDetailsSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    companyIds: [{
      type: mongoose.Schema.Types.ObjectId,
      ref: "Company",
    }],
    name: {
      type: String,
      required: true,
      trim: true,
    },
    email: {
      type: String,
      trim: true,
    },
    phoneNumber: {
      type: String,
      required: true,
    },
  },
  { timestamps: true }
);

const AdminDetails = mongoose.model("AdminDetails", adminDetailsSchema);
export default AdminDetails;
