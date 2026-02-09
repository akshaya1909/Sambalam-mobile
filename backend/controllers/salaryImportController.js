import SalaryImportConfig from "../models/salaryImportConfigModel.js";
import Employee from "../models/employeeModel.js";
import { SalaryDetails } from "../models/salaryDetailsModel.js"; // Assuming this export exists
import XLSX from "xlsx";

// Default Fields Config
const INITIAL_FIELDS = [
  { id: "employeeId", name: "Employee ID", enabled: true, required: true },
  { id: "basic", name: "Basic Salary", enabled: true, required: true },
  { id: "hra", name: "HRA", enabled: true, required: false },
  { id: "special", name: "Special Allowance", enabled: true, required: false },
  { id: "conveyance", name: "Conveyance Allowance", enabled: false, required: false },
  { id: "medical", name: "Medical Allowance", enabled: false, required: false },
  { id: "pf", name: "PF (Employee Share)", enabled: true, required: false },
  { id: "esi", name: "ESI (Employee Share)", enabled: true, required: false },
  { id: "pt", name: "Professional Tax", enabled: true, required: false },
  { id: "tds", name: "TDS", enabled: true, required: false },
  { id: "loan", name: "Loan Deduction", enabled: false, required: false },
];

// GET Settings
export const getImportSettings = async (req, res) => {
  try {
    const { companyId } = req.params;
    let config = await SalaryImportConfig.findOne({ companyId });

    if (!config) {
      // Create default if not exists
      config = await SalaryImportConfig.create({
        companyId,
        fields: INITIAL_FIELDS
      });
    }
    res.json(config);
  } catch (error) {
    res.status(500).json({ message: "Error fetching settings", error: error.message });
  }
};

// UPDATE Settings
export const updateImportSettings = async (req, res) => {
  try {
    const { companyId } = req.params;
    const { fields } = req.body;

    const config = await SalaryImportConfig.findOneAndUpdate(
      { companyId },
      { $set: { fields } },
      { new: true, upsert: true }
    );

    res.json(config);
  } catch (error) {
    res.status(500).json({ message: "Error updating settings", error: error.message });
  }
};

// DOWNLOAD Template
export const downloadTemplate = async (req, res) => {
  try {
    const { companyId } = req.params;
    const config = await SalaryImportConfig.findOne({ companyId });
    
    // Filter enabled fields for headers
    const fieldsToExport = config 
      ? config.fields.filter(f => f.enabled) 
      : INITIAL_FIELDS.filter(f => f.enabled);

    const headers = {};
    fieldsToExport.forEach(f => {
        headers[f.name] = ""; // Create Empty Column
    });

    // Create Sample Row
    const sampleData = [{ ...headers }];
    
    // Clear values in sample row for the user to fill
    Object.keys(sampleData[0]).forEach(k => sampleData[0][k] = "");

    const ws = XLSX.utils.json_to_sheet(sampleData);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, "Salary Import");

    const buffer = XLSX.write(wb, { type: "buffer", bookType: "xlsx" });

    res.setHeader("Content-Disposition", 'attachment; filename="Salary_Template.xlsx"');
    res.setHeader("Content-Type", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
    res.send(buffer);

  } catch (error) {
    res.status(500).json({ message: "Error generating template", error: error.message });
  }
};

// IMPORT Data
export const importSalaryData = async (req, res) => {
  try {
    const { companyId } = req.params;
    if (!req.file) return res.status(400).json({ message: "No file uploaded" });

    // 1. Read Excel
    const workbook = XLSX.readFile(req.file.path);
    const sheetName = workbook.SheetNames[0];
    const data = XLSX.utils.sheet_to_json(workbook.Sheets[sheetName]);

    if (!data.length) return res.status(400).json({ message: "File is empty" });

    // 2. Fetch Config to map names to IDs
    const config = await SalaryImportConfig.findOne({ companyId });
    const fieldMap = {}; // "Basic Salary": "basic"
    (config ? config.fields : INITIAL_FIELDS).forEach(f => {
        fieldMap[f.name] = f.id;
    });

    const results = { success: 0, failed: 0, errors: [] };

    // 3. Process Rows
    for (const row of data) {
      const empIdValue = row["Employee ID"]; // Must match Header Name
      
      if (!empIdValue) {
        results.failed++;
        continue;
      }

      // Find Employee
      const employee = await Employee.findOne({ 
        companyId, 
        "employment.employeeId": empIdValue 
      });

      if (!employee) {
        results.failed++;
        results.errors.push(`Employee ID ${empIdValue} not found`);
        continue;
      }

      // Find or Create Salary Doc
      let salaryDoc = await SalaryDetails.findOne({ employeeId: employee._id });
      if (!salaryDoc) {
        salaryDoc = new SalaryDetails({ 
            employeeId: employee._id, 
            companyId,
            earnings: [], 
            deductions: [] 
        });
      }

      // Helper to push/update array
      const updateComponent = (arr, headName, value, type) => {
         if (!value) return;
         const idx = arr.findIndex(x => x.head === headName);
         const amount = Number(value) || 0;
         if (idx > -1) arr[idx].amount = amount;
         else arr.push({ head: headName, amount, calculation: "Flat Rate" });
      };

      // Map Excel Columns to DB Fields
      Object.keys(row).forEach(colName => {
         const key = fieldMap[colName];
         const val = row[colName];

         if (key === "basic") updateComponent(salaryDoc.earnings, "Basic", val);
         else if (key === "hra") updateComponent(salaryDoc.earnings, "HRA", val);
         else if (key === "special") updateComponent(salaryDoc.earnings, "Special Allowance", val);
         else if (key === "conveyance") updateComponent(salaryDoc.earnings, "Conveyance Allowance", val);
         else if (key === "medical") updateComponent(salaryDoc.earnings, "Medical Allowance", val);
         
         else if (key === "pf") updateComponent(salaryDoc.deductions, "PF", val);
         else if (key === "esi") updateComponent(salaryDoc.deductions, "ESI", val);
         else if (key === "pt") updateComponent(salaryDoc.deductions, "Professional Tax", val);
         else if (key === "tds") updateComponent(salaryDoc.deductions, "TDS", val);
         else if (key === "loan") updateComponent(salaryDoc.deductions, "Loan Recovery", val);
      });

      // Recalculate CTC (Simple Sum)
      const totalEarnings = salaryDoc.earnings.reduce((a, b) => a + b.amount, 0);
      salaryDoc.CTCAmount = totalEarnings; 

      await salaryDoc.save();
      results.success++;
    }

    res.json({ message: "Import complete", results });

  } catch (error) {
    console.error("Import Error", error);
    res.status(500).json({ message: "Server error", error: error.message });
  }
};