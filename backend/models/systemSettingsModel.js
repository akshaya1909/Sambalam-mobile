import mongoose from "mongoose";

const systemSettingsSchema = new mongoose.Schema({
  // Branding & Identity
  companyName: { type: String, default: "Sambalam" },
  supportPhone: { type: String, default: "" },
  supportEmail: { type: String, default: "" },
  systemSenderEmail: { type: String, default: "" },
  platformBaseUrl: { type: String, default: "" },

  // Legal & Compliance
  gstin: { type: String, uppercase: true },
  privacyPolicyUrl: { type: String, default: "" },
  termsConditionsUrl: { type: String, default: "" },

  // System Controls
  isMaintenanceMode: { type: Boolean, default: false },
  allowPublicSignups: { type: Boolean, default: true },

  lastUpdatedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }
}, { 
  timestamps: true 
});

const SystemSettings = mongoose.model('SystemSettings', systemSettingsSchema);
export default SystemSettings;