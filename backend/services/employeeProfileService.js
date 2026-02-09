// services/employeeProfileService.js
import Employee from '../models/employeeModel.js';
import User from '../models/userModel.js';

export const getEmployeeProfileById = async (employeeId) => {
  // Populate branches to get their names
  const employee = await Employee.findById(employeeId)
    .populate('basic.branches', 'name') 
    .lean();

  if (!employee) {
    throw new Error('Employee not found');
  }

  const basic = employee.basic || {};
  const personal = employee.personal || {};
  
  // Get the latest/current employment record (assuming last in array is current)
  const currentEmp = (employee.employment && employee.employment.length > 0)
    ? employee.employment[employee.employment.length - 1]
    : {};

  // Fetch role from User model (existing logic)
  let role = 'employee';
  if (basic.phone) {
    const user = await User.findOne({ phoneNumber: basic.phone }).select('role').lean();
    if (user) role = user.role;
  }

  return {
    // --- Basic & Personal (Existing) ---
    fullName: basic.fullName || '',
    phoneNumber: basic.phone || '',
    jobTitle: basic.jobTitle || '',
    role,
    personalEmail: personal.personalEmail || '',
    dob: personal.dob ? new Date(personal.dob).toISOString().split('T')[0] : '',
    gender: basic.gender || '',
    maritalStatus: personal.maritalStatus || '',
    bloodGroup: personal.bloodGroup || '',
    guardianName: personal.guardianName || '',
    emergencyContactName: personal.emergencyContactName || '',
    emergencyContactRelationship: personal.emergencyContactRelationship || '',
    emergencyContactNumber: personal.emergencyContactNumber || '',
    emergencyContactAddress: personal.emergencyContactAddress || '',

    // --- Current Employment Data (NEW) ---
    branches: basic.branches ? basic.branches.map(b => b.name).join(', ') : '',
    departments: basic.departments ? basic.departments.join(', ') : '',
    officialEmail: basic.officialEmail || '',
    dateOfJoining: basic.dateOfJoining ? new Date(basic.dateOfJoining).toISOString().split('T')[0] : '',
    
    // From Employment Sub-Schema
    employeeType: currentEmp.employeeType || '',
    employeeCode: currentEmp.employeeId || '', // This is the manual ID (e.g. EMP001)
    pfNumber: currentEmp.pfNumber || '',
    esiNumber: currentEmp.esiNumber || '',
    customFieldValues: employee.customFieldValues || [],
  };
};