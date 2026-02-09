import express from 'express';
import {
    getEmployeesByCompany,
    runPayroll,
    getCompanyPayrolls,
    savePayment,
    saveAdvance,        
    saveIncentives,     
    saveReimbursements,
    getAdvanceLedger,
    getSingleEmployeePayroll,
    getPayrollTrend
} from '../controllers/PayrollController.js'; 

// Import TDS Controller (Matches the export name in controller file)
import { getTdsRecords, generateTdsMatrix } from '../controllers/tdsController.js';

const router = express.Router();

// --- PAYROLL ROUTES ---
router.route('/employees').get(getEmployeesByCompany); 
router.route("/employee/:employeeId").get(getSingleEmployeePayroll);
router.route('/run').post(runPayroll);
router.route('/pay').post(savePayment);

// --- MODULE ENDPOINTS ---
router.route('/advance/list').get(getAdvanceLedger);
router.route('/advance').post(saveAdvance);
router.route('/incentives').post(saveIncentives);
router.route('/reimbursements').post(saveReimbursements);

// --- TDS MODULE ROUTES ---
// GET: /api/payroll/tds/data
router.get('/tds/data', getTdsRecords); 

// POST: /api/payroll/tds/calculate
// We map this route to the "generateTdsMatrix" function
router.post('/tds/calculate', generateTdsMatrix);

// --- HISTORY ---
router.route('/list').get(getCompanyPayrolls);
router.get("/trend/:companyId", getPayrollTrend);

export default router;