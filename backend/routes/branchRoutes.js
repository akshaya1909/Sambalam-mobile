// routes/branchRoutes.js
import express from 'express';
import { createBranch, getCompanyBranches, getBranchById, updateBranch, deleteBranch } from '../controllers/branchController.js';
import { protect } from '../middleware/authMiddleware.js';

const router = express.Router();

// create new branch for a company
router.post('/:companyId/branches', createBranch);
router.get('/:companyId/branches', getCompanyBranches);
router.put('/:branchId', updateBranch);
router.delete('/:branchId', deleteBranch);
router.get('/by-id/:branchId', getBranchById);

export default router;
