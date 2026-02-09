import asyncHandler from "../middleware/asyncHandler.js";
import User from "../models/userModel.js";
import Company from "../models/companyModel.js";
import AdminDetails from "../models/adminDetailsModel.js";
import { getAdminCompanies } from "../services/companyService.js";

export const createAdminDetails = asyncHandler(async (req, res) => {
  const { phoneNumber, companyId, name, email } = req.body;

  if (!phoneNumber || !companyId || !name) {
    return res.status(400).json({ 
      message: "phoneNumber, companyId, and name are required" 
    });
  }

  const user = await User.findOne({ phoneNumber });
  if (!user) {
    return res.status(404).json({ message: "User not found" });
  }

  const company = await Company.findById(companyId);
  if (!company) {
    return res.status(404).json({ message: "Company not found" });
  }

  // Check if AdminDetails already exists for this user (phone number)
  let adminDetails = await AdminDetails.findOne({ userId: user._id });

  if (adminDetails) {
    // Scenario: Existing Admin. Just add the new companyId to their list.
    if (!adminDetails.companyIds.includes(companyId)) {
      adminDetails.companyIds.push(companyId);
      await adminDetails.save();
    }
  } else {
    // Scenario: New Admin. Create the first record.
    adminDetails = await AdminDetails.create({
      userId: user._id,
      companyIds: [companyId],
      name,
      email,
      phoneNumber,
    });
  }

  // Maintain the relationship in the Company model
  if (!company.admins.includes(user._id)) {
    company.admins.push(user._id);
    await company.save();
  }

  res.status(201).json({
    message: "Admin details updated/saved",
    adminDetailsId: adminDetails._id,
    alreadyExisted: !!(adminDetails.createdAt < adminDetails.updatedAt)
  });
});

export const getAdminCompaniesController = async (req, res) => {
  try {
    const { adminId } = req.params;
    
    if (!adminId) {
      return res.status(400).json({ 
        success: false, 
        message: 'adminId is required' 
      });
    }

    const companiesData = await getAdminCompanies(adminId);
    
    res.status(200).json({
      success: true,
      data: companiesData
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};


export const checkAdminStatusController = asyncHandler(async (req, res) => {
  const { phoneNumber } = req.params;

  // Search for the admin record by phone number
  const admin = await AdminDetails.findOne({ phoneNumber });

  res.status(200).json({
    exists: !!admin, // returns true if record found, false otherwise
  });
});