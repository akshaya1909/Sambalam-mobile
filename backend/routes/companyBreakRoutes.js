// routes/companyBreakRoutes.js
import express from 'express';
import {
  createCompanyBreak,
  getCompanyBreaks,
  updateCompanyBreak,
  deleteCompanyBreak,
} from '../controllers/companyBreakController.js';

const router = express.Router();

// create break for a company
router.post('/:companyId', createCompanyBreak);

// get all breaks for a company
router.get('/company/:companyId', getCompanyBreaks);

// update / delete single break
router.put('/:breakId', updateCompanyBreak);
router.delete('/:breakId', deleteCompanyBreak);

export default router;
