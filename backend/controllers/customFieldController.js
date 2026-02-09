import CustomField from "../models/customFieldModel.js";
import Company from "../models/companyModel.js";

// GET /api/companies/:companyId/custom-fields
export const getCompanyCustomFields = async (req, res) => {
  try {
    const { companyId } = req.params;
    const fields = await CustomField.find({ companyId })
      .sort({ createdAt: 1 })
      .lean();

    return res.json({
      customFields: fields.map((f) => ({
        id: String(f._id),
        name: f.name,
        type: f.type,
        options: f.options || [],
        placeholder: f.placeholder,
        isRequired: f.isRequired,
      })),
    });
  } catch (err) {
    console.error("getCompanyCustomFields error", err);
    res.status(500).json({ message: "Server error" });
  }
};

// POST /api/companies/:companyId/custom-fields
export const createCustomField = async (req, res) => {
  try {
    const { companyId } = req.params;
    const { name, type, options, placeholder, isRequired } = req.body;

    if (!name || !name.trim()) {
      return res.status(400).json({ message: "Field name is required" });
    }

    // Validate Dropdown
    if (type === "dropdown" && (!options || options.length === 0)) {
      return res
        .status(400)
        .json({ message: "Dropdown fields must have at least one option" });
    }

    const existing = await CustomField.findOne({
      companyId,
      name: { $regex: new RegExp(`^${name.trim()}$`, "i") },
    });

    if (existing) {
      return res.status(400).json({ message: "Field name already exists" });
    }

    const field = await CustomField.create({
      companyId,
      name: name.trim(),
      type: type || "text",
      options: type === "dropdown" ? options : [],
      placeholder: placeholder || "",
      isRequired: isRequired || false,
    });

    await Company.findByIdAndUpdate(companyId, {
      $push: { customFields: field._id },
    });

    return res.status(201).json({
      message: "Custom field created",
      customField: {
        id: String(field._id),
        name: field.name,
        type: field.type,
        options: field.options,
      },
    });
  } catch (err) {
    console.error("createCustomField error", err);
    res.status(500).json({ message: "Server error" });
  }
};

// PUT /api/custom-fields/:fieldId
export const updateCustomField = async (req, res) => {
  try {
    const { fieldId } = req.params;
    const { name, type, options } = req.body;

    const field = await CustomField.findById(fieldId);
    if (!field) {
      return res.status(404).json({ message: "Custom field not found" });
    }

    // Basic validation logic
    if (name) field.name = name.trim();
    if (type) field.type = type;
    if (options && type === "dropdown") field.options = options;

    await field.save();

    return res.json({ message: "Custom field updated", customField: field });
  } catch (err) {
    console.error("updateCustomField error", err);
    res.status(500).json({ message: "Server error" });
  }
};

// DELETE /api/custom-fields/:fieldId
export const deleteCustomField = async (req, res) => {
  try {
    const { fieldId } = req.params;
    const field = await CustomField.findById(fieldId);
    if (!field) return res.status(404).json({ message: "Field not found" });

    await Company.findByIdAndUpdate(field.companyId, {
      $pull: { customFields: field._id },
    });
    await CustomField.findByIdAndDelete(fieldId);

    return res.json({ message: "Custom field deleted" });
  } catch (err) {
    res.status(500).json({ message: "Server error" });
  }
};