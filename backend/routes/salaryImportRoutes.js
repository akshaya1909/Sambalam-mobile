import express from "express";
import { 
  getImportSettings, 
  updateImportSettings, 
  downloadTemplate, 
  importSalaryData 
} from "../controllers/salaryImportController.js";
import upload from "../middleware/uploadMiddleware.js"; // Reuse your existing multer middleware

const router = express.Router();

router.get("/:companyId/settings", getImportSettings);
router.put("/:companyId/settings", updateImportSettings);
router.get("/:companyId/template", downloadTemplate);
router.post("/:companyId/import", upload.single("file"), importSalaryData);

export default router;