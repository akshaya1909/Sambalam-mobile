import express from 'express';
import {
  checkPhone,
  verifyOtp,
  checkUserStatus,
  updateSecurePin,
  getUserCompanies,
  saveFcmToken,
  getUserById,
  getUserIdByPhone,
  getAssignedBranches
} from '../controllers/userController.js';

const router = express.Router();

router.post('/check-phone', checkPhone);
router.get('/assigned-branches', getAssignedBranches);
router.post('/verify-otp', verifyOtp);
router.post('/check-user-status', checkUserStatus);
router.post('/update-secure-pin', updateSecurePin);
router.get('/companies', getUserCompanies);
router.get("/get-id/:phone", getUserIdByPhone);
router.post('/users/:userId/fcm-token', saveFcmToken);
router.get('/:id', getUserById);

export default router;
