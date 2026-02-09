import express from 'express';
import { 
  createAnnouncementController, 
  getCompanyAnnouncementsController,
  markAnnouncementAsRead,
  getUnreadAnnouncementCount
} from '../controllers/announcementController.js';

const router = express.Router();

router.post('/create/:adminId', createAnnouncementController);
router.get('/company/:companyId', getCompanyAnnouncementsController);
router.get('/unread-count/:companyId/:userId', getUnreadAnnouncementCount);
router.put("/:announcementId/read", markAnnouncementAsRead);

export default router;
