import express from "express";
import { createAdvertiseDetails } from "../controllers/advertiseDetailsController.js";
// import { protect } from "../middleware/authMiddleware.js";

const router = express.Router();

router.post("/", createAdvertiseDetails);

export default router;
