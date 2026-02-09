// routes/departmentRoutes.js
import express from 'express';
import {
  createDepartment,
  getCompanyDepartments,
  deleteDepartment,
  addDepartmentStaff,
  removeDepartmentStaff
} from '../controllers/departmentController.js';

const router = express.Router();

// POST /api/department/:companyId
router.post('/:companyId', createDepartment);

// GET /api/department/company/:companyId
router.get('/company/:companyId', getCompanyDepartments);
router.delete('/:departmentId', deleteDepartment);
router.post('/:departmentId/staff', addDepartmentStaff);
router.delete('/:departmentId/staff/:employeeId', removeDepartmentStaff);

export default router;
