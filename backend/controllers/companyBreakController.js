// controllers/companyBreakController.js
import CompanyBreak from '../models/companyBreakModel.js';
import Company from '../models/companyModel.js';

// POST /api/company-breaks/:companyId
export const createCompanyBreak = async (req, res) => {
  try {
    const { companyId } = req.params;
    const { name, type, durationHours, durationMinutes } = req.body;

    if (!name || !type) {
      return res.status(400).json({ message: 'Name and type are required' });
    }

    const company = await Company.findById(companyId);
    if (!company) {
      return res.status(404).json({ message: 'Company not found' });
    }

    const breakDoc = await CompanyBreak.create({
      company: companyId,
      name,
      type,
      durationHours: Number(durationHours) || 0,
      durationMinutes: Number(durationMinutes) || 0,
    });

    company.breaks.push(breakDoc._id);
    await company.save();

    return res.status(201).json(breakDoc);
  } catch (err) {
    console.error('createCompanyBreak error', err);
    return res.status(500).json({ message: 'Server error' });
  }
};

// GET /api/company-breaks/company/:companyId
export const getCompanyBreaks = async (req, res) => {
  try {
    const { companyId } = req.params;
    const breaks = await CompanyBreak.find({ company: companyId }).sort({
      createdAt: 1,
    });
    return res.status(200).json(breaks);
  } catch (err) {
    console.error('getCompanyBreaks error', err);
    return res.status(500).json({ message: 'Server error' });
  }
};

// PUT /api/company-breaks/:breakId
export const updateCompanyBreak = async (req, res) => {
  try {
    const { breakId } = req.params;
    const update = req.body;

    const breakDoc = await CompanyBreak.findByIdAndUpdate(breakId, update, {
      new: true,
    });
    if (!breakDoc) {
      return res.status(404).json({ message: 'Break not found' });
    }

    return res.status(200).json(breakDoc);
  } catch (err) {
    console.error('updateCompanyBreak error', err);
    return res.status(500).json({ message: 'Server error' });
  }
};

// DELETE /api/company-breaks/:breakId
export const deleteCompanyBreak = async (req, res) => {
  try {
    const { breakId } = req.params;

    const breakDoc = await CompanyBreak.findById(breakId);
    if (!breakDoc) {
      return res.status(404).json({ message: 'Break not found' });
    }

    await breakDoc.deleteOne();

    await Company.updateOne(
      { _id: breakDoc.company },
      { $pull: { breaks: breakDoc._id } }
    );

    return res.status(200).json({ message: 'Break deleted' });
  } catch (err) {
    console.error('deleteCompanyBreak error', err);
    return res.status(500).json({ message: 'Server error' });
  }
};
