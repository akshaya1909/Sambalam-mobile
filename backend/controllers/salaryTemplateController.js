import SalaryTemplate from "../models/salaryTemplateModel.js";
import Company from "../models/companyModel.js";

// GET All Templates for a Company
export const getSalaryTemplates = async (req, res) => {
  try {
    const { companyId } = req.params;
    const templates = await SalaryTemplate.find({ companyId });
    res.json(templates);
  } catch (error) {
    res.status(500).json({ message: "Server Error", error: error.message });
  }
};

// CREATE Template
export const createSalaryTemplate = async (req, res) => {
  try {
    const { companyId, name, description, components } = req.body;

    const template = await SalaryTemplate.create({
      companyId,
      name,
      description,
      components
    });

    // Optional: Push to Company Model if you want reference there
    await Company.findByIdAndUpdate(companyId, { 
       $push: { salaryTemplates: template._id } // Ensure you add this field to Company schema
    });

    res.status(201).json(template);
  } catch (error) {
    res.status(500).json({ message: "Failed to create template", error: error.message });
  }
};

// UPDATE Template
export const updateSalaryTemplate = async (req, res) => {
  try {
    const { id } = req.params;
    const updated = await SalaryTemplate.findByIdAndUpdate(id, req.body, { new: true });
    res.json(updated);
  } catch (error) {
    res.status(500).json({ message: "Failed to update template", error: error.message });
  }
};

// DELETE Template
export const deleteSalaryTemplate = async (req, res) => {
  try {
    const { id } = req.params;
    await SalaryTemplate.findByIdAndDelete(id);
    
    // Also remove reference from Company if needed
    // await Company.updateMany({}, { $pull: { salaryTemplates: id } });

    res.json({ message: "Template deleted" });
  } catch (error) {
    res.status(500).json({ message: "Failed to delete template", error: error.message });
  }
};