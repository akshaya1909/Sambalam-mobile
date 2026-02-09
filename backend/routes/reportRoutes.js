import express from 'express';
import { getReportData, getReportHistory } from '../controllers/reportController.js';
// import { protect } from '../middleware/authMiddleware.js'; // Assuming you have auth

const router = express.Router();

// Route: GET /api/reports/generate?companyId=...&reportType=...
router.get('/generate', getReportData); 

// Route: GET /api/reports/history?companyId=...
router.get('/history', getReportHistory); 

export default router;