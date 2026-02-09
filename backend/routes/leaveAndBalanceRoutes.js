import express from "express";
import { upsertLeaveAndBalance, getLeavePolicyByEmployeeId, resetLeavePolicy, updateEmployeeLeaveBalance, getCompanyLeaveDetails,
    createLeaveRequest, getCompanyLeaveRequests, updateLeaveRequestStatus,getEmployeeLeaveRequests } from "../controllers/leaveAndBalanceController.js";
import upload from "../middleware/uploadMiddleware.js";

const router = express.Router();

router.post("/upsert", upsertLeaveAndBalance);
router.get("/employee/:employeeId", getLeavePolicyByEmployeeId);
router.put("/reset/:employeeId", resetLeavePolicy);
router.put("/update-balance", updateEmployeeLeaveBalance);
router.get("/company-leave-details/:companyId", getCompanyLeaveDetails);
router.post("/request", upload.single('file'), createLeaveRequest);
router.get("/company/:companyId/requests", getCompanyLeaveRequests);
router.put("/request/status", updateLeaveRequestStatus);
router.get("/employee/:employeeId/requests", getEmployeeLeaveRequests);


export default router;
