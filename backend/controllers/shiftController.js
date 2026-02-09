// controllers/shiftController.js
import Shift from '../models/shiftModel.js';
import Company from '../models/companyModel.js';

// POST /api/shifts/:companyId
export const createShift = async (req, res) => {
  try {
    const { companyId } = req.params;
    const {
      name,
      startTime,
      endTime,
      punchInRule,
      punchOutRule,
      punchInHours,
      punchInMinutes,
      punchOutHours,
      punchOutMinutes,
    } = req.body;

    if (!name || !startTime || !endTime) {
      return res
        .status(400)
        .json({ message: 'name, startTime and endTime are required' });
    }

    const company = await Company.findById(companyId);
    if (!company) {
      return res.status(404).json({ message: 'Company not found' });
    }

    const shift = await Shift.create({
      company: companyId,
      name,
      startTime,
      endTime,
      punchInRule,
      punchOutRule,
      punchInHours: punchInHours || 0,
      punchInMinutes: punchInMinutes || 0,
      punchOutHours: punchOutHours || 0,
      punchOutMinutes: punchOutMinutes || 0,
    });

    company.shifts.push(shift._id);
    await company.save();

    return res.status(201).json(shift);
  } catch (err) {
    console.error('createShift error', err);
    return res.status(500).json({ message: 'Server error' });
  }
};

// GET /api/shifts/company/:companyId
export const getCompanyShifts = async (req, res) => {
  try {
    const { companyId } = req.params;
    const shifts = await Shift.find({ company: companyId }).sort({
      createdAt: 1,
    });
    return res.status(200).json(shifts);
  } catch (err) {
    console.error('getCompanyShifts error', err);
    return res.status(500).json({ message: 'Server error' });
  }
};

// PUT /api/shifts/:shiftId
export const updateShift = async (req, res) => {
  try {
    const { shiftId } = req.params;
    const update = req.body;

    const shift = await Shift.findByIdAndUpdate(shiftId, update, {
      new: true,
    });
    if (!shift) {
      return res.status(404).json({ message: 'Shift not found' });
    }

    return res.status(200).json(shift);
  } catch (err) {
    console.error('updateShift error', err);
    return res.status(500).json({ message: 'Server error' });
  }
};

// DELETE /api/shifts/:shiftId
export const deleteShift = async (req, res) => {
  try {
    const { shiftId } = req.params;

    const shift = await Shift.findById(shiftId);
    if (!shift) {
      return res.status(404).json({ message: 'Shift not found' });
    }

    await shift.deleteOne();

    // remove from company.shifts
    await Company.updateOne(
      { _id: shift.company },
      { $pull: { shifts: shift._id } }
    );

    return res.status(200).json({ message: 'Shift deleted' });
  } catch (err) {
    console.error('deleteShift error', err);
    return res.status(500).json({ message: 'Server error' });
  }
};
