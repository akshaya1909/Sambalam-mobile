import mongoose from "mongoose";
import Employee from "../models/employeeModel.js";
import Company from "../models/companyModel.js";
import AdminDetails from '../models/adminDetailsModel.js';
import User from '../models/userModel.js';

export const getCompanyStaffList = async (companyId, branchId) => {
  
  try {
    let query = { 
      companyId: new mongoose.Types.ObjectId(companyId) 
    };
    // 1. Get company and its users (phone numbers)
    const company = await Company.findById(companyId)
      .populate('users', '_id phoneNumber') // Get phoneNumber from users
      .lean();
    
    if (!company) {
      throw new Error("Company not found");
    }

    if (branchId && branchId !== 'null' && branchId !== '') {
      // Since basic.branches is an array, MongoDB will return any employee 
      // who has this branchId inside their branches array.
      query['basic.branches'] = new mongoose.Types.ObjectId(branchId);
    }

    // 2. Extract phone numbers from users
    const userPhoneNumbers = company.users
      ?.map(user => user.phoneNumber)
      .filter(phone => phone) || [];

    if (userPhoneNumbers.length === 0) {
      console.log('❌ No phone numbers found - returning empty');
      return [];
    }

    // 3. Find employees with matching phone numbers
    const employees = await Employee.find(query)
      .select('basic.fullName basic.phone employment.employeeId dateOfJoining _id employmentStatus')
      .lean();

    // 4. Format response
    const staffList = employees.map(emp => ({
      id: emp._id.toString(),
      name: emp.basic.fullName || 'Unknown Staff',
      phone: emp.basic.phone || 'N/A',
      employeeId: emp.employment?.[0]?.employeeId || emp._id.toString().substring(0, 8),
      dateOfJoining: emp.dateOfJoining ? emp.dateOfJoining.toISOString() : null,
      employmentStatus: emp.employmentStatus || 'active',
    }));
    
    return staffList;
    
  } catch (error) {
    console.error('❌ getCompanyStaffList error:', error);
    throw error;
  }
};


export const getAdminCompanies = async (adminId) => {
  try {
    // Get admin details
    const admin = await AdminDetails.findById(adminId).populate('userId');
    if (!admin) throw new Error('Admin not found');

    const userId = admin.userId._id;

    // Get user companies
    const user = await User.findById(userId).populate('companies', 'name');
    if (!user) throw new Error('User not found');

    const companies = user.companies.map(company => ({
      _id: company._id,
      name: company.name
    }));

    return {
      companies: [
        'All Branches', // Always include first
        ...companies.map(c => c.name)
      ],
      companiesWithIds: companies.map(c => ({ _id: c._id, name: c.name }))
    };
  } catch (error) {
    throw new Error(`Failed to fetch companies: ${error.message}`);
  }
};

export const getCompanyBasicById = async (companyId) => {
  const company = await Company.findById(companyId)
    .select('name company_code logo')
    .lean();

  if (!company) {
    throw new Error('Company not found');
  }

  return {
    id: company._id,
    name: company.name,
    company_code: company.company_code,
    logo: company.logo ?? null,
  };
};


export async function getCompanyDetailsById(companyId) {
  const company = await Company.findById(companyId).lean().exec();
  return company;
}

export async function updateCompanyById(companyId, payload) {
  const updateData = { ...payload };
  const updated = await Company.findByIdAndUpdate(
    companyId,
    {
      $set: {
        name: payload.name,
        category: payload.category,
        address: payload.address,
        gstNumber: payload.gstNumber,
        udyamNumber: payload.udyamNumber,
        logo: payload.logo, // if you handle upload separately this can be optional
      },
    },
    { new: true }
  )
    .lean()
    .exec();
  return updated;
}