// controllers/leaveTypeController.js
import mongoose from 'mongoose';
import LeaveType from '../models/leaveTypeModel.js';
import Company from '../models/companyModel.js';

// helper: ensure default leave types exist for a company
const ensureDefaultLeaveTypes = async (companyId) => {
  const company = await Company.findById(companyId);
  if (!company) return null;

  const existing = await LeaveType.find({ company: companyId }).lean();
  const hasCasual = existing.some((l) => l.code === 'CASUAL');
  const hasSick = existing.some((l) => l.code === 'SICK');

  const toCreate = [];
  if (!hasCasual) {
    toCreate.push({
      company: companyId,
      name: 'Casual Leave',
      code: 'CASUAL',
    });
  }
  if (!hasSick) {
    toCreate.push({
      company: companyId,
      name: 'Sick Leave',
      code: 'SICK',
    });
  }

  if (toCreate.length) {
    const created = await LeaveType.insertMany(toCreate);
    // store their ids on company
    created.forEach((doc) => {
      if (!company.leaveTypes.includes(doc._id)) {
        company.leaveTypes.push(doc._id);
      }
    });
    await company.save();
  }
};

// GET /api/companies/:companyId/leave-types
export const getCompanyLeaveTypes = async (req, res) => {
  try {
    const { companyId } = req.params;
    const company = await Company.findById(companyId);
    if (!company) {
      return res.status(404).json({ message: 'Company not found' });
    }

    await ensureDefaultLeaveTypes(companyId);

    const types = await LeaveType.find({
      company: companyId,
      isActive: true,
    })
      .sort({ createdAt: 1 })
      .lean();

    const result = types.map((t) => ({
      id: String(t._id),
      name: t.name,
      code: t.code, // CASUAL, SICK, CUSTOM
    }));

    return res.json({ leaveTypes: result });
  } catch (err) {
    console.error('getCompanyLeaveTypes error', err);
    return res.status(500).json({ message: 'Server error' });
  }
};

// POST /api/companies/:companyId/leave-types
export const createLeaveType = async (req, res) => {
  try {
    const { companyId } = req.params;
    const { name } = req.body;

    if (!name?.trim()) {
      return res.status(400).json({ message: 'Leave name is required' });
    }

    const company = await Company.findById(companyId);
    if (!company) {
      return res.status(404).json({ message: 'Company not found' });
    }

    const leaveType = await LeaveType.create({
      company: companyId,
      name: name.trim(),
      code: 'CUSTOM',
    });

    company.leaveTypes.push(leaveType._id);
    await company.save();

    return res.status(201).json({
      id: String(leaveType._id),
      name: leaveType.name,
      code: leaveType.code,
    });
  } catch (err) {
    console.error('createLeaveType error', err);
    if (err.code === 11000) {
      return res
        .status(400)
        .json({ message: 'Leave name already exists for this company' });
    }
    return res.status(500).json({ message: 'Server error' });
  }
};

// PUT /api/companies/leave-types/:leaveTypeId
export const updateLeaveType = async (req, res) => {
  try {
    const { leaveTypeId } = req.params;
    const { name } = req.body;

    const leaveType = await LeaveType.findById(leaveTypeId);
    if (!leaveType) {
      return res.status(404).json({ message: 'Leave type not found' });
    }

    if (!name?.trim()) {
      return res.status(400).json({ message: 'Leave name is required' });
    }

    leaveType.name = name.trim();
    const updated = await leaveType.save();

    return res.json({
      id: String(updated._id),
      name: updated.name,
      code: updated.code,
    });
  } catch (err) {
    console.error('updateLeaveType error', err);
    if (err.code === 11000) {
      return res
        .status(400)
        .json({ message: 'Leave name already exists for this company' });
    }
    return res.status(500).json({ message: 'Server error' });
  }
};

// DELETE /api/companies/leave-types/:leaveTypeId
export const deleteLeaveType = async (req, res) => {
  try {
    const { leaveTypeId } = req.params;

    const leaveType = await LeaveType.findById(leaveTypeId);
    if (!leaveType) {
      return res.status(404).json({ message: 'Leave type not found' });
    }

    // optional: if you want to prevent deleting CASUAL/SICK, uncomment:
    // if (leaveType.code === 'CASUAL' || leaveType.code === 'SICK') {
    //   return res.status(400).json({ message: 'Cannot delete default leave types' });
    // }

    await Company.updateOne(
      { _id: leaveType.company },
      { $pull: { leaveTypes: leaveType._id } }
    );

    await leaveType.deleteOne();

    return res.json({ message: 'Leave type deleted' });
  } catch (err) {
    console.error('deleteLeaveType error', err);
    return res.status(500).json({ message: 'Server error' });
  }
};
