import express from "express";
import { getBankDetailsByEmployee, saveBankDetails, verifyBankAccount, verifyUpi,
    getCompanyBankDetails } from "../controllers/bankDetailsController.js";

const router = express.Router();

router.get('/employee/:employeeId', getBankDetailsByEmployee);
router.put('/verify-bank/:employeeId', verifyBankAccount);
router.put('/verify-upi/:employeeId', verifyUpi);
router.get('/company-bank-details/:companyId', getCompanyBankDetails);
router.post('/', saveBankDetails);
export default router;