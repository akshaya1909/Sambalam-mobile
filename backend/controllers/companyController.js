import mongoose from "mongoose";
import { logAudit } from "../utils/auditLogger.js"; //
import asyncHandler from "../middleware/asyncHandler.js";
import Company from '../models/companyModel.js';
import User from '../models/userModel.js';
import JoinRequest from "../models/joinRequestModel.js";
import UserDetails from "../models/userDetailsModel.js";
import Employee from '../models/employeeModel.js';
import Attendance from '../models/attendanceModel.js';
import Plan from "../models/planModel.js";
import Addon from "../models/addonModel.js";
import Subscription from "../models/subscriptionModel.js";
import SubscriptionHistory from "../models/subscriptionHistoryModel.js";
import { LeaveAndBalance } from '../models/leaveBalanceModel.js'; // Adjust path if needed
import { BankDetails } from '../models/bankDetailsModel.js'
import {getCompanyStaffList, getCompanyBasicById, getCompanyDetailsById, updateCompanyById} from "../services/companyService.js";


function generateRandomCode(length = 6) {
  const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  let result = '';
  for (let i = 0; i < length; i++) {
    result += characters.charAt(Math.floor(Math.random() * characters.length));
  }
  return result;
}

const generateUniqueCode = async () => {
  let code;
  let exists = true;
  while (exists) {
    code = generateRandomCode();
    exists = await Company.findOne({ company_code: code });
  }
  return code;
};

const getPendingJoinRequests = asyncHandler(async (req, res) => {
  try {
    const requests = await JoinRequest.find({ status: { $in: ["pending", "approved"] } })
    .select("companyId userId name dob address email profilePic requestedAt status")
    .populate("companyId", "company_code") // only company_code from Company
    .populate("userId", "phoneNumber");
      // populate only phoneNumber from User

  res.status(200).json(requests);
  } catch (error) {
    console.error("Error fetching pending join requests:", error);
    res.status(500).json({ message: "Server error while fetching pending join requests" });
  }
});


const approveJoinRequest = async (req, res) => {
  try {
    const { id } = req.params;
    console.log("hello  : ", id);

    // 1. Approve the join request
    const updatedRequest = await JoinRequest.findByIdAndUpdate(
      id,
      { status: "approved" },
      { new: true }
    );

    if (!updatedRequest) {
      return res.status(404).json({ message: "Join request not found" });
    }

    const { userId, companyId, name, dob, email, profilePic, address } = updatedRequest;

    // 2. Update User: set status + ensure companies array includes companyId
    let updatedUser = null;
    if (userId && companyId) {
      updatedUser = await User.findByIdAndUpdate(
        userId,
        {
          $set: { status: "approved" },
          $addToSet: { companies: companyId } // ✅ push into array (no duplicates)
        },
        { new: true }
      );
    }

    // 3. Insert into UserDetails (only if not already created for this user)
    let userDetails = await UserDetails.findOne({ user: userId });

    if (!userDetails) {
      userDetails = new UserDetails({
        user: userId,
        basic_info: {
          name,
          dob,
          email,
          profilePic,
          // optional extra mapping
          gender: null,
          phone: null,
          jobTitle: null,
          department: null,
          employeeId: null,
          doj: new Date(), // can set join date as today or from request
          securePin: null
        }
      });
      await userDetails.save();
    }

    // 4. Response
    res.status(200).json({
      message: "Request approved successfully",
      request: updatedRequest,
      user: updatedUser,
      userDetails,
    });
  } catch (err) {
    res.status(500).json({
      message: "Error approving request",
      error: err.message,
    });
  }
};







// ✅ Decline request (delete record)
export const declineJoinRequest = async (req, res) => {
  try {
    const { id } = req.params;

    // Find the join request
    const joinRequest = await JoinRequest.findById(id);
    if (!joinRequest) {
      return res.status(404).json({ message: "Join request not found" });
    }

    // Delete the user associated with this request
    if (joinRequest.userId) {
      await User.findByIdAndDelete(joinRequest.userId);
    }

    // Delete the join request itself
    await JoinRequest.findByIdAndDelete(id);

    res.status(200).json({ message: "Request declined & user deleted" });
  } catch (err) {
    res.status(500).json({ message: "Error declining request", error: err.message });
  }
};



