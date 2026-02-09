// controllers/attendanceKioskController.js
import mongoose from 'mongoose';
import AttendanceKiosk from '../models/attendanceKioskModel.js';
import Company from '../models/companyModel.js';
import Branch from '../models/branchModel.js';

// GET /api/companies/:companyId/kiosks
export const getCompanyKiosks = async (req, res) => {
  try {
    const { companyId } = req.params;

    const kiosks = await AttendanceKiosk.find({
      company: companyId,
    })
      .populate('branches', 'name') // only need name
      .lean();

    const result = kiosks.map((k) => ({
      id: String(k._id),
      name: k.name,
      dialCode: k.dialCode,
      phone: k.phoneNumber,
      branches: k.branches?.map((b) => ({
        id: String(b._id),
        name: b.name,
      })) || [],
    }));

    res.json({ kiosks: result });
  } catch (err) {
    console.error('getCompanyKiosks error', err);
    res.status(500).json({ message: 'Server error' });
  }
};

// POST /api/companies/:companyId/kiosks
export const createKiosk = async (req, res) => {
  try {
    const { companyId } = req.params;
    const { name, dialCode, phoneNumber, branchIds } = req.body;

    if (!name?.trim() || !dialCode?.trim() || !phoneNumber?.trim()) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    const company = await Company.findById(companyId);
    if (!company) {
      return res.status(404).json({ message: 'Company not found' });
    }

    let branches = [];
    if (Array.isArray(branchIds) && branchIds.length) {
      branches = branchIds.map((id) => new mongoose.Types.ObjectId(id));
      // optional: validate they belong to same company
      await Branch.find({
        _id: { $in: branches },
        company: companyId,
      });
    }

    const kiosk = await AttendanceKiosk.create({
      company: companyId,
      name: name.trim(),
      dialCode: dialCode.trim(),
      phoneNumber: phoneNumber.trim(),
      branches,
    });

    company.attendanceKiosks.push(kiosk._id);
    await company.save();

    return res.status(201).json({
      id: String(kiosk._id),
      name: kiosk.name,
      dialCode: kiosk.dialCode,
      phone: kiosk.phoneNumber,
      branches: [],
    });
  } catch (err) {
    console.error('createKiosk error', err);
    res.status(500).json({ message: 'Server error' });
  }
};

// PUT /api/companies/kiosks/:kioskId
export const updateKiosk = async (req, res) => {
  try {
    const { kioskId } = req.params;
    const { name, branchIds } = req.body;

    const kiosk = await AttendanceKiosk.findById(kioskId);
    if (!kiosk) {
      return res.status(404).json({ message: 'Kiosk not found' });
    }

    if (name != null) kiosk.name = name.trim();

    if (Array.isArray(branchIds)) {
      kiosk.branches = branchIds.map(
        (id) => new mongoose.Types.ObjectId(id)
      );
    }

    const updated = await kiosk.save();

    res.json({
      id: String(updated._id),
      name: updated.name,
      dialCode: updated.dialCode,
      phone: updated.phoneNumber,
      branches: updated.branches.map((b) => String(b)),
    });
  } catch (err) {
    console.error('updateKiosk error', err);
    res.status(500).json({ message: 'Server error' });
  }
};

// DELETE /api/companies/kiosks/:kioskId
export const deleteKiosk = async (req, res) => {
  try {
    const { kioskId } = req.params;

    const kiosk = await AttendanceKiosk.findById(kioskId);
    if (!kiosk) {
      return res.status(404).json({ message: 'Kiosk not found' });
    }

    // remove from company.attendanceKiosks
    await Company.updateOne(
      { _id: kiosk.company },
      { $pull: { attendanceKiosks: kiosk._id } }
    );

    await kiosk.deleteOne();

    res.json({ message: 'Kiosk deleted' });
  } catch (err) {
    console.error('deleteKiosk error', err);
    res.status(500).json({ message: 'Server error' });
  }
};
