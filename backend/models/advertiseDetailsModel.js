import mongoose from "mongoose";

const advertiseDetailsSchema = new mongoose.Schema(
  {
    adminId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "AdminDetails",
      required: true,
    },
    companyId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Company",
      required: true,
    },
    featuresInterestedIn: [
      {
        type: String,
      },
    ],
    heardFrom: {
      type: String,
    },
    salaryRange: {
      type: String,
    },
  },
  { timestamps: true }
);

const AdvertiseDetails = mongoose.model(
  "AdvertiseDetails",
  advertiseDetailsSchema
);
export default AdvertiseDetails;
