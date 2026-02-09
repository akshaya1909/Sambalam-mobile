// routes/biometricDeviceRoutes.js
import express from 'express';
import {
  getCompanyBiometricDevices,
  createBiometricDevice,
  updateBiometricDevice,
  deleteBiometricDevice,
} from '../controllers/biometricDeviceController.js';

const router = express.Router();

router.get('/:companyId/biometric-devices', getCompanyBiometricDevices);
router.post('/:companyId/biometric-devices', createBiometricDevice);

router.put('/biometric-devices/:deviceId', updateBiometricDevice);
router.delete('/biometric-devices/:deviceId', deleteBiometricDevice);

export default router;
