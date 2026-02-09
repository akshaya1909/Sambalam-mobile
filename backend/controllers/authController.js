import bcrypt from "bcryptjs";
import asyncHandler from "../middleware/asyncHandler.js";
import User from "../models/userModel.js";
import {checkDeviceStatus} from '../services/authService.js'


// @desc     Auth user and get token
// @route    POST /login
// @access   Public
export const login = asyncHandler(async(req, res) => {
  try{
  const { phoneNumber, pin } = req.body;

  // console.log("Received phoneNumber:", phoneNumber);
  // console.log("Received pin:", pin);

  const user = await User.findOne({ phoneNumber });

//   const allUsers = await User.find();
// console.log("Available users:", allUsers.map(u => u.phoneNumber));

  if (!user) {
    console.log("User not found");
    return res.status(401).json({ message: 'Phone number not found' });
  }
// console.log("Stored hash for user:", user.secure_pin);
  const isMatch = await bcrypt.compare(pin, user.secure_pin);
  // console.log("bcrypt comparison result:", isMatch);

  if (!isMatch) {
    return res.status(401).json({ message: 'Incorrect PIN' });
  }

  return res.status(200).json({ 
    message: 'Login successful',
    user: {
      id: user._id,
      phoneNumber: user.phoneNumber,
      role: user.role,
      companyId: user.companyId
    }
  });
}
catch(err){
  console.error('Login Error:', err);
    return res.status(500).json({ message: 'Server error' });
}
});

// POST /api/auth/verify-device
export const verifyDeviceController = async (req, res) => {
  try {
    const { userId, deviceId, deviceModel } = req.body;
    const result = await checkDeviceStatus(userId, deviceId, deviceModel);
    res.status(200).json(result);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};