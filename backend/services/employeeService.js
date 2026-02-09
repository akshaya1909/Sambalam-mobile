// services/employeeService.js
import Employee from "../models/employeeModel.js";

export const getEmployeeBasicDetails = async ({ employeeId, companyId }) => {
  const employee = await Employee.findOne({
    _id: employeeId,
    companyId,
  }).select("basic.fullName basic.initials basic.dateOfJoining employmentStatus");

  if (!employee) {
    throw new Error("Employee not found for this company");
  }

  const basic = employee.basic || {};
  return {
    employeeId: employee._id,
    fullName: basic.fullName || "",
    initials: basic.initials || "",
    dateOfJoining: basic.dateOfJoining || null,
    employmentStatus: employee.employmentStatus || "active",
  };
};


export const getEmployeeByPhoneService = async (phoneNumber, companyId) => {
  const employee = await Employee.findOne({
    'basic.phone': phoneNumber,
    companyId, // you added this field on Employee
  })
    .select('_id basic.fullName basic.phone')
    .lean();

  if (!employee) {
    throw new Error('Employee not found');
  }
  return {
    id: employee._id,
    fullName: employee.basic.fullName,
    phoneNumber: employee.basic.phone,
  };
};