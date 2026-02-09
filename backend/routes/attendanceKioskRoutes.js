// routes/attendanceKioskRoutes.js
import express from 'express';
import {
  getCompanyKiosks,
  createKiosk,
  updateKiosk,
  deleteKiosk,
} from '../controllers/attendanceKioskController.js';

const router = express.Router();

// company-scoped
router.get('/:companyId/kiosks', getCompanyKiosks);
router.post('/:companyId/kiosks', createKiosk);

// update / delete by kiosk id
router.put('/kiosks/:kioskId', updateKiosk);
router.delete('/kiosks/:kioskId', deleteKiosk);

export default router;
