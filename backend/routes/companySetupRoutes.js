import express from 'express';
import upload from '../middleware/uploadMiddleware.js';
import {
  createCompanyInfo,
  updateContactDetails,
  updateAdminInfo,
  updateSettings,
  updateCompliance,
  uploadDocuments,
  getCompanySetup
} from '../controllers/companySetupController.js';

const router = express.Router();

// Step 1: Company Info
router.post('/company-info', upload.single('companyLogo'), createCompanyInfo);

// Step 2: Contact Details
router.put('/contact-details/:id', updateContactDetails);

// Step 3: Admin Info
router.put('/admin-info/:id', updateAdminInfo);

// Step 4: Company Settings
router.put('/settings/:id', updateSettings);

// Step 5: Compliance
router.put('/compliance/:id', updateCompliance);

// Step 6: Upload Documents
router.put(
  '/documents/:id',
  upload.fields([
    { name: 'certificateOfIncorporation' },
    { name: 'panCard' },
    { name: 'gstRegistration' },
    { name: 'authorizedSignatoryId' },
    { name: 'pfEsiRegistration' },
    { name: 'moaAoa' },
    { name: 'professionalTaxCertificate' },
    { name: 'shopEstablishmentLicense' },
    { name: 'leavePolicyDocument' },
  ]),
  uploadDocuments
);

// Get Full Company Setup by ID
router.get('/:id', getCompanySetup);

export default router;