const requestJoinCompany = asyncHandler(async (req, res) => {
  const { teamCode, phoneNumber, name, dob, address, email, profilePic } = req.body;
console.log("Team codeee: ", teamCode)
  const company = await Company.findOne({ company_code: teamCode.toUpperCase() });
  if (!company) {
    return res.status(404).json({ message: "Invalid team code" });
  }

  const user = await User.findOne({ phoneNumber });
  if (!user) {
    return res.status(404).json({ message: "User not found" });
  }

  // Check if already in the company
  if (user.companies.includes(company._id)) {
    return res.status(400).json({ message: "User already in this company" });
  }

  // Check if a pending request already exists
  const existingRequest = await JoinRequest.findOne({
    userId: user._id,
    companyId: company._id,
    status: "pending"
  });
  if (existingRequest) {
    return res.status(400).json({ message: "Join request already pending" });
  }

  // Create join request
  const joinRequest = await JoinRequest.create({
    userId: user._id,
    companyId: company._id,
    name,
  dob,
  address,
  email,
  profilePic
  });

  res.status(201).json({
    message: "Join request submitted",
    joinRequest
  });
});


// @desc     join company by code
// @route    POST/api/company/join
// @access   Public
const joinCompanyByCode = asyncHandler(async(req, res) => {
  const { teamCode, phoneNumber } = req.body;

  try {
    const company = await Company.findOne({ company_code: teamCode.toUpperCase() });

    if (!company) {
      return res.status(404).json({ message: 'Invalid team code' });
    }

    const user = await User.findOne({phoneNumber});

    if (!user) {
  return res.status(404).json({ message: 'User not found' });
}

    // // Avoid duplicates
    // if (!user.companies.includes(company._id)) {
    //   user.companies.push(company._id);
    //   await user.save();
    // }

    // // Add user to company's users array too
    // if (!company.users.includes(user._id)) {
    //   company.users.push(user._id);
    //   await company.save();
    // }

    res.status(200).json({ message: 'Valid Team Code', company });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error while finding company code' });
  }
});



export const reviewJoinRequest = asyncHandler(async (req, res) => {
  const { requestId } = req.params;
  const { action, reviewerId } = req.body; // action = "approve" | "reject"

  const joinRequest = await JoinRequest.findById(requestId);
  if (!joinRequest) {
    return res.status(404).json({ message: "Join request not found" });
  }

  joinRequest.status = action === "approve" ? "approved" : "rejected";
  joinRequest.reviewedAt = new Date();
  joinRequest.reviewedBy = reviewerId;
  await joinRequest.save();

  // If approved → add user to company & company to user
  if (action === "approve") {
    await User.findByIdAndUpdate(joinRequest.userId, {
      $addToSet: { companies: joinRequest.companyId }
    });
    await Company.findByIdAndUpdate(joinRequest.companyId, {
      $addToSet: { users: joinRequest.userId }
    });
  }

  res.json({ message: `Request ${action}d successfully` });
});







export const getJoinStatus = asyncHandler(async (req, res) => {
  const { phoneNumber } = req.params;

  const user = await User.findOne({ phoneNumber });

  if (!user) return res.status(404).json({ message: "User not found" });

  const joinRequest = await JoinRequest.findOne({ userId: user._id }).populate("companyId", "name");

  if (!joinRequest) return res.status(404).json({ message: "No join request found" });

  res.status(200).json({
    status: joinRequest.status,
    companyName: joinRequest.companyId?.name,
    role: joinRequest.role || "Employee",
  });
});



