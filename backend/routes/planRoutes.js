import express from 'express';
import { getPlans, createPlan, updatePlan, deletePlan } from '../controllers/planController.js';
const router = express.Router();

router.route('/').get(getPlans).post(createPlan);
router.route('/:id').put(updatePlan).delete(deletePlan);

export default router;