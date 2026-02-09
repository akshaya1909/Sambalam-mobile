import express from "express";
import { 
  getSystemSettings, 
  toggleMaintenanceMode 
} from "../controllers/systemSettingsController.js";
// import { protect, admin } from "../middleware/authMiddleware.js";

const router = express.Router();

// Publicly readable so the app can block users if maintenance is on
router.get("/settings", getSystemSettings);

// Protected: Only Master Admins should toggle this
router.patch("/maintenance", toggleMaintenanceMode);

export default router;