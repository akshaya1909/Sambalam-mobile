import express from 'express';
import { login, verifyDeviceController } from '../controllers/authController.js';

const router = express.Router();

router.post('/login', login);
router.post('/verify-device', verifyDeviceController);

export default router;
