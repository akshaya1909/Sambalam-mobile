import mongoose from "mongoose";

const anomalySchema = new mongoose.Schema({
  // 1. UNIQUE IDENTIFICATION (Added to match Support Ticket style)
  anomalyNumber: {
    type: String,
    required: true,
    unique: true,
    uppercase: true,
    // Format Example: ANM-2026-X8Y2
  },

  companyId: { type: mongoose.Schema.Types.ObjectId, ref: 'Company', required: true },
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  employeeName: String,
  companyName: String,
  
  type: { 
    type: String, 
    enum: ['GPS Spoofing', 'Buddy Punching', 'Device Mismatch', 'Unusual Hours', 'Rapid Punches', 'Failed Login', 'Device Tampering'],
    required: true 
  },
  description: String,
  severity: { type: String, enum: ['low', 'medium', 'high'], default: 'medium' },
  status: { type: String, enum: ['investigating', 'confirmed', 'false_positive', 'resolved'], default: 'investigating' },
  
  metadata: {
    ipAddress: String,
    providedLocation: { lat: Number, lng: Number },
    actualOfficeLocation: { lat: Number, lng: Number },
    deviceId: String
  }
}, { timestamps: true });

// PRE-SAVE HOOK: Generate a unique anomaly number if not provided
anomalySchema.pre('validate', function (next) {
  if (!this.anomalyNumber) {
    const year = new Date().getFullYear();
    // Generates a 4-character random alphanumeric string
    const random = Math.random().toString(36).substring(2, 6).toUpperCase();
    this.anomalyNumber = `ANM-${year}-${random}`;
  }
  next();
});

const Anomaly = mongoose.model("Anomaly", anomalySchema);
export default Anomaly;