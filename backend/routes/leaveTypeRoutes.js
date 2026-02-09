// routes/leaveTypeRoutes.js
import express from 'express';
import {
  getCompanyLeaveTypes,
  createLeaveType,
  updateLeaveType,
  deleteLeaveType,
} from '../controllers/leaveTypeController.js';
// import { protect } from '../middleware/authMiddleware.js';

const router = express.Router();

// router.use(protect);

router.get('/:companyId/leave-types', getCompanyLeaveTypes);
router.post('/:companyId/leave-types', createLeaveType);
router.put('/leave-types/:leaveTypeId', updateLeaveType);
router.delete('/leave-types/:leaveTypeId', deleteLeaveType);

export default router;
