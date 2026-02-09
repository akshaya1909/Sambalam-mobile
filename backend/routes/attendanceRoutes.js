import express from "express";
import { punchAttendanceController, getTodayStatusController, getMonthlyAttendanceController, getCompanyAttendanceStatsController,
    getCompanyLiveAttendanceController, updateAttendanceStatus, adminPunchInController, adminPunchOutController, adminDeletePunchInController,
    adminDeletePunchOutController, getCompanyDailyAttendanceController, updateStatusController,
    updateRemarksController, upsertMobileAlarm, getMobileAlarmsController, getEmployeeAttendance, getWorkScheduleController } from "../controllers/attendanceController.js";
    import { initializeDailyStatus } from "../services/attendanceCronService.js";
import upload from "../middleware/uploadMiddleware.js";
import { protect } from '../middleware/authMiddleware.js'; 

const router = express.Router();

// POST /api/attendance/punch
router.post("/punch", upload.single('photo'), punchAttendanceController);
router.get("/employee/:employeeId", getEmployeeAttendance);
router.post("/admin/punch-in", adminPunchInController);
router.post("/admin/punch-out", adminPunchOutController);
router.post('/admin/punch-in/delete', adminDeletePunchInController);
router.post('/admin/punch-out/delete', adminDeletePunchOutController);
router.get("/schedule/:employeeId", getWorkScheduleController);
router.post("/trigger-auto-absent", async (req, res) => {
  try {
    await initializeDailyStatus(); // Calls the function we created in the service
    res.status(200).json({ message: "Auto-mark absent logic executed successfully" });
  } catch (error) {
    res.status(500).json({ message: "Failed to trigger logic", error: error.message });
  }
});
router.patch(
    "/:companyId/:employeeId/status",
    // add auth middleware here if needed
    updateStatusController
  );
  
  // PATCH /api/attendance/:companyId/:employeeId/remarks
  router.patch(
    "/:companyId/:employeeId/remarks",
    updateRemarksController
  );
router.get("/today-status", getTodayStatusController);
router.get("/monthly", getMonthlyAttendanceController);
router.get('/daily', getCompanyDailyAttendanceController);
router.get("/stats", getCompanyAttendanceStatsController);
router.get('/company/live-attendance', getCompanyLiveAttendanceController);
router.put('/status', updateAttendanceStatus);
router.post('/mobile-alarm', upsertMobileAlarm);
router.get('/:employeeId/mobile-alarms', getMobileAlarmsController);

export default router;
