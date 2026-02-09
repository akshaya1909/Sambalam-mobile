// routes/incentiveRoutes.js
import express from 'express';
import {
  getCompanyIncentiveTypes,
  createIncentiveType,
  updateIncentiveType,
  deleteIncentiveType,
} from '../controllers/incentiveController.js';

const router = express.Router();

router
  .route('/company/:companyId')
  .get(getCompanyIncentiveTypes)
  .post(createIncentiveType);

router
  .route('/:id')
  .put(updateIncentiveType)
  .delete(deleteIncentiveType);

export default router;
