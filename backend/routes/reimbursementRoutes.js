import express from 'express';
import multer from 'multer';
import path from 'path';
import upload from '../middleware/uploadMiddleware.js';
import { createReimbursement, getReimbursements, updateReimbursementStatus, getPendingReimbursements, updateReimbursementStatusByAdmin } from '../controllers/reimbursementController.js';

const router = express.Router();

// Multer Setup
// const storage = multer.diskStorage({
//   destination: (req, file, cb) => cb(null, 'uploads/'),
//   filename: (req, file, cb) => cb(null, `${Date.now()}-${file.originalname}`)
// });
// const upload = multer({ storage });

// Routes
router.post('/', upload.array('attachments', 3), createReimbursement); // Allow up to 3 files
router.get('/', getReimbursements);
router.get('/pending', getPendingReimbursements);
router.put('update/:id/status', updateReimbursementStatusByAdmin);
router.put('/:id/status', updateReimbursementStatus);


export default router;