import {WorkReportTemplate} from "../models/workReportTemplateModel.js";
import { WorkReport } from "../models/workReportModel.js";
import Company from "../models/companyModel.js";
import Employee from "../models/employeeModel.js";

/**
 * @desc    Create or Update a work report template
 * @route   POST /api/work-report/template/save
 */
export const saveWorkReportTemplate = async (req, res) => {
  const { 
    templateId, 
    companyId, 
    departmentIds, 
    isAllDepartments, 
    fields, 
    title 
  } = req.body;

  try {
    // 1. Validation: At least one department must be chosen if not Global
    if (!isAllDepartments && (!departmentIds || departmentIds.length === 0)) {
      return res.status(400).json({ message: "Please select at least one department." });
    }

    let template;

    if (templateId) {
      // --- UPDATE MODE ---
      template = await WorkReportTemplate.findByIdAndUpdate(
        templateId,
        {
          departmentIds: isAllDepartments ? [] : departmentIds,
          isForAllDepartments: isAllDepartments,
          fields,
          title,
          isActive: true
        },
        { new: true } // Returns the modified document
      );

      if (!template) {
        return res.status(404).json({ message: "Template not found" });
      }
    } else {
      // --- CREATE MODE ---
      // For Global templates, ensure we don't create multiple. Use findOneAndUpdate with upsert.
      if (isAllDepartments) {
        template = await WorkReportTemplate.findOneAndUpdate(
          { companyId, isForAllDepartments: true },
          { fields, title, departmentIds: [], isActive: true },
          { upsert: true, new: true }
        );
      } else {
        // For specific departments, create a new shared template
        template = await WorkReportTemplate.create({
          companyId,
          departmentIds,
          fields,
          title,
          isForAllDepartments: false,
          isActive: true
        });
      }
    }

    // 2. Link template reference to the Company model if not already linked
    await Company.findByIdAndUpdate(companyId, {
      $addToSet: { workReportTemplates: template._id }
    });

    res.status(200).json({ 
      message: templateId ? "Template updated successfully" : "Template created successfully", 
      template 
    });

  } catch (error) {
    // Handle MongoDB unique index errors (if a department is already in another template)
    if (error.code === 11000) {
      return res.status(400).json({ 
        message: "One of the selected departments is already assigned to another template." 
      });
    }
    res.status(500).json({ message: error.message });
  }
};


/**
 * @desc    Fetch all work report templates for a company
 * @route   GET /api/work-report/templates/:companyId
 */
export const getCompanyTemplates = async (req, res) => {
  try {
    const { companyId } = req.params;

    // We populate departmentIds to show names in the list screen
    const templates = await WorkReportTemplate.find({ companyId })
      .populate("departmentIds", "name")
      .sort({ createdAt: -1 });

    res.status(200).json(templates);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};


/**
 * @desc    Delete a template
 * @route   DELETE /api/work-report/template/:id
 */
export const deleteTemplate = async (req, res) => {
  try {
    const { id } = req.params;

    const template = await WorkReportTemplate.findById(id);
    if (!template) {
      return res.status(404).json({ message: "Template not found" });
    }

    const companyId = template.companyId;

    // Delete the template
    await WorkReportTemplate.findByIdAndDelete(id);

    // Remove the reference from the Company record
    await Company.findByIdAndUpdate(companyId, {
      $pull: { workReportTemplates: id }
    });

    res.status(200).json({ message: "Template deleted successfully" });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};


// --- EMPLOYEE OPERATIONS ---

export const getApplicableTemplates = async (req, res) => {
  try {
    const employee = await Employee.findById(req.params.employeeId);
    if (!employee) return res.status(404).json({ message: "Employee not found" });

    const templates = await WorkReportTemplate.find({
      companyId: employee.companyId,
      $or: [
        { isForAllDepartments: true },
        { departmentIds: { $in: employee.basic.departments } }
      ]
    });
    res.status(200).json(templates);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

export const getEmployeeMonthlyReports = async (req, res) => {
  const { employeeId, year, month } = req.query;
  try {
    const reportDoc = await WorkReport.findOne({ employeeId, year: Number(year), month: Number(month) });
    res.status(200).json(reportDoc ? reportDoc.reports : []);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

export const submitDailyReport = async (req, res) => {
  const { companyId, employeeId, date, templateId, data } = req.body;
  
  // Use UTC to prevent the 7th/8th date shift issue
  const d = new Date(date + 'T00:00:00.000Z');
  const year = d.getUTCFullYear();
  const month = d.getUTCMonth() + 1;

  try {
    // Find the monthly document
    let reportDoc = await WorkReport.findOne({ companyId, employeeId, year, month });

    if (reportDoc) {
      // Check if this specific date already exists in the reports array
      const dateEntryIndex = reportDoc.reports.findIndex(
        (r) => r.date.toISOString() === d.toISOString()
      );

      if (dateEntryIndex !== -1) {
        // Date exists: Push the new data into the 'entries' array of that date
        reportDoc.reports[dateEntryIndex].entries = entries;
      } else {
        // Date doesn't exist: Create a new report entry for this date
        reportDoc.reports.push({ templateId, date: d, entries: [{ data }] });
      }
      await reportDoc.save();
    } else {
      // Monthly doc doesn't exist: Create everything from scratch
      await WorkReport.create({
        companyId,
        employeeId,
        year,
        month,
        reports: [{ templateId, date: d, entries: [{ data }] }]
      });
    }

    res.status(200).json({ message: "Entry added successfully" });
  } catch (error) {
    console.error("Submit Error:", error);
    res.status(500).json({ message: error.message });
  }
};

export const getDayReport = async (req, res) => {
  const { employeeId, date } = req.query;
  const d = new Date(date + 'T00:00:00.000Z');
  const year = d.getUTCFullYear();
  const month = d.getUTCMonth() + 1;

  try {
    const reportDoc = await WorkReport.findOne({ employeeId, year, month });
    if (!reportDoc) return res.status(200).json(null);

    // Find the specific date entry
    const dayEntry = reportDoc.reports.find(
      (r) => r.date.toISOString() === d.toISOString()
    );

    res.status(200).json(dayEntry || null);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};