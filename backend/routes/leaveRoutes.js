// routes/leaveRoutes.js
import express from "express";
import { getLeaveBalanceController, createLeaveRequestController, getEmployeeLeaveRequestsController, getPendingLeaveRequestsController,
    updateLeaveStatusController } from "../controllers/leaveController.js";

const router = express.Router();

// GET /api/leaves/balance?employeeId=...&companyId=...
router.get("/balance", getLeaveBalanceController);
router.post("/request", createLeaveRequestController);
router.get("/requests", getEmployeeLeaveRequestsController);
router.get("/pending", getPendingLeaveRequestsController);
router.put("/status", updateLeaveStatusController); 

export default router;
