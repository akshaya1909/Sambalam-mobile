import mongoose from "mongoose";
import bcrypt from 'bcryptjs';


const membershipSchema = new mongoose.Schema({
  companyId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Company',
    required: true
  },
  // Array allows multiple roles in the same company (e.g., Admin + Branch Admin)
  roles: [{
    type: String,
    enum: ['admin', 'manager', 'employee', 'branch admin', 'attendance manager', 'advanced attendance manager'],
    default: ['employee']
  }],
  assignedBranches: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Branch'
  }],
  // Scoped PIN: Unique to this company
  secure_pin: {
    type: String,
    required: false
  },
  joinedAt: {
    type: Date,
    default: Date.now
  }
});


const userSchema = new mongoose.Schema({
    phoneNumber: {
    type: String,
    required: true,
    unique: true,
    trim: true
  },
  memberships: [membershipSchema],
  isVerified: {
    type: Boolean,
    default: false
  },
  otp: {
    code: String,
    expiresAt: Date
  },
  deviceId: { 
    type: String, 
    default: null,
    trim: true 
  },
  isDeviceVerified: { 
    type: Boolean, 
    default: false 
  },
  deviceModel: String, // Optional: e.g., "Samsung Galaxy S21"
  lastLogin: Date,
  fcmTokens: [{
    token: String,
    platform: String, // 'android' | 'ios' | 'web'
    addedAt: { type: Date, default: Date.now }
  }],
}, {
  timestamps: true
})


/**
 * UPDATED METHOD: matchSecurePin
 * Now requires a companyId to know WHICH pin to check.
 */
userSchema.methods.matchSecurePin = async function (companyId, enteredSecurePin) {
  const membership = this.memberships.find(m => m.companyId.toString() === companyId.toString());
  
  if (!membership || !membership.secure_pin) return false;

  return await bcrypt.compare(enteredSecurePin, membership.secure_pin);
};

/**
 * UPDATED MIDDLEWARE: pre-save
 * We must loop through the memberships array to hash any modified pins.
 */
userSchema.pre('save', async function (next) {
  const user = this;

  // Check if any membership secure_pin was modified
  for (let membership of user.memberships) {
    // If pin exists and looks like plain text (not yet hashed)
    if (membership.secure_pin && membership.secure_pin.length < 20) {
      const salt = await bcrypt.genSalt(10);
      membership.secure_pin = await bcrypt.hash(membership.secure_pin, salt);
    }
  }
  next();
});

const User = mongoose.model('User', userSchema);

export default User;