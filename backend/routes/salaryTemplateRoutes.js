import express from "express";
import { 
  getSalaryTemplates, 
  createSalaryTemplate, 
  updateSalaryTemplate, 
  deleteSalaryTemplate 
} from "../controllers/salaryTemplateController.js";

const router = express.Router();

router.get("/:companyId", getSalaryTemplates);
router.post("/", createSalaryTemplate);
router.put("/:id", updateSalaryTemplate);
router.delete("/:id", deleteSalaryTemplate);

export default router;