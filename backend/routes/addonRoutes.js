import express from 'express';
const router = express.Router();
import { getAddons, createAddon, updateAddon, deleteAddon } from '../controllers/addonController.js';

router.route('/')
    .get(getAddons)
    .post(createAddon);
    router.route('/:id')
    .put(updateAddon)
    .delete(deleteAddon);

export default router;