// @route POST /company/create
export const createCompany = asyncHandler(async (req, res) => {
  const { name, logo, phoneNumber, staffCount,
    category,
    sendWhatsappAlerts, } = req.body;

  if (!name || !phoneNumber) {
    return res.status(400).json({ message: "Missing required fields" });
  }

  const user = await User.findOne({ phoneNumber });
  if (!user) {
    return res.status(404).json({ message: "User not found" });
  }

  const isAlreadyAdmin = user.memberships.some(m => m.roles.includes('admin'));
  const isPrimary = !isAlreadyAdmin;

  if (isAlreadyAdmin) {
    // Find the primary company to get the shared subscription
    const primaryCompany = await Company.findOne({ 
      created_by: user._id, 
      isPrimaryBillingAccount: true 
    }).populate('subscriptionId');

    if (primaryCompany && primaryCompany.subscriptionId) {
      const sub = await Subscription.findById(primaryCompany.subscriptionId).populate('planId');

      // A. Check Expiry
      if (sub.expiryDate && new Date(sub.expiryDate) < new Date()) {
        return res.status(403).json({ 
          message: "PLAN_EXPIRED", 
          details: `Your ${sub.planId.name} has expired. Please renew to create more companies.` 
        });
      }

      // B. Check Company Limit
      const currentCompanyCount = await Company.countDocuments({ 
        subscriptionId: sub._id 
      });

      if (currentCompanyCount >= sub.includedCompaniesCount) {
        return res.status(403).json({ 
          message: "LIMIT_REACHED", 
          limitType: "company",
          planName: sub.planId.name,
          limit: sub.includedCompaniesCount 
        });
      }
    }
  }

  const existingCompany = await Company.findOne({ name, created_by: user._id });
  if (existingCompany) {
    return res.status(409).json({ message: "Company already exists" });
  }

  const code = await generateUniqueCode();

  const company = await Company.create({
    name,
    logo: logo || null,
    created_by: user._id,
    company_code: code,
    users: [],
    admins: [user._id],
    staffCount,
    category,
    sendWhatsappAlerts:
      typeof sendWhatsappAlerts === "boolean" ? sendWhatsappAlerts : true,
  });

  if (isPrimary) {
    // Find the Free Plan (Price 0)
    const freePlan = await Plan.findOne({ price: 0 });
    
    if (freePlan) {
      // Find any Free Add-ons (Price 0)
      const freeAddons = await Addon.find({ price: 0 });
      
      const addonData = freeAddons.map(addon => ({
        addonId: addon._id,
        label: addon.label,
        quantity: 1,
        priceAtPurchase: 0,
        fullPriceAtRenewal: 0,
        purchaseDate: new Date()
      }));

      // Create the Subscription
      const subscription = await Subscription.create({
        subscriberCompanyId: company._id,
        planId: freePlan._id,
        includedCompaniesCount: freePlan.maxCompanies || 0, 
        includedEmployeesCount: freePlan.maxEmployees || 0,
        addons: addonData,
        status: 'active',
        billingCycle: freePlan.billingCycle,
        totalAmount: 0,
        startDate: new Date(),
        expiryDate: null, // Free plans usually don't expire
        hasCRM: false
      });

      await SubscriptionHistory.create({
        companyId: company._id,
        oldPlanId: null,
        newPlanId: freePlan._id,
        changeType: 'new',
        amountPaid: 0,
        itemizedBreakdown: { 
          planBasePrice: 0, 
          companyAddonPrice: 0, 
          employeeAddonPrice: 0, 
          crmAddonPrice: 0 
        }
      });

      // Update company with the new subscriptionId
      company.subscriptionId = subscription._id;
      await company.save();
    }
  } else {
    // If they are already an admin, they likely want to link this 
    // new company to their existing subscription pool.
    // Logic: Find the user's primary company and copy its subscriptionId
    const primaryCompany = await Company.findOne({ 
      created_by: user._id, 
      isPrimaryBillingAccount: true 
    });
    
    if (primaryCompany) {
      company.subscriptionId = primaryCompany.subscriptionId;
      await company.save();
    }
  }

  // Instead of pushing to user.companies, we push to user.memberships
  const newMembership = {
    companyId: company._id,
    roles: ['admin'], // Creator is always the admin
    assignedBranches: [], // Can be updated later when they create branches
    // secure_pin: "" // User will be prompted to set this in the next Flutter screen
  };

  // Check if membership already exists (safety check)
  const isAlreadyMember = user.memberships.some(m => 
    m.companyId.toString() === company._id.toString()
  );

  if (!isAlreadyMember) {
    user.memberships.push(newMembership);
    // user.role = 'admin'; // Optional: You can keep a global 'primary' role if you want
    await user.save();
  }

  await logAudit({
    req,
    action: 'create',
    resource: name, // The company name from req.body
    description: isPrimary 
      ? `Created primary company and initialized Free Plan` 
      : `Created additional company linked to existing subscription pool`,
    status: 'success'
  });

  res.status(201).json({ 
    message: 'Company created', 
    company_code: code, 
    companyId: company._id 
  });
});

