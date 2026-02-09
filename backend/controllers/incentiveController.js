// controllers/incentiveController.js
import IncentiveType from '../models/incentiveTypeModel.js';
import Company from '../models/companyModel.js';

// GET /api/incentives/company/:companyId
export const getCompanyIncentiveTypes = async (req, res) => {
  try {
    const { companyId } = req.params;
    if (!companyId) {
      return res.status(400).json({ message: 'companyId is required' });
    }

    const types = await IncentiveType.find({ company: companyId })
      .sort({ createdAt: 1 })
      .lean();

    res.json(types);
  } catch (err) {
    console.error('getCompanyIncentiveTypes error', err);
    res.status(500).json({ message: 'Failed to load incentive types' });
  }
};

// POST /api/incentives/company/:companyId
export const createIncentiveType = async (req, res) => {
  try {
    const { companyId } = req.params;
    const { name, description, isTaxable, isActive } = req.body;

    if (!companyId || !name?.trim()) {
      return res.status(400).json({ message: 'companyId and name are required' });
    }

    const company = await Company.findById(companyId);
    if (!company) return res.status(404).json({ message: 'Company not found' });

    const trimmedName = name.trim();

    const incentive = await IncentiveType.create({
      company: companyId,
      name: trimmedName,
      description: description || "",
      isTaxable: isTaxable !== undefined ? isTaxable : true,
      isActive: isActive !== undefined ? isActive : true,
    });

    // Optional: Keep reference in company model if your architecture requires it
    if (!company.incentiveTypes) company.incentiveTypes = [];
    company.incentiveTypes.push(incentive._id);
    await company.save();

    res.status(201).json(incentive);
  } catch (err) {
    if (err.code === 11000) {
      return res.status(400).json({ message: 'This incentive type already exists' });
    }
    console.error('createIncentiveType error', err);
    res.status(500).json({ message: 'Failed to create incentive type' });
  }
};

// PUT /api/incentives/:id
export const updateIncentiveType = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, description, isTaxable, isActive } = req.body;

    // Build update object dynamically to allow partial updates
    const updateData = {};
    if (name !== undefined) updateData.name = name.trim();
    if (description !== undefined) updateData.description = description;
    if (isTaxable !== undefined) updateData.isTaxable = isTaxable;
    if (isActive !== undefined) updateData.isActive = isActive;

    const incentive = await IncentiveType.findByIdAndUpdate(
      id,
      updateData,
      { new: true, runValidators: true }
    );

    if (!incentive)
      return res.status(404).json({ message: 'Incentive type not found' });

    res.json(incentive);
  } catch (err) {
    if (err.code === 11000) {
      return res.status(400).json({ message: 'This incentive type already exists' });
    }
    console.error('updateIncentiveType error', err);
    res.status(500).json({ message: 'Failed to update incentive type' });
  }
};

// DELETE /api/incentives/:id
export const deleteIncentiveType = async (req, res) => {
  try {
    const { id } = req.params;

    const incentive = await IncentiveType.findByIdAndDelete(id);
    if (!incentive)
      return res.status(404).json({ message: 'Incentive type not found' });

    await Company.updateOne(
      { _id: incentive.company },
      { $pull: { incentiveTypes: incentive._id } }
    );

    res.json({ message: 'Incentive type deleted' });
  } catch (err) {
    console.error('deleteIncentiveType error', err);
    res.status(500).json({ message: 'Failed to delete incentive type' });
  }
};
