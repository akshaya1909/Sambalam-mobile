import express from "express";
import {
  getSalaryDetails,
  updateSalaryDetails,
  getCompanySalaryDetails,
  getSalaryData
} from "../controllers/salaryDetailsController.js";
const router = express.Router();

router.get("/company/:companyId", getCompanySalaryDetails);
router.get('/calculate', getSalaryData);
router.get("/:employeeId", getSalaryDetails);
router.put("/:employeeId", updateSalaryDetails);

export default router;