const getUsersByCompanyId = async (req, res) => {
  const { companyId } = req.params;

  try {
    const objectId = new mongoose.Types.ObjectId(companyId);
    
    const users = await User.aggregate([
      { $match: { "memberships.companyId": objectId } },
      {
        $lookup: {
          from: "employees", // Ensure this matches your actual collection name
          localField: "phoneNumber",
          foreignField: "basic.phone",
          as: "details"
        }
      },
      { $unwind: { path: "$details", preserveNullAndEmptyArrays: true } },
      {
        $project: {
          _id: 1,
          phoneNumber: 1,
          fcmTokens: 1,
          membership: {
            $arrayElemAt: [
              {
                $filter: {
                  input: "$memberships",
                  as: "m",
                  cond: { $eq: ["$$m.companyId", objectId] }
                }
              },
              0
            ]
          },
          "fullName": { $ifNull: ["$details.basic.fullName", "Unknown User"] },
          "profilePic": "$details.basic.employeeProfile", // Matches your Employee schema field
          "empArray": "$details.employment",
        }
      },
      {
        $project: {
          _id: 1,
          fullName: 1,
          phoneNumber: 1,
          profilePic: 1,
          // Extract the first ID string from the employment array objects
          employeeId: { $ifNull: [{ $arrayElemAt: ["$empArray.employeeId", 0] }, ""] },
          // Extract the first role string
          role: { $ifNull: [{ $arrayElemAt: ["$membership.roles", 0] }, "employee"] },
          assignedBranches: { $ifNull: ["$membership.assignedBranches", []] },
          hasFcmToken: { 
            $gt: [{ $size: { $ifNull: ["$fcmTokens", []] } }, 0] 
          }
        }
      }
    ]);

    res.json(users);
  } catch (error) {
    console.error("Error fetching company users:", error);
    res.status(500).json({ message: "Server error" });
  }
};

