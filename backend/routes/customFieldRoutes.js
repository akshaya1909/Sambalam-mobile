// routes/customFieldRoutes.js
import express from 'express';
import {
  getCompanyCustomFields,
  createCustomField,
  updateCustomField,
  deleteCustomField,
} from '../controllers/customFieldController.js';

const router = express.Router();

// /api/companies/:companyId/custom-fields
router.put('/custom-fields/:fieldId', updateCustomField);
router.delete('/custom-fields/:fieldId', deleteCustomField);
router.get('/:companyId/custom-fields', getCompanyCustomFields);
router.post('/:companyId/custom-fields', createCustomField);

export default router;
