import mongoose from "mongoose";
import Employee from "../models/employeeModel.js";
import { BankDetails } from "../models/bankDetailsModel.js";

export const saveBankDetails = async (req, res) => {
  try {
    const { employeeId, type, accountHolderName, accountNumber, bankName, ifscCode, branch, accountType, upiId, linkedMobileNumber } = req.body;

    if (!employeeId || !type) {
      return res.status(400).json({ message: "Missing required fields" });
    }
    const employee = await Employee.findById(employeeId);
      if (!employee) return res.status(404).json({ message: "Employee not found" });

    if (type === 'Bank Account') {
      if (!accountHolderName || !accountNumber || !bankName || !ifscCode || !branch || !accountType) {
        return res.status(400).json({ message: "All bank account fields are mandatory" });
      }
    }
    if (type === 'UPI') {
      if (!upiId || !linkedMobileNumber) {
        return res.status(400).json({ message: "UPI ID and Linked Mobile Number are mandatory" });
      }
    }
    const existing = await BankDetails.findOne({ employeeId });
    if (existing) {
      // Update the record
      existing.type = type;
      if (type === 'Bank Account') {
        existing.accountHolderName = accountHolderName;
        existing.accountNumber = accountNumber;
        existing.bankName = bankName;
        existing.ifscCode = ifscCode;
        existing.branch = branch;
        existing.accountType = accountType;
        existing.isAccnVerified = false; // Reset verification on change
        // Preserve UPI data
      }
      // If new submission is UPI, update UPI field only, keep bank
      if (type === 'UPI') {
        existing.upiId = upiId;
        existing.linkedMobileNumber = linkedMobileNumber;
        existing.isUpiVerified = false; // Reset verification on change
        // Preserve Bank data
      }
      await existing.save();
      return res.status(200).json({ message: "Bank/UPI details updated", details: existing });
    }

    const details = new BankDetails({
      employeeId,
      type,
      // Bank Fields
      accountHolderName: type === 'Bank Account' ? accountHolderName : undefined,
      accountNumber: type === 'Bank Account' ? accountNumber : undefined,
      bankName: type === 'Bank Account' ? bankName : undefined,
      ifscCode: type === 'Bank Account' ? ifscCode : undefined,
      branch: type === 'Bank Account' ? branch : undefined,
      accountType: type === 'Bank Account' ? accountType : undefined,
      // UPI Fields
      upiId: type === 'UPI' ? upiId : undefined,
      linkedMobileNumber: type === 'UPI' ? linkedMobileNumber : undefined,
      
      isAccnVerified: false,
      isUpiVerified: false
    });

    await details.save();
    res.status(201).json({ message: "Bank/UPI details saved", details });

  } catch (err) {
    console.error("Error saving bank details", err);
    res.status(500).json({ message: "Server error while saving details" });
  }
};

// Get latest (or only) bank details for employee
export const getBankDetailsByEmployee = async (req, res) => {
    try {
      const { employeeId } = req.params;

      const employee = await Employee.findById(employeeId);
      if (!employee) return res.status(404).json({ message: "Employee not found" });

      // Adjust to fetch latest if multiple exist, or use .findOne if only one per user is allowed
      const details = await BankDetails.findOne({ employeeId }).sort({ createdAt: -1 });
      if (!details) return res.json({ type: null, details: null }); // No record yet
      res.status(200).json(details);
    } catch (err) {
      res.status(500).json({ message: "Error fetching bank details" });
    }
  };
  

  export const verifyBankAccount = async (req, res) => {
    try {
      const { employeeId } = req.params;
      const employee = await Employee.findById(employeeId);
      if (!employee) return res.status(404).json({ message: "Employee not found" });
      const details = await BankDetails.findOne({ employeeId });
      if (!details) return res.status(404).json({ message: "Bank details not found" });
      details.isAccnVerified = true;
      await details.save();
      res.status(200).json({ message: "Bank Account verified", details });
    } catch (err) {
      res.status(500).json({ message: "Error verifying bank account" });
    }
  };
  
  export const verifyUpi = async (req, res) => {
    try {
      const { employeeId } = req.params;
      const employee = await Employee.findById(employeeId);
      if (!employee) return res.status(404).json({ message: "Employee not found" });
      const details = await BankDetails.findOne({ employeeId });
      if (!details) return res.status(404).json({ message: "Bank details not found" });
      details.isUpiVerified = true;
      await details.save();
      res.status(200).json({ message: "UPI verified", details });
    } catch (err) {
      res.status(500).json({ message: "Error verifying UPI" });
    }
  };

  export const getCompanyBankDetails = async (req, res) => {
    try {
      const { companyId } = req.params;
      const { branchId, departmentIds } = req.query;

      const empFilter = { companyId };
    if (branchId && branchId !== 'null') {
      empFilter["basic.branches"] = { $in: [branchId] };
    }

    if (departmentIds) {
  const depts = departmentIds.split(',');
  empFilter["basic.departments"] = { $in: depts };
}
  
      // Fetch all employee IDs in the company
      const employees = await Employee.find(empFilter)
        .select("_id basic.fullName basic.phone basic.jobTitle basic.profilePic")
        .lean();
  
      const empIds = employees.map(emp => emp._id);
  
      // Fetch bank details for these employees
      const bankDetailsList = await BankDetails.find({ employeeId: { $in: empIds } })
        .select("employeeId accountHolderName accountNumber bankName ifscCode isAccnVerified")
        .lean();
  
      // Map employeeId to bank details for quick access
      const empIdToBankDetails = {};
      bankDetailsList.forEach(bd => {
        if (bd.employeeId) {
          empIdToBankDetails[bd.employeeId.toString()] = bd;
        }
      });
  
      // Merge employees with their bank details
      const data = employees.map(emp => {
        const bank = empIdToBankDetails[emp._id.toString()] || {};
        return {
          _id: emp._id,
          fullName: emp.basic.fullName,
          phone: emp.basic.phone,
          jobTitle: emp.basic.jobTitle,
          profilePic: emp.basic.profilePic,
          accountHolderName: bank.accountHolderName || null,
          accountNumber: bank.accountNumber || null,
          bankName: bank.bankName || null,
          ifscCode: bank.ifscCode || null,
          isAccnVerified: bank.isAccnVerified || false
        };
      });
  
      res.status(200).json(data);
  
    } catch (error) {
      console.error("Error fetching company bank details", error);
      res.status(500).json({ message: "Failed to get bank details" });
    }
  };