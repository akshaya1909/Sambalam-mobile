import express from 'express';
import { generateTdsMatrix, getTdsRecords } from '../controllers/tdsController.js';

const router = express.Router();

router.post('/calculate', generateTdsMatrix);
router.get('/data', getTdsRecords);

export default router;