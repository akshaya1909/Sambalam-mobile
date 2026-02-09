// controllers/joinRequestController.js
import mongoose from "mongoose";
import asyncHandler from "../middleware/asyncHandler.js";
import NewJoinRequest from "../models/NewJoinRequestModel.js";
import User from "../models/userModel.js";
import Company from "../models/companyModel.js";

// controllers/newJoinRequestController.js
export const createJoinRequest = asyncHandler(async (req, res) => {
  console.log("hiii")
  const { companyId, name, phoneNumber, email } = req.body;
  const imagePath = req.file ? `/uploads/${req.file.filename}` : null;

  if (!companyId || !name || !phoneNumber) {
    return res.status(400).json({ message: 'companyId, name, phoneNumber are required' });
  }

  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    // 1. Check company exists
    const company = await Company.findById(companyId).session(session);
    if (!company) {
      await session.abortTransaction();
      session.endSession();
      return res.status(404).json({ message: 'Company not found' });
    }

    // 2. ✅ FIX: Create user if not exists (for new joiners)
    let user = await User.findOne({ phoneNumber }).session(session);
    if (!user) {
      user = new User({
        phoneNumber,  // Empty until approved
        isVerified: false,
        memberships: []
      });
      await user.save({ session });
    }

    // 3. Check existing request
    const existingRequest = await NewJoinRequest.findOne({
      userId: user._id,
      companyId,
      status: { $in: ['pending', 'approved', 'rejected'] }
    }).session(session);

    if (existingRequest) {
      await session.abortTransaction();
      session.endSession();
      return res.status(409).json({ message: 'Join request already exists' });
    }

    // 4. Create join request
    const joinRequest = new NewJoinRequest({
      userId: user._id,
      companyId,
      name,
      phoneNumber,
      email,
      image: imagePath
    });
    await joinRequest.save({ session });

    // 5. Add to company.newJoinRequests
    company.newJoinRequests.push(joinRequest._id);
    await company.save({ session });

    await session.commitTransaction();
    session.endSession();

    res.status(201).json({
      message: 'Join request created successfully',
      joinRequest: {
        id: joinRequest._id,
        status: joinRequest.status,
        requestedAt: joinRequest.requestedAt
      }
    });
  } catch (err) {
    await session.abortTransaction();
    session.endSession();
    console.error('Create join request error:', err);
    throw err;
  }
});

