import express from 'express';
import { getEmployeeNotes, createNote } from '../controllers/notesController.js';
import upload from '../middleware/uploadMiddleware.js'; // Your multer file

const router = express.Router();

// POST /api/notes - Save a new note (Text or File metadata)
router.post('/', upload.single('file'), createNote);

// GET /api/notes/:employeeId - Fetch history for a specific person
router.get('/:employeeId', getEmployeeNotes);

export default router;