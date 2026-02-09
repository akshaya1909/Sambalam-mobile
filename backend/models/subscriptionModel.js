// models/subscriptionModel.js
import mongoose from "mongoose";

const subscriptionSchema = new mongoose.Schema({
  // The 'Main' company that made the payment
  subscriberCompanyId: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'Company', 
    required: true 
  },
  planId: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'Plan', 
    required: true 
  },
  
  // SHARED RESOURCE LIMITS
  // Example: 1 base + 2 additional = 3
  includedCompaniesCount: { type: Number, default: 1 }, 
  // Example: 20 base + 10 additional = 30
  includedEmployeesCount: { type: Number, default: 20 }, 
  
  // Track specific addons for history and renewal calculation
  addons: [{
    addonId: { type: mongoose.Schema.Types.ObjectId, ref: 'Addon' },
    label: String,
    quantity: { type: Number, default: 1 },
    priceAtPurchase: { type: Number }, // The Pro-rated amount paid mid-cycle
    fullPriceAtRenewal: { type: Number }, // The actual Addon price (₹3000) for next year
    purchaseDate: { type: Date, default: Date.now } // Knowing WHEN they bought it is vital for history
  }],

  status: {
    type: String,
    enum: ['active', 'expired', 'trialing', 'past_due', 'canceled'],
    default: 'active'
  },
  
  billingCycle: { type: String, enum: ["monthly", "annual", "custom"] },
  totalAmount: { type: Number, required: true }, // Total paid (Plan + Addons)
  isAutoRenew: { type: Boolean, default: true },
  lastPaymentDate: { type: Date },
  startDate: { type: Date, default: Date.now },
  expiryDate: { type: Date, required: false },
  
  // For the CRM highlight logic you wanted
  hasCRM: { type: Boolean, default: false } 
}, { timestamps: true });

const Subscription = mongoose.model("Subscription", subscriptionSchema);
export default Subscription;