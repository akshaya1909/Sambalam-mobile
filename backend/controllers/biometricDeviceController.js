// controllers/biometricDeviceController.js
import mongoose from 'mongoose';
import BiometricDevice from '../models/biometricDeviceModel.js';
import Company from '../models/companyModel.js';
import Branch from '../models/branchModel.js';

// GET /api/companies/:companyId/biometric-devices
export const getCompanyBiometricDevices = async (req, res) => {
  try {
    const { companyId } = req.params;

    const devices = await BiometricDevice.find({ company: companyId })
      .populate('branches', 'name')
      .lean();

    const result = devices.map((d) => ({
      id: String(d._id),
      deviceName: d.deviceName,
      serialNumber: d.serialNumber,
      branches: d.branches?.map((b) => ({ id: String(b._id), name: b.name })) || [],
    }));

    res.json({ devices: result });
  } catch (err) {
    console.error('getCompanyBiometricDevices error', err);
    res.status(500).json({ message: 'Server error' });
  }
};

// POST /api/companies/:companyId/biometric-devices
export const createBiometricDevice = async (req, res) => {
  try {
    const { companyId } = req.params;
    const { deviceName, serialNumber, branchIds } = req.body;

    if (!deviceName?.trim() || !serialNumber?.trim()) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    const company = await Company.findById(companyId).populate('branches', '_id');
    if (!company) {
      return res.status(404).json({ message: 'Company not found' });
    }

    let branches = [];
    if (Array.isArray(branchIds) && branchIds.length) {
      branches = branchIds.map((id) => new mongoose.Types.ObjectId(id));
    } else {
      // no branch selected => all company branches
      branches = company.branches.map((b) => b._id);
    }

    const device = await BiometricDevice.create({
      company: companyId,
      deviceName: deviceName.trim(),
      serialNumber: serialNumber.trim(),
      branches,
    });

    company.biometricDevices.push(device._id);
    await company.save();

    res.status(201).json({
      id: String(device._id),
      deviceName: device.deviceName,
      serialNumber: device.serialNumber,
      branches: branches.map((id) => String(id)),
    });
  } catch (err) {
    console.error('createBiometricDevice error', err);
    if (err.code === 11000) {
      return res.status(400).json({ message: 'Serial number already exists' });
    }
    res.status(500).json({ message: 'Server error' });
  }
};

// PUT /api/companies/biometric-devices/:deviceId
export const updateBiometricDevice = async (req, res) => {
    try {
      const { deviceId } = req.params;
      const { deviceName, serialNumber, branchIds } = req.body;
  
      const device = await BiometricDevice.findById(deviceId);
      if (!device) {
        return res.status(404).json({ message: 'Device not found' });
      }
  
      if (deviceName != null) device.deviceName = deviceName.trim();
  
      // NEW: allow editing serial number
      if (serialNumber != null) device.serialNumber = serialNumber.trim();
  
      if (Array.isArray(branchIds)) {
        if (branchIds.length) {
          device.branches = branchIds.map(
            (id) => new mongoose.Types.ObjectId(id)
          );
        } else {
          const company = await Company.findById(device.company).populate(
            'branches',
            '_id'
          );
          device.branches = company ? company.branches.map((b) => b._id) : [];
        }
      }
  
      const updated = await device.save();
  
      res.json({
        id: String(updated._id),
        deviceName: updated.deviceName,
        serialNumber: updated.serialNumber,
        branches: updated.branches.map((id) => String(id)),
      });
    } catch (err) {
      console.error('updateBiometricDevice error', err);
      if (err.code === 11000) {
        // handle unique serialNumber conflict
        return res.status(400).json({ message: 'Serial number already exists' });
      }
      res.status(500).json({ message: 'Server error' });
    }
  };

// DELETE /api/companies/biometric-devices/:deviceId
export const deleteBiometricDevice = async (req, res) => {
  try {
    const { deviceId } = req.params;

    const device = await BiometricDevice.findById(deviceId);
    if (!device) {
      return res.status(404).json({ message: 'Device not found' });
    }

    await Company.updateOne(
      { _id: device.company },
      { $pull: { biometricDevices: device._id } }
    );

    await device.deleteOne();

    res.json({ message: 'Device deleted' });
  } catch (err) {
    console.error('deleteBiometricDevice error', err);
    res.status(500).json({ message: 'Server error' });
  }
};
