import bcrypt from 'bcryptjs';
import User from '../models/userModel.js';
import Company from '../models/companyModel.js';
import asyncHandler from '../middleware/asyncHandler.js';


export const checkPhone = asyncHandler(async (req, res) => {
  const { phoneNumber } = req.body;

  try {
    const user = await User.findOne({ phoneNumber });

    if (!user) {
      return res.json({ exists: false }); // Not in DB
    }

    res.json({
      exists: true,
      isVerified: user.isVerified || false,
      hasSecurePin: !!user.secure_pin
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});



export const verifyOtp = asyncHandler(async (req, res) => {
  const { phoneNumber, otp } = req.body;

  if (!phoneNumber || !otp) {
    return res.status(400).json({ message: 'Phone number and OTP are required' });
  }

  try {
    const user = await User.findOne({ phoneNumber });

    const expiresAt = new Date(Date.now() + 2 * 60 * 1000); // 2 minutes from now

    if (user) {
      // Update existing user
      user.otp = { code: otp, expiresAt };
      user.isVerified = true;
      await user.save();
    } else {
      // Create new user
      const newUser = new User({
        phoneNumber,
        isVerified: true,
        otp: { code: otp, expiresAt }
      });
      await newUser.save();
    }

    return res.json({ message: 'OTP verified and user updated/created' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});


export const checkUserStatus = asyncHandler(async (req, res) => {
  const { phoneNumber } = req.body;

  try {
    const user = await User.findOne({ phoneNumber });

    if (!user) {
      return res.status(404).json({ exists: false });
    }

    res.json({ exists: true, isVerified: user.isVerified });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error" });
  }
});


export const updateSecurePin = asyncHandler(async (req, res) => {
  const { phoneNumber, secure_pin } = req.body;

  try {
    const user = await User.findOne({ phoneNumber });

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    if (!user.isVerified) {
      return res.status(403).json({ message: "User not verified" });
    }

    const otpValid = user.otp?.expiresAt && new Date() < new Date(user.otp.expiresAt);
    if (!otpValid) {
      return res.status(410).json({ message: "OTP expired", expired: true });
    }

    const hashedPin = bcrypt.hashSync(secure_pin, 10);
    user.secure_pin = hashedPin;
    await user.save();

    res.json({ message: "Secure PIN set successfully" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error" });
  }
});


export const getUserCompanies = asyncHandler(async(req, res) => {

    const phoneNumber = req.query.phone;



  if (!phoneNumber) {

    return res.status(400).json({ message: 'Phone number is required' });

  }



  try {

    const user = await User.findOne({ phoneNumber });



    if (!user) {

      return res.status(404).json({ message: 'User not found' });

    }



    // Populate companies based on the user's reference

    const companies = await Company.find({ _id: { $in: user.companies } });



    res.json(companies);

  } catch (error) {

    console.error(error);

    res.status(500).json({ message: 'Server error' });

  }

});



export const saveFcmToken = async (req, res) => {
  try {
    const { userId } = req.params;
    const { token, platform } = req.body;

    if (!token) {
      return res.status(400).json({ success: false, message: 'Token is required' });
    }

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    // avoid duplicates
    const exists = user.fcmTokens?.some(t => t.token === token);
    if (!exists) {
      user.fcmTokens = user.fcmTokens || [];
      user.fcmTokens.push({ token, platform });
      await user.save();
    }

    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

export const getUserById = async (req, res) => {
  try {
    const user = await User.findById(req.params.id);

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.json(user);
  } catch (error) {
    console.error('getUserById error:', error);
    // Handle invalid ObjectId format
    if (error.kind === 'ObjectId') {
        return res.status(404).json({ message: 'User not found' });
    }
    res.status(500).json({ message: 'Server error' });
  }
};


export const getUserIdByPhone = async (req, res) => {
  try {
    const { phone } = req.params;

    if (!phone) {
      return res.status(400).json({ message: "Phone number is required" });
    }

    const user = await User.findOne({ phoneNumber: phone }).select('_id');

    if (!user) {
      return res.status(404).json({ message: "User not found with this phone number" });
    }

    res.status(200).json({ userId: user._id });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error retrieving user ID" });
  }
};

export const getAssignedBranches = async (req, res) => {
  try {
    const { userId, companyId } = req.query;

    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ message: "User not found" });

    // Find the specific membership for this company
    const membership = user.memberships.find(
      (m) => m.companyId.toString() === companyId.toString()
    );

    if (!membership) {
      return res.status(403).json({ message: "No membership found for this company" });
    }

    // Return the array of ObjectIDs (assignedBranches)
    res.status(200).json({ 
      success: true, 
      assignedBranches: membership.assignedBranches || [] 
    });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
};