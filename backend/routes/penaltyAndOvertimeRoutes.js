// routes/penaltyAndOvertimeRoutes.js
import express from "express";
import {
  updateEarlyLeavingPolicy,
  getEarlyLeavingPolicy,
  updateLateComingPolicy,
  getLateComingPolicy,
  getOvertimePolicy,
  updateOvertimePolicy,
  getCompanyPenaltyDetails
} from "../controllers/penaltyAndOvertimeController.js";

const router = express.Router();

router.get("/early-leaving/:employeeId", getEarlyLeavingPolicy);
router.get("/late-coming/:employeeId", getLateComingPolicy);
router.get("/over-time/:employeeId", getOvertimePolicy);
router.put("/early-leaving/:employeeId", updateEarlyLeavingPolicy);
router.put("/late-coming/:employeeId", updateLateComingPolicy);
router.put("/over-time/:employeeId", updateOvertimePolicy);
router.get("/company-penalty-details/:companyId", getCompanyPenaltyDetails);

export default router;
