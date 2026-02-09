import express from "express";
import { createAdminDetails, getAdminCompaniesController,checkAdminStatusController } from "../controllers/adminDetailsController.js";
// import { protect } from "../middleware/authMiddleware.js";

const router = express.Router();

router.post("/", createAdminDetails);
router.get('/companies/:adminId', getAdminCompaniesController);
router.get('/status/:phoneNumber', checkAdminStatusController);

export default router;
