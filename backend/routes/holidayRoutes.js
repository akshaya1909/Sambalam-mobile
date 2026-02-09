// routes/holidayRoutes.js
import express from 'express';
import { getIndiaPublicHolidays } from '../controllers/calendarificController.js';
import {
  getCompanyHolidays,
  upsertCompanyHolidays,
} from '../controllers/companyHolidayController.js';

const router = express.Router();

// govt holidays from Calendarific
router.get('/public-holidays/india/:year', getIndiaPublicHolidays);

// company-specific holidays
router.get('/company/:companyId/holidays/:year', getCompanyHolidays);
router.post('/company/:companyId/holidays/:year', upsertCompanyHolidays);

export default router;
