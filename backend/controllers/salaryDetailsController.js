import {SalaryDetails} from "../models/salaryDetailsModel.js"
import Employee from "../models/employeeModel.js";
import { calculatePayableDays } from "../services/salaryService.js";

// GET details
export const getSalaryDetails = async (req, res) => {
  try {
    const details = await SalaryDetails.findOne({ employeeId: req.params.employeeId });
    if (!details) {
      return res.status(404).json({ message: "Salary details not found" });
    }
    res.json(details);
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

// UPDATE details
export const updateSalaryDetails = async (req, res) => {
    try {
        const { effectiveMonthOfChange, salaryType, salaryStructure, CTCAmount, earnings, compliances, deductions } = req.body;

        // BASIC VALIDATION
        if (!salaryType || !salaryStructure || !effectiveMonthOfChange) {
            return res.status(400).json({ message: "All required fields must be filled" });
        }
        if ((salaryType === "Per Month" && salaryStructure === "Sambalam Provided") && (!CTCAmount || isNaN(CTCAmount))) {
            return res.status(400).json({ message: "Valid CTC Amount required" });
        }
        
        // FIND existing record
        let details = await SalaryDetails.findOne({ employeeId: req.params.employeeId });
        if (!details) {
            details = new SalaryDetails({ employeeId: req.params.employeeId });
        }

        // --- 1. Fields common to all types are updated outside the conditional block ---
        details.effectiveMonthOfChange = effectiveMonthOfChange;
        details.salaryType = salaryType;
        details.salaryStructure = salaryStructure;
        details.CTCAmount = CTCAmount;
        
        // FIX: Compliances should be updated regardless of salaryType
        details.compliances = compliances;
        
        // --- 2. Fields dependent on salaryType ---
        if (salaryType === "Per Month") {
            // Only set earnings and deductions for monthly salary structure
            details.earnings = earnings;
            details.deductions = deductions;
        } else {
            // Clear earnings and deductions for Per Day/Per Hour types
            details.earnings = [];
            details.deductions = [];
        }

        await details.save();
        res.json({ message: "Salary Details updated!", details });
    } catch (err) {
        // In a real Mongoose setup, you might want to check for validation errors specifically
        res.status(500).json({ message: "Server error", error: err.message });
    }
};

// GET ALL Salary Details for a Company
export const getCompanySalaryDetails = async (req, res) => {
    try {
        const { companyId } = req.params;
        
        // 1. Get all employee IDs for this company
        const employees = await Employee.find({ companyId }).select('_id');
        const empIds = employees.map(e => e._id);

        // 2. Fetch salary details for these employees
        const salaries = await SalaryDetails.find({ employeeId: { $in: empIds } });
        
        res.json(salaries);
    } catch (err) {
        res.status(500).json({ message: "Server error", error: err.message });
    }
};

export const getSalaryData = async (req, res) => {
  try {
    const { employeeId, companyId, year, month } = req.query;

    const data = await calculatePayableDays(
      employeeId, 
      companyId, 
      Number(year), 
      Number(month)
    );

    res.status(200).json({
      success: true,
      ...data
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};