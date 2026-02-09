import mongoose from "mongoose";
import AdminDetails from '../models/adminDetailsModel.js';
import User from '../models/userModel.js';
import Company from '../models/companyModel.js';
import Employee from '../models/employeeModel.js';
import newDeviceVerificationRequestModel from '../models/newDeviceVerificationRequestModel.js';

// Get admins for specific company
export const getCompanyAdmins = async (req, res) => {
  try {
    // console.log("hi")
    const { companyId } = req.params;
    // console.log(companyId)
    
    const admins = await AdminDetails.find({ companyIds: companyId })
      .populate('userId', 'name phoneNumber email role')
      .populate('companyIds', 'name company_code')
      .sort({ createdAt: -1 });
      // console.log("Admins: ",admins)

    res.json({
      success: true,
      admins: admins.map(admin => ({
        id: admin._id,
        name: admin.name,
        phone: admin.phoneNumber,
        email: admin.email || '',
        userId: admin.userId ? admin.userId._id : null
      }))
    });
  } catch (error) {
    console.error('Get admins error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

// Create new admin
export const createAdmin = async (req, res) => {
  try {
    const { companyId } = req.params;
    const { name, phoneNumber, email } = req.body;

    if (!name || !phoneNumber || !companyId) {
      return res.status(400).json({ success: false, message: 'Name, phone and companyId are required' });
    }

    const companyObjectId = new mongoose.Types.ObjectId(companyId);

    // Check if phone exists in User collection
    let user = await User.findOne({ phoneNumber });

    if (!user) {
      // SCENARIO: Completely new user
      user = new User({
        phoneNumber,
        isVerified: false,
        memberships: [{
          companyId: companyObjectId,
          roles: ['admin'], // Initialize with admin role
          secure_pin: null,
          joinedAt: new Date()
        }],
      });
      await user.save();
    } else {
      // SCENARIO: Existing user - Check memberships array
      const membershipIndex = user.memberships.findIndex(
        (m) => m.companyId.toString() === companyId
      );

      if (membershipIndex !== -1) {
        // User is already linked to this company
        const roles = user.memberships[membershipIndex].roles;
        
        if (roles.includes('admin')) {
          return res.status(400).json({ 
            success: false, 
            message: 'This user is already an admin in this company' 
          });
        } else {
          // Company exists but role is missing, push 'admin' role
          user.memberships[membershipIndex].roles.push('admin');
          await user.save();
        }
      } else {
        // User exists but is new to THIS company, push new membership
        user.memberships.push({
          companyId: companyObjectId,
          roles: ['admin'],
          secure_pin: null,
          joinedAt: new Date()
        });
        await user.save();
      }
    }

    // Check if AdminDetails already exists for this user and company
    let adminDetails = await AdminDetails.findOne({ userId: user._id });

    if (adminDetails) {
      // If profile exists, ensure this companyId is in the companyIds array
      if (!adminDetails.companyIds.some(id => id.equals(companyObjectId))) {
        adminDetails.companyIds.push(companyObjectId);
        await adminDetails.save();
      }
    } else {
      // Create new AdminDetails profile
      adminDetails = new AdminDetails({
        userId: user._id,
        companyIds: [companyObjectId],
        name,
        phoneNumber,
        email: email || ''
      });
      await adminDetails.save();
    }

    // Add user to company admins array
    await Company.findByIdAndUpdate(companyId, {
      $addToSet: { admins: user._id }
    });

    const populatedAdmin = await AdminDetails.findById(adminDetails._id)
      .populate('userId', 'phoneNumber role');

    res.json({
      success: true,
      message: 'Admin created successfully',
      admin: {
        id: adminDetails._id,
        name: adminDetails.name,
        phone: adminDetails.phoneNumber,
        email: adminDetails.email || '',
        userId: populatedAdmin.userId._id
      }
    });
  } catch (error) {
    console.error('Create admin error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

// Update admin
export const updateAdmin = async (req, res) => {
  try {
    const { adminId } = req.params;
    const { name, phoneNumber, email } = req.body;

    const admin = await AdminDetails.findById(adminId).populate('companyId');
    if (!admin) {
      return res.status(404).json({ success: false, message: 'Admin not found' });
    }

    // Update AdminDetails
    admin.name = name || admin.name;
    admin.phoneNumber = phoneNumber || admin.phoneNumber;
    admin.email = email || admin.email;
    await admin.save();

    res.json({
      success: true,
      message: 'Admin updated successfully',
      admin: {
        id: admin._id,
        name: admin.name,
        phone: admin.phoneNumber,
        email: admin.email || ''
      }
    });
  } catch (error) {
    console.error('Update admin error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

// Delete admin
export const deleteAdmin = async (req, res) => {
  try {
    const { adminId } = req.params;
    const companyIdFromRequest = req.query.companyId;

    if (!companyIdFromRequest) {
      return res.status(400).json({ 
        success: false, 
        message: 'CompanyId is required in query parameters to delete admin' 
      });
    }

    const adminDetail = await AdminDetails.findById(adminId);
    if (!adminDetail) {
      return res.status(404).json({ success: false, message: 'Admin details not found' });
    }
    const userId = adminDetail.userId;
    const targetCompanyId = companyIdFromRequest;

    const hasCompany = adminDetail.companyIds.some(id => id.toString() === targetCompanyId);
    
    if (!hasCompany) {
       return res.status(400).json({ success: false, message: 'This admin is not associated with the provided companyId' });
    }

    // Delete AdminDetails
    if (adminDetail.companyIds.length > 1) {
      // SCENARIO: Multiple companies exist, just pull this one
      await AdminDetails.findByIdAndUpdate(adminId, {
        $pull: { companyIds: targetCompanyId }
      });
    } else {
      // SCENARIO: Only this companyId exists, delete the whole object
      await AdminDetails.findByIdAndDelete(adminId);
    }

    // Remove user from company admins array
    await Company.findByIdAndUpdate(targetCompanyId, {
      $pull: { admins: userId }
    });

    const user = await User.findById(userId);
    if (user) {
      const membershipIndex = user.memberships.findIndex(
        (m) => m.companyId.toString() === targetCompanyId.toString()
      );

      if (membershipIndex !== -1) {
        let roles = user.memberships[membershipIndex].roles;

        // If 'admin' is the ONLY role, remove the entire membership entry
        if (roles.length === 1 && roles.includes('admin')) {
          user.memberships.splice(membershipIndex, 1);
        } 
        // If there are other roles (like 'employee'), just remove 'admin'
        else {
          user.memberships[membershipIndex].roles = roles.filter(role => role !== 'admin');
        }
        
        await user.save();
      }
    }

    res.json({ success: true, message: 'Admin privileges updated and processed successfully' });
  } catch (error) {
    console.error('Delete admin error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};


export const getCurrentAdminForCompany = async (req, res) => {
  try {
    const { companyId, phoneNumber } = req.query;

    if (!companyId || !phoneNumber) {
      return res
        .status(400)
        .json({ success: false, message: 'companyId and phoneNumber are required' });
    }

    // find AdminDetails by company + phone
    const admin = await AdminDetails.findOne({ companyId, phoneNumber })
      .populate('userId', 'role phoneNumber') // optional fields
      .populate('companyId', 'name company_code');

    if (!admin) {
      return res
        .status(404)
        .json({ success: false, message: 'Admin not found for this company' });
    }

    // optional: verify user has admin role on User model
    const user = admin.userId
      ? await User.findById(admin.userId._id).select('role')
      : null;

    res.json({
      success: true,
      admin: {
        id: admin._id,
        name: admin.name,
        phone: admin.phoneNumber,
        email: admin.email || '',
        userId: admin.userId?._id,
        role: user?.role || admin.userId?.role || null,
        companyId: admin.companyId?._id,
      },
    });
  } catch (error) {
    console.error('Get current admin error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

export const approveDeviceChange = async (req, res) => {
  const { employeeId } = req.params;
  const { action } = req.body; // 'approve' or 'reject'

  const employee = await Employee.findById(employeeId);
  const user = await User.findById(employee.user);

  if (action === 'approve') {
    // Extract the new device ID from the pending request remarks or a specific field
    const newId = employee.device.remarks.replace('Pending: ', '');
    
    user.deviceId = newId;
    user.isDeviceVerified = true;
    await user.save();

    employee.device.status = "verified";
    employee.device.verifiedOn = new Date();
  } else {
    employee.device.status = "failed";
    employee.device.remarks = "Admin rejected device change";
  }

  await employee.save();
  res.status(200).json({ message: `Device request ${action}ed` });
};

export const getPendingDeviceRequests = async (req, res) => {
  try {
    const requests = await newDeviceVerificationRequestModel.find({ 
      companyId: req.params.companyId, 
      status: 'pending' 
    }).sort({ requestedAt: -1 });
    res.status(200).json(requests);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

export const handleDeviceRequest = async (req, res) => {
  const { requestId } = req.params;
  const { action } = req.body; // 'approved' or 'rejected'

  try {
    const request = await newDeviceVerificationRequestModel.findById(requestId);
    if (!request) return res.status(404).json({ message: "Request not found" });

    if (action === 'approved') {
      // 1. Update the User Model with the NEW hardware ID
      await User.findByIdAndUpdate(request.userId, {
        deviceId: request.newDeviceId,
        deviceModel: request.newDeviceModel,
        isDeviceVerified: true
      });

      // 2. Update the Employee Model's internal device status
      await Employee.findByIdAndUpdate(request.employeeId, {
        'device.status': 'verified',
        'device.verifiedOn': new Date(),
        'device.remarks': `Approved new device: ${request.newDeviceModel}`
      });

      request.status = 'approved';
    } else {
      // Logic for rejection
      await Employee.findByIdAndUpdate(request.employeeId, {
        'device.status': 'failed',
        'device.remarks': 'Admin rejected device change request'
      });
      request.status = 'rejected';
    }

    await request.save();
    res.status(200).json({ message: `Device request ${action}` });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};