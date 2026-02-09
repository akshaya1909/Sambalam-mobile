// routes/shiftRoutes.js
import express from 'express';
import {
  createShift,
  getCompanyShifts,
  updateShift,
  deleteShift,
} from '../controllers/shiftController.js';

const router = express.Router();

// create shift for a company
router.post('/:companyId', createShift);

// get all shifts for a company
router.get('/company/:companyId', getCompanyShifts);

// update / delete single shift
router.put('/:shiftId', updateShift);
router.delete('/:shiftId', deleteShift);

export default router;
