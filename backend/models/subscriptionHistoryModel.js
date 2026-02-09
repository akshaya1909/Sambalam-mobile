import mongoose from "mongoose";

const subscriptionHistorySchema = new mongoose.Schema({
  companyId: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'Company', 
    required: true 
  },
  // The plan they were on BEFORE this change (null if they are a new user)
  oldPlanId: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'Plan', 
    default: null 
  },
  // The plan they are on AFTER this change
  newPlanId: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'Plan', 
    required: true 
  },
  // type of change to help with filtering
  changeType: { 
    type: String, 
    enum: ['new', 'upgrade', 'downgrade', 'addon'], 
    required: true 
  },
  amountPaid: { 
    type: Number, 
    required: true 
  },
  itemizedBreakdown: {
    planBasePrice: { type: Number, default: 0 },
    companyAddonPrice: { type: Number, default: 0 },
    employeeAddonPrice: { type: Number, default: 0 },
    crmAddonPrice: { type: Number, default: 0 }
  },
  transactionId: { 
    type: String 
  },
  date: { 
    type: Date, 
    default: Date.now 
  }
}, { timestamps: true });

const SubscriptionHistory = mongoose.model("SubscriptionHistory", subscriptionHistorySchema);
export default SubscriptionHistory;