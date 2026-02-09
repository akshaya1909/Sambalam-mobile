import express from 'express';
import { getCompanyAdmins, createAdmin, updateAdmin, deleteAdmin,getCurrentAdminForCompany, getPendingDeviceRequests, handleDeviceRequest } from '../controllers/adminController.js';

const router = express.Router({ mergeParams: true });

// Get all admins for a company
router.get('/current', getCurrentAdminForCompany);
router.get('/device-requests/:companyId', getPendingDeviceRequests);

// Approve or Reject a specific request
router.post('/device-requests/:requestId/action', handleDeviceRequest);
router.get('/:companyId/admins', getCompanyAdmins);

// Create new admin for company
router.post('/:companyId/admins', createAdmin);

// Update admin
router.put('/admins/:adminId', updateAdmin);

// Delete admin
router.delete('/admins/:adminId', deleteAdmin);

export default router;
