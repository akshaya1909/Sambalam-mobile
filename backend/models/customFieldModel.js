import mongoose from "mongoose";

const customFieldSchema = new mongoose.Schema(
  {
    companyId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Company",
      required: true,
    },
    name: {
      type: String,
      required: true,
      trim: true,
    },
    type: {
      type: String,
      enum: ["text", "number", "date", "dropdown", "checkbox", "textarea"],
      default: "text",
    },
    options: {
      type: [String], // Only required if type === 'dropdown'
      default: [],
    },
    placeholder: {
      type: String,
      default: "",
    },
    isRequired: {
      type: Boolean,
      default: false,
    },
  },
  { timestamps: true }
);

const CustomField = mongoose.model("CustomField", customFieldSchema);
export default CustomField;