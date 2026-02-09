import express from 'express';
import { createJoinRequest } from '../controllers/newJoinRequestController.js';
import { 
  joinCompanyByCode, 
  createCompany, 
  getUsersByCompanyId, 
  requestJoinCompany, 
  reviewJoinRequest, 
  getJoinStatus, 
  getPendingJoinRequests, 
  approveJoinRequest, 
  declineJoinRequest,
  getCompanyById,
  getCompanyStaffController ,
  getCompanyBasicByIdController,
  getCompanyDetails,
  updateCompanyDetails,
  updateCompanySettings,
  getUserCompanies,
  deleteAllStaff,
  updateCompanyUserRole,
  getRolesByCompanyId,
  getCompanyPlan
} from '../controllers/companyController.js';
import upload from "../middleware/uploadMiddleware.js";
// import { protect } from '../middleware/authMiddleware.js'; // ensure user is authenticated

const router = express.Router();

// router.post('/join', joinCompanyByCode);

router.get('/user/:phoneNumber', getUserCompanies);
router.post('/join-request', upload.single('image'), createJoinRequest);
router.get("/staff", getCompanyStaffController);
router.post('/create', createCompany);
router.get('/company-users/:companyId', getUsersByCompanyId);
router.get('/company-roles/:companyId', getRolesByCompanyId);
router.post("/join", requestJoinCompany);
router.put("/join-requests/:requestId", reviewJoinRequest); // For admin approval/rejection
router.get('/join-status/:phoneNumber', getJoinStatus);
router.post('/validate-teamcode', joinCompanyByCode);
router.get('/join/pending', getPendingJoinRequests);
router.put("/join/:id/approve", approveJoinRequest);
router.delete("/join/:id/decline", declineJoinRequest);
router.get('/basic/:companyId', getCompanyBasicByIdController);
router.get('/:companyId', getCompanyById);
router.put('/:id/settings', updateCompanySettings);
router.put('/:companyId/users/:userId/role', updateCompanyUserRole);
router.delete('/:companyId/staff/all', deleteAllStaff);
router.get('/details/:companyId', getCompanyDetails);
router.put('/details/:companyId', upload.single('logo'), updateCompanyDetails);
router.get('/:id/plan', getCompanyPlan);

export default router;
