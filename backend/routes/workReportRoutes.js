import express from 'express';
import { saveWorkReportTemplate, getCompanyTemplates, deleteTemplate, getApplicableTemplates, getEmployeeMonthlyReports, submitDailyReport,
    getDayReport } from '../controllers/workReportController.js';

const router = express.Router();

router.post('/template/save', saveWorkReportTemplate);
router.get('/templates/:companyId', getCompanyTemplates);
router.delete('/template/:id', deleteTemplate);

router.get('/applicable/:employeeId', getApplicableTemplates);
router.get('/monthly', getEmployeeMonthlyReports); // Use query params: ?employeeId=X&year=Y&month=Z
router.post('/submit', submitDailyReport);
router.get('/day-report', getDayReport);

export default router;