export const getCompanyById = async (req, res) => {
  try {
    const { companyId } = req.params;
    
    const company = await Company.findById(companyId)
      .populate('created_by', 'name phoneNumber')
      .lean();
    
    if (!company) {
      return res.status(404).json({
        success: false,
        message: 'Company not found'
      });
    }
// console.log("Comapnyy: ",company)
    res.json({
      success: true,
      data: company
    });
  } catch (error) {
    console.error('Error fetching company:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

export const getCompanyStaffController = async (req, res) => {
  console.log("hellooooo")
  try {
    const { companyId, branchId } = req.query;

    if (!companyId) {
      return res.status(400).json({ message: "companyId is required" });
    }

    const staffList = await getCompanyStaffList(companyId, branchId);
    console.log(staffList);
    return res.status(200).json({
      staffList,
      totalStaff: staffList.length
    });
  } catch (err) {
    console.error("Get company staff error:", err);
    return res.status(400).json({ 
      message: err.message || "Unable to fetch staff list" 
    });
  }
};

export const getCompanyBasicByIdController = async (req, res) => {
  try {
    const { companyId } = req.params;
    if (!companyId) {
      return res.status(400).json({ message: 'companyId is required' });
    }

    const company = await getCompanyBasicById(companyId);
    return res.status(200).json(company);
  } catch (err) {
    console.error('getCompanyBasicById error:', err);
    return res
      .status(400)
      .json({ message: err.message || 'Unable to fetch company' });
  }
};


export const getCompanyDetails = async (req, res) => {
  try {
    const { companyId } = req.params;
    if (!companyId) {
      return res.status(400).json({ message: "companyId is required" });
    }

    const company = await getCompanyDetailsById(companyId);
    if (!company) {
      return res.status(404).json({ message: "Company not found" });
    }

    return res.json({ success: true, company });
  } catch (err) {
    console.error("getCompanyDetails error", err);
    return res.status(500).json({ message: "Server error" });
  }
};

export const updateCompanyDetails = async (req, res) => {
  try {
    const { companyId } = req.params;
    if (!companyId) {
      return res.status(400).json({ message: "companyId is required" });
    }

    // 1. Prepare base payload from text fields
    const payload = {
      name: req.body.name,
      category: req.body.category,
      address: req.body.address,
      gstNumber: req.body.gstNumber,
      udyamNumber: req.body.udyamNumber,
    };

    // 2. Check if a file was uploaded via Multer
    if (req.file) {
      // Construct the full URL. 
      // req.protocol = http, req.get('host') = 192.168.1.13:5000
      payload.logo = `/uploads/${req.file.filename}`;
    } 
    // If no file uploaded, we generally don't overwrite 'logo' with null 
    // unless you specifically handle removing logos.

    const updated = await updateCompanyById(companyId, payload);
    
    if (!updated) {
      return res.status(404).json({ message: "Company not found" });
    }

    return res.json({ success: true, company: updated });
  } catch (err) {
    console.error("updateCompanyDetails error", err);
    return res.status(500).json({ message: "Server error" });
  }
};


export const updateCompanySettings = async (req, res) => {
  try {
    const { id } = req.params;
    const { salarySettings, appNotifications } = req.body;

    const company = await Company.findById(id);
    if (!company) {
      return res.status(404).json({ message: "Company not found" });
    }

    // Update Salary Settings if provided
    if (salarySettings) {
      if (salarySettings.monthCalculation) company.salarySettings.monthCalculation = salarySettings.monthCalculation;
      if (salarySettings.attendanceCycle) company.salarySettings.attendanceCycle = salarySettings.attendanceCycle;
      if (salarySettings.roundOff !== undefined) company.salarySettings.roundOff = salarySettings.roundOff;
    }

    // Update Notifications if provided
    if (appNotifications !== undefined) {
      company.appNotifications = appNotifications;
    }

    await company.save();

    res.status(200).json({ 
      message: "Settings updated successfully", 
      company 
    });

  } catch (error) {
    console.error("updateCompanySettings error:", error);
    res.status(500).json({ message: "Failed to update settings" });
  }
};


export const getUserCompanies = async (req, res) => {
  try {
    const { phoneNumber } = req.params;

    // 1. Find the User ID based on the phone number
    const user = await User.findOne({ phoneNumber });
    
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // 2. Find Companies where this user is an Admin (or Member)
    // Adjust the query fields ('admins', 'members') to match your exact Company Schema
    const companies = await Company.find({
      $or: [
        { admins: user._id },
        { members: user._id }, // Include if you have a members array
        { owner: user._id }    // Include if you have an owner field
      ]
    })
    .select('name company_code address logo') // Select only fields needed for the list
    .sort({ createdAt: -1 });

    res.status(200).json(companies);
  } catch (error) {
    console.error('getUserCompanies error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};


// DELETE /api/company/:companyId/staff/all
export const deleteAllStaff = async (req, res) => {
  try {
    const { companyId } = req.params;

    // 1. Find all employees belonging to this company
    const employees = await Employee.find({ companyId }).select('_id');
    const employeeIds = employees.map(emp => emp._id);

    if (employeeIds.length === 0) {
      return res.status(200).json({ message: 'No staff members found to delete.' });
    }

    // 2. Delete related records in parallel for efficiency
    await Promise.all([
      // Delete Attendance Records
      Attendance.deleteMany({ employeeId: { $in: employeeIds } }),
      
      // Delete Leave Balances & Requests
      LeaveAndBalance.deleteMany({ employeeId: { $in: employeeIds } }),
      
      // Delete Bank Details
      BankDetails.deleteMany({ employeeId: { $in: employeeIds } }),
    ]);

    // 3. Finally, delete the employees
    const result = await Employee.deleteMany({ companyId });

    res.status(200).json({ 
      success: true, 
      message: `Successfully deleted ${result.deletedCount} staff members and all related data.` 
    });

  } catch (error) {
    console.error('deleteAllStaff error:', error);
    res.status(500).json({ message: 'Server error while deleting staff.' });
  }
};

export const updateCompanyUserRole = async (req, res) => {
  try {
    const { companyId, userId } = req.params;
    const { oldRole, newRole, branchIds } = req.body;

    // 1. Validation
    if (!newRole || !oldRole) {
      return res.status(400).json({ message: "Both oldRole and newRole are required" });
    }

    if (newRole.toLowerCase() === 'branch admin' && (!branchIds || branchIds.length === 0)) {
      return res.status(400).json({ message: "At least one branch must be assigned for Branch Admin" });
    }

    const company = await Company.findById(companyId);
    if (!company) {
      return res.status(404).json({ message: "Company not found" });
    }

    // 2. Find the user and membership
    const user = await User.findOne({ 
      _id: userId, 
      "memberships.companyId": companyId 
    });

    if (!user) {
      return res.status(404).json({ message: "User or membership not found" });
    }

    const membership = user.memberships.find(
      (m) => m.companyId.toString() === companyId
    );

    // 3. Logic Bypass for Branch Admin Updates
    const isChangingToSameRole = membership.roles.includes(newRole.toLowerCase());
    const isBranchAdminUpdate = newRole.toLowerCase() === 'branch admin';

    // Throw error ONLY if the role is the same AND it is NOT a branch admin (who needs branch updates)
    if (isChangingToSameRole && !isBranchAdminUpdate) {
      return res.status(400).json({ 
        success: false, 
        message: `User already has the role '${newRole}' in this company.` 
      });
    }

    const roleIndex = membership.roles.indexOf(oldRole.toLowerCase());
    if (roleIndex === -1) {
      return res.status(400).json({ message: `Old role '${oldRole}' not found in user memberships` });
    }

    // 4. Prepare Dynamic Update Object
    let updateData = {};

    // Only update the roles array if the string actually changed
    if (oldRole.toLowerCase() !== newRole.toLowerCase()) {
       updateData[`memberships.$.roles.${roleIndex}`] = newRole.toLowerCase();
    }

    // Update branches for Branch Admins
    if (newRole.toLowerCase() === 'branch admin') {
      updateData["memberships.$.assignedBranches"] = branchIds;
    }
    // If moving AWAY from Branch Admin, clear the branches
    else if (oldRole.toLowerCase() === 'branch admin') {
      updateData["memberships.$.assignedBranches"] = [];
    }

    // If nothing has changed, return early to save a database call
    if (Object.keys(updateData).length === 0) {
        return res.status(200).json({
            success: true,
            message: "No changes detected",
            roles: membership.roles
        });
    }

    // 5. Execute Update
    const updatedUser = await User.findOneAndUpdate(
      { _id: userId, "memberships.companyId": companyId },
      { $set: updateData },
      { new: true }
    );

    res.status(200).json({
      success: true,
      message: "User permissions updated successfully",
      roles: updatedUser.memberships.find(m => m.companyId.toString() === companyId).roles
    });

  } catch (error) {
    console.error("updateCompanyUserRole error:", error);
    res.status(500).json({ message: "Server error while updating role" });
  }
};

export const getRolesByCompanyId = async (req, res) => {
  try {
    const { companyId } = req.params;

    const company = await Company.findById(companyId)
      .populate('users', '_id phoneNumber role')
      .lean();
    if (!company) {
      return res.status(404).json({ message: 'Company not found' });
    }

    // 1) collect all user phoneNumbers
    const userPhones = company.users
      .map((u) => u.phoneNumber)
      .filter(Boolean);

    // 2) find employees whose basic.phone is in those numbers
    const employees = await Employee.find({
      'basic.phone': { $in: userPhones },
    })
      .select('_id basic.fullName basic.jobTitle basic.profilePic basic.phone employment.userId')
      .lean();

    // 3) index employees both by userId and by phone
    const empByUserId = {};
    const empByPhone = {};
    employees.forEach((emp) => {
      const userId = emp.employment?.[0]?.userId?.toString();
      const phone = emp.basic?.phone;
      if (userId) empByUserId[userId] = emp;
      if (phone) empByPhone[phone] = emp;
    });

    // 4) build roles only for users having a matching Employee (by phoneNumber)
    const roles = company.users
      .filter((u) => u.phoneNumber && empByPhone[u.phoneNumber]) // only users with Employee
      .map((u) => {
        const emp =
          empByUserId[u._id.toString()] || empByPhone[u.phoneNumber] || null;

        return {
          userId: u._id.toString(),
          fullName: emp?.basic?.fullName || 'User',
          jobTitle: emp?.basic?.jobTitle || '-',
          role: u.role || 'Employee',
          profilePic: emp?.basic?.profilePic || null,
        };
      });

    return res.status(200).json(roles);
  } catch (err) {
    console.error('getRolesByCompanyId error', err);
    return res.status(500).json({ message: 'Failed to load roles' });
  }
};

export const getCompanyPlan = asyncHandler(async (req, res) => {
  const company = await Company.findById(req.params.id).populate({
      path: 'subscriptionId',
      populate: { path: 'planId', select: 'name price' }
  });

  if (!company) {
      res.status(404);
      throw new Error("Company not found");
  }

  const sub = company.subscriptionId;
  let status = sub?.status || 'active';

  // AUTO-EXPIRE LOGIC: Check if current date has passed expiryDate
  if (sub && sub.expiryDate && sub.status !== 'expired') {
    const now = new Date();
    const expiry = new Date(sub.expiryDate);

    if (expiry < now) {
      status = 'expired';
      // Update the actual subscription record in background
      sub.status = 'expired';
      await sub.save();
    }
  }

  // Fallback if no subscription exists
  const planName = company.subscriptionId?.planId?.name || "null";
  const totalAmount = company.subscriptionId?.totalAmount || 0;
  const expiryDate = company.subscriptionId?.expiryDate || null;
  const hasCRM = company.subscriptionId?.hasCRM || false

  res.json({ planName, totalAmount, expiryDate, hasCRM, status: status });
});

export {joinCompanyByCode, getUsersByCompanyId, requestJoinCompany, getPendingJoinRequests, approveJoinRequest};

