import mongoose from "mongoose";

const commissionHistorySchema = new mongoose.Schema({
  companyId: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'Company', 
    required: true 
  },
  subscriptionId: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'Subscription', 
    required: true 
  },
  transactionTotal: { type: Number, required: true }, // Total paid by client (Plan + Addons)
  planCommission: { type: Number, default: 0 },
  addonCommission: { type: Number, default: 0 },
  totalCommissionEarned: { type: Number, required: true }, // Sum of plan + addon commission
  status: { type: String, enum: ['pending', 'paid'], default: 'pending' },
  calculatedAt: { type: Date, default: Date.now }
});

const partnerDetailsSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    unique: true 
  },
  partnerCode: {
    type: String,
    required: true,
    unique: true,
    uppercase: true,
  },
  // --- Client Companies ---
  // This stores an array of Company IDs that this partner manages
  clientCompanies: [
    {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Company', // Ensure this matches your Company model name
    }
  ],
  // --- Login OTP Logic ---
  loginOtp: {
    code: { type: String, trim: true }
  },
  // --- Contact Information ---
  companyName: { type: String, required: false, trim: true },
  contactPerson: { type: String, required: true },
  email: { type: String, required: true, lowercase: true },
  mobileNumber: { type: String, required: true },


  // Add this to your partnerDetailsSchema
kycDocuments: [
  {
    type: { 
      type: String, 
      enum: ['pan_card', 'gst_certificate', 'agreement', 'address_proof'],
      required: true 
    },
    fileName: String,
    fileUrl: String,
    status: { 
      type: String, 
      enum: ['pending', 'verified', 'rejected'], 
      default: 'pending' 
    },
    uploadedAt: { type: Date, default: Date.now }
  }
],

  // --- Business Information ---
  businessInformation: {
    gstNumber: { type: String },
    businessType: { type: String, required: true },
    panNumber: { type: String, required: false } // Change to false or remove
  },
  // --- Address ---
  address: {
    street: { type: String, required: true },
    city: { type: String, required: true },
    state: { type: String, required: true },
    pincode: { type: String, required: true }
  },
  commissions: {
    plans: [{
      planId: { type: mongoose.Schema.Types.ObjectId, ref: 'Plan' },
      commissionType: { type: String, enum: ['percentage', 'amount'] },
      value: { type: Number }
    }],
    addons: [{
      addonId: { type: mongoose.Schema.Types.ObjectId, ref: 'Addon' },
      commissionType: { type: String, enum: ['percentage', 'amount'] },
      value: { type: Number }
    }]
  },
  commissionsHistory: [commissionHistorySchema],
  isActive: { type: Boolean, default: true }
}, {
  timestamps: true
});

const PartnerDetails = mongoose.model('PartnerDetails', partnerDetailsSchema);

export default PartnerDetails;