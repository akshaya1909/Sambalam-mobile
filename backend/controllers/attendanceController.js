import mongoose from "mongoose";
import Attendance from "../models/attendanceModel.js";
import Employee from '../models/employeeModel.js';
import { sendNotificationToCompanyAdmins } from "../services/fcmService.js";
import { punchAttendance, getTodayStatus, getMonthlyAttendance, getCompanyDailyAttendanceStats, getCompanyLiveAttendanceList, getCompanyDailyAttendanceList,
  updateDailyStatus,
  updateDailyRemarks, getEmployeeWorkSchedule } from "../services/attendanceService.js";
  import { getMobileAlarms } from '../services/attendanceAlarmService.js';

  export const punchAttendanceController = async (req, res) => {
    try {
      const { employeeId, companyId, punchedFrom, lat, lng, address } = req.body;
  
      if (!employeeId || !companyId) {
        return res.status(400).json({ message: "employeeId and companyId are required" });
      }
  
      let photoUrl = null;
      if (req.file) {
        photoUrl = `/uploads/${req.file.filename}`;
      }
  
      const location = {
        lat: lat ? Number(lat) : null,
        lng: lng ? Number(lng) : null,
        address: address || null,
      };
  
      // 1. Call Service
      const result = await punchAttendance({
        employeeId,
        companyId,
        punchedFrom: punchedFrom || "Mobile",
        photoUrl,
        location,
      });
  
      // 2. DETERMINE STATUS MANUALLY
      // The service returns 'todayRecord'. We must look inside it.
      let currentStatus = "none";
      
      if (result.status === 'completed') {
         currentStatus = 'completed'; // Already done for the day
      } else if (result.todayRecord) {
        // Check Punch Out first (if it exists, they just punched out)
        if (result.todayRecord.punchOut && result.todayRecord.punchOut.time) {
          currentStatus = "out";
        } 
        // Otherwise check Punch In
        else if (result.todayRecord.punchIn && result.todayRecord.punchIn.time) {
          currentStatus = "in";
        }
      }
  
      console.log("📊 Detected Status:", currentStatus); // Debug Log
  
      // 3. TRIGGER NOTIFICATION
      // Only notify if status is 'in' or 'out'
      if (result.todayRecord && (currentStatus === 'in' || currentStatus === 'out')) {
        
        const employee = await Employee.findById(employeeId);
        
        if (employee) {
          const branchId = employee.basic.branches && employee.basic.branches.length > 0 
      ? employee.basic.branches[0] 
      : null;
          const action = currentStatus === 'in' ? "punched in" : "punched out";
          
          const timeStr = new Date().toLocaleTimeString('en-US', { 
              hour: 'numeric', minute: '2-digit', hour12: true, timeZone: 'Asia/Kolkata' 
          });
          
          const shortAddress = address 
              ? (address.length > 30 ? address.substring(0, 30) + '...' : address) 
              : 'Location not available';
  
          const payload = {
            employeeId: String(employeeId),
            branchId: String(branchId),
            employeeName: employee.basic.fullName,
            employeePhoto: employee.basic.profilePic || "",
            image: photoUrl || "",
            address: address || "",
            lat: Number(lat) || 0,
            lng: Number(lng) || 0,
            eventTime: new Date(),
            status: currentStatus
          };
  
          console.log("🔔 Sending Notification for:", employee.basic.fullName);
  
          // Fire and forget
          sendNotificationToCompanyAdmins(companyId, {
            type: 'Attendance',
            title: `${employee.basic.fullName} has ${action}.`,
            body: `${timeStr} | ${shortAddress}`,
            payload: payload
          });
        }
      }
  
      // 4. Send Response
      res.status(200).json({
        message: currentStatus === 'completed' 
          ? "Already completed for today" 
          : (currentStatus === 'in' ? "Punched in" : "Punched out"),
        status: currentStatus,
        todayRecord: result.todayRecord,
      });
  
    } catch (err) {
      console.error("Punch attendance error:", err.message);
      
      // Check the error message to decide the status code
      const statusCode = err.message.includes("Out of range") ? 403 : 400;
  
      // Ensure we only send ONE error response
      if (!res.headersSent) {
        return res.status(statusCode).json({ message: err.message || "Unable to punch attendance" });
      }
    }
  };


  export const getTodayStatusController = async (req, res) => {
    try {
      const { employeeId, companyId } = req.query;
      
      if (!employeeId || !companyId) {
        return res.status(400).json({ message: "employeeId and companyId required" });
      }
  
      const status = await getTodayStatus({
        employeeId,
        companyId
      });
  
      res.status(200).json({
        status: status  // "none" | "in" | "out"
      });
    } catch (err) {
      console.error("Today status error:", err);
      res.status(400).json({ status: "none" });
    }
  };


  export const getMonthlyAttendanceController = async (req, res) => {
    try {
      const { employeeId, companyId, year, month } = req.query;
      console.log("employeeId", employeeId)
      console.log("companyId", companyId)
      console.log("year", year)
      console.log("month", month)
  
      if (!employeeId || !companyId || !year || !month) {
        return res
          .status(400)
          .json({ message: "employeeId, companyId, year, and month are required" });
      }
  
      const result = await getMonthlyAttendance({
        employeeId,
        companyId,
        year: Number(year),
        month: Number(month),
      });
  
      if (!result) {
        return res.status(200).json({ records: [] });
      }
      console.log("result: ", result)
  
      return res.status(200).json(result);
    } catch (err) {
      console.error("Monthly attendance error:", err);
      return res
        .status(400)
        .json({ message: err.message || "Unable to fetch monthly attendance" });
    }
  };

  export const getCompanyAttendanceStatsController = async (req, res) => {
    try {
      const { companyId, branchId } = req.query;
  
      if (!companyId) {
        return res.status(400).json({ message: "companyId is required" });
      }
  
      const stats = await getCompanyDailyAttendanceStats(companyId, branchId);
      
      res.status(200).json(stats);
    } catch (err) {
      console.error("Attendance stats error:", err);
      res.status(400).json({ 
        message: err.message || "Unable to fetch attendance stats" 
      });
    }
  };

  export const getCompanyLiveAttendanceController = async (req, res) => {
    try {
      const { companyId, branchId } = req.query;
  
      if (!companyId) {
        return res.status(400).json({ message: 'companyId is required' });
      }
  
      const list = await getCompanyLiveAttendanceList(String(companyId), branchId);
      return res.status(200).json(list);
    } catch (err) {
      console.error('getCompanyLiveAttendanceController error:', err);
      return res
        .status(500)
        .json({ message: err.message || 'Failed to fetch attendance list' });
    }
  };

  export const getCompanyDailyAttendanceController = async (req, res) => {
    try {
      const { companyId, branchId, date } = req.query;
      if (!companyId || !date) {
        return res
          .status(400)
          .json({ message: 'companyId and date are required' });
      }
  
      const target = new Date(date); // expect "2025-12-09"
  
      const targetIst = new Date(
        target.toLocaleString('en-US', { timeZone: 'Asia/Kolkata' })
      );
      const start = new Date(
        targetIst.getFullYear(),
        targetIst.getMonth(),
        targetIst.getDate(),
        0,
        0,
        0,
        0
      );
      const end = new Date(
        targetIst.getFullYear(),
        targetIst.getMonth(),
        targetIst.getDate(),
        23,
        59,
        59,
        999
      );
  
      const list = await getCompanyDailyAttendanceList({
        companyId: String(companyId),
        branchId,
        start,
        end,
      });
  
      return res.status(200).json(list);
    } catch (err) {
      console.error('getCompanyDailyAttendanceController error:', err);
      return res
        .status(500)
        .json({ message: err.message || 'Failed to fetch daily attendance' });
    }
  };

  export const updateAttendanceStatus = async (req, res) => {
    try {
      const { employeeId, companyId, date, leaveId } = req.body;

      const rawStatus = req.body.status; // e.g. "present", "half_day"
    const statusMap = {
      present: "Present",
      double_present: "Double Present",
      absent: "Absent",
      half_day: "Half Day",
      half_day_leave: "Half Day Leave", // Store as distinct leave type
      paid_leave: "Paid Leave",
      unpaid_leave: "Unpaid Leave",
      leave: "Leave",
      sunday: "Sunday",
      week_off: "Week Off",
      holiday: "Holiday",
    };

    const status = statusMap[rawStatus];
    if (!status) {
      return res
        .status(400)
        .json({ message: `Invalid status: ${rawStatus}` });
    }
  
      // 1) Only admin is allowed
      // if (!req.user || !req.user.isAdmin) {
      //   return res.status(403).json({ message: 'Only admin can edit attendance' });
      // }
  
      // 2) Find attendance doc
      const attendance = await Attendance.findOne({ employeeId }).exec();
      if (!attendance) {
        console.log("hello")
        return res.status(404).json({ message: 'Attendance doc not found' });
      }
  
      const targetDate = new Date(date); // ISO date string for that day (yyyy‑MM‑dd)
  
      const year = targetDate.getFullYear();
      const month = targetDate.getMonth() + 1;
  
      const monthDoc = attendance.monthlyAttendance.find(
        (m) => m.year === year && m.month === month
      );
      if (!monthDoc) {
        console.log("hell")
        return res.status(404).json({ message: 'Month attendance not found' });
      }

      const normalize = (d) => {
        const nd = new Date(d);
        nd.setHours(0, 0, 0, 0);
        return nd.getTime();
      };
  
      let record = monthDoc.records.find(
        (r) => normalize(r.date) === normalize(targetDate)
      );

      const validLeaveId = (leaveId && mongoose.Types.ObjectId.isValid(leaveId)) 
  ? leaveId 
  : null;
  
      if (!record) {
        record = {
          date: targetDate,
          status,            // set requested status
          punchIn: null,
          punchOut: null,
          leaveType: (rawStatus === "paid_leave" || rawStatus === "half_day_leave") ? validLeaveId : null,
          remarks: '',
        };
        monthDoc.records.push(record);
      } else {

      if (record.status === 'Absent' && status === 'Absent') {
        return res.json({ success: false, message: 'Already marked absent', record });
      }

      // already Half Day and trying to set Half Day again
    if (record.status === 'Half Day' && status === 'Half Day') {
      return res.json({
        success: false,
        message: 'Already marked half day',
        record,
      });
    }

    // already Week Off and trying to set Week Off again
if (record.status === 'Week Off' && status === 'Week Off') {
  return res.json({
    success: false,
    message: 'Already marked week off',
    record,
  });
}

// already Holiday and trying to set Holiday again
if (record.status === 'Holiday' && status === 'Holiday') {
  return res.json({
    success: false,
    message: 'Already marked holiday',
    record,
  });
}
  
      // 3) Update status
      record.status = status; // "Present" | "Absent" | "Leave" | "Sunday" | "Holiday"
      console.log('Updated status to', record.status);
      record.leaveType = (rawStatus === "paid_leave" || rawStatus === "half_day_leave") ? validLeaveId : null;
}

      if (status === 'Absent') {
        record.punchIn = null;
        record.punchOut = null;
      }
  
      await attendance.save();
      return res.json({ success: true, record });
    } catch (err) {
      console.error('updateAttendanceStatus error', err);
      return res.status(500).json({ message: 'Server error' });
    }
  };

  export const adminPunchInController = async (req, res) => {
    try {
      const { employeeId, companyId, punchedFrom, isoTime } = req.body;
  
      if (!employeeId || !companyId || !isoTime) {
        return res.status(400).json({ message: "employeeId, companyId and isoTime are required" });
      }
  
      // parse provided time (ISO string) to Date
      const customDate = new Date(isoTime);
      if (Number.isNaN(customDate.getTime())) {
        return res.status(400).json({ message: "Invalid isoTime" });
      }
  
      // reuse punchAttendance, but allow overriding 'now'
      const result = await punchAttendance({
        employeeId,
        companyId,
        punchedFrom: punchedFrom || "Web",
        photoUrl: null,
        location: { lat: null, lng: null, address: null },
        overrideNow: customDate,        // NEW field
      });
  
      return res.status(200).json({
        message: "Punched in",
        todayRecord: result.todayRecord,
      });
    } catch (err) {
      console.error("Admin punch‑in error:", err);
      return res.status(500).json({ message: err.message || "Unable to punch attendance" });
    }
  };

  export const adminPunchOutController = async (req, res) => {
    try {
      const { employeeId, companyId, isoTime, punchedFrom } = req.body;
  
      if (!employeeId || !companyId || !isoTime) {
        return res
          .status(400)
          .json({ message: 'employeeId, companyId and isoTime are required' });
      }
  
      const customDate = new Date(isoTime);
      if (Number.isNaN(customDate.getTime())) {
        return res.status(400).json({ message: 'Invalid isoTime' });
      }
  
      const result = await punchAttendance({
        employeeId,
        companyId,
        punchedFrom: punchedFrom || 'Web',
        photoUrl: null,
        location: { lat: null, lng: null, address: null },
        overrideNow: customDate,
      });
  
      // if no punchIn, do not allow punchOut
      if (!result.todayRecord.punchIn) {
        return res
          .status(400)
          .json({ message: 'Punch in does not exist for this date' });
      }
  
      if (!result.todayRecord.punchOut) {
        return res
          .status(500)
          .json({ message: 'Unable to create punch out' });
      }
  
      return res.status(200).json({
        message: 'Punched out',
        todayRecord: result.todayRecord,
      });
    } catch (err) {
      console.error('Admin punch‑out error:', err);
      return res
        .status(500)
        .json({ message: err.message || 'Unable to punch out' });
    }
  };
  

  export const adminDeletePunchInController = async (req, res) => {
    try {
      const { employeeId, companyId, date } = req.body; // ISO date string (day)
      if (!employeeId || !companyId || !date) {
        return res.status(400).json({ message: 'employeeId, companyId and date are required' });
      }
  
      const target = new Date(date);
      const year = target.getFullYear();
      const month = target.getMonth() + 1; // 1–12
      const dayOnly = new Date(year, target.getMonth(), target.getDate());
  
      const attendance = await Attendance.findOne({
        employeeId,
        'monthlyAttendance.companyId': companyId,
      });
      if (!attendance) {
        console.log("hioiu")
        return res.status(404).json({ message: 'Attendance not found' });
      }
  
      const monthDoc = attendance.monthlyAttendance.find(
        m => m.year === year && m.month === month,
      );
      if (!monthDoc) {
        return res.status(404).json({ message: 'Month record not found' });
      }
  
      const rec = monthDoc.records.find(r =>
        new Date(r.date).getTime() === dayOnly.getTime(),
      );
      if (!rec || !rec.punchIn) {
        return res.status(404).json({ message: 'Punch in not found for this date' });
      }
  
      rec.punchIn = null;
  
      // if no punchOut as well, you can optionally mark status Absent
      if (!rec.punchOut) {
        rec.status = 'Absent';
      }
  
      await attendance.save({ validateBeforeSave: false });
      return res.status(200).json({ message: 'Punch in deleted', todayRecord: rec });
    } catch (err) {
      console.error('adminDeletePunchIn error', err);
      return res.status(500).json({ message: err.message || 'Unable to delete punch in' });
    }
  };
  
  export const adminDeletePunchOutController = async (req, res) => {
    try {
      const { employeeId, companyId, date } = req.body;
      if (!employeeId || !companyId || !date) {
        return res.status(400).json({ message: 'employeeId, companyId and date are required' });
      }
  
      const target = new Date(date);
      const year = target.getFullYear();
      const month = target.getMonth() + 1;
      const dayOnly = new Date(year, target.getMonth(), target.getDate());
  
      const attendance = await Attendance.findOne({
        employeeId,
        'monthlyAttendance.companyId': companyId,
      });
      if (!attendance) {
        return res.status(404).json({ message: 'Attendance not found' });
      }
  
      const monthDoc = attendance.monthlyAttendance.find(
        m => m.year === year && m.month === month,
      );
      if (!monthDoc) {
        return res.status(404).json({ message: 'Month record not found' });
      }
  
      const rec = monthDoc.records.find(r =>
        new Date(r.date).getTime() === dayOnly.getTime(),
      );
      if (!rec || !rec.punchOut) {
        return res.status(404).json({ message: 'Punch out not found for this date' });
      }
  
      rec.punchOut = null;
      await attendance.save({ validateBeforeSave: false });
      return res.status(200).json({ message: 'Punch out deleted', todayRecord: rec });
    } catch (err) {
      console.error('adminDeletePunchOut error', err);
      return res.status(500).json({ message: err.message || 'Unable to delete punch out' });
    }
  };

  export async function updateStatusController(req, res, next) {
    try {
      const { employeeId, companyId } = req.params;
      const { date, status } = req.body; // date ISO string, status string
  
      const record = await updateDailyStatus({
        employeeId,
        companyId,
        date,
        status,
      });
  
      return res.json({ success: true, record });
    } catch (err) {
      next(err);
    }
  }
  
  export async function updateRemarksController(req, res, next) {
    try {
      const { employeeId, companyId } = req.params;
      const { date, remarks } = req.body;
  
      const record = await updateDailyRemarks({
        employeeId,
        companyId,
        date,
        remarks,
      });
  
      return res.json({ success: true, record });
    } catch (err) {
      next(err);
    }
  }

  export const upsertMobileAlarm = async (req, res) => {
    try {
      const { employeeId, type, hour, minute, enabled } = req.body;
      console.log("emp id: ",employeeId);
  
      const attendance = await Attendance.findOne({ employeeId }).exec();
      if (!attendance) {
        return res.status(404).json({ message: "Attendance doc not found" });
      }
  
      const idx = attendance.mobileAlarms.findIndex((a) => a.type === type);
      if (idx === -1) {
        attendance.mobileAlarms.push({ type, hour, minute, enabled });
      } else {
        attendance.mobileAlarms[idx].hour = hour;
        attendance.mobileAlarms[idx].minute = minute;
        if (enabled !== undefined) {
          attendance.mobileAlarms[idx].enabled = enabled;
        }
      }
  
      await attendance.save();
      return res.json({ success: true, mobileAlarms: attendance.mobileAlarms });
    } catch (err) {
      console.error("upsertMobileAlarm error", err);
      return res.status(500).json({ message: "Server error" });
    }
  };

  export const getMobileAlarmsController = async (req, res) => {
    try {
      const { employeeId } = req.params;
      if (!employeeId) {
        return res.status(400).json({ message: 'employeeId is required' });
      }
  
      const alarms = await getMobileAlarms({ employeeId });
      if (!alarms) {
        return res.status(404).json({ message: 'Attendance doc not found' });
      }
  
      return res.json({ success: true, mobileAlarms: alarms });
    } catch (err) {
      console.error('getMobileAlarms error', err);
      return res.status(500).json({ message: 'Server error' });
    }
  };

  export const getEmployeeAttendance = async (req, res) => {
    try {
      const { employeeId } = req.params;

      const employee = await Employee.findById(employeeId);
      if (!employee) return res.status(404).json({ message: "Employee not found" });

      const record = await Attendance.findOne({ employeeId })
      .populate({
        path: 'workTimings.fixed.days.selectedShift',
        model: 'Shift'
      })
      .populate({
        path: 'workTimings.flexibles.days.selectedShift',
        model: 'Shift'
      });
      if (!record)
        return res.json({ scheduleType: "Not Set", attendance: null });
      res.json({
        scheduleType: record.workTimings?.scheduleType || "Not Set",
        attendance: record,
      });
    } catch (err) {
      console.error("Error in getEmployeeAttendance", err);
      res.status(500).json({ message: "Failed to load employee attendance" });
    }
  };

  export const getWorkScheduleController = async (req, res) => {
    try {
        const { employeeId } = req.params;
        const schedule = await getEmployeeWorkSchedule(employeeId);
        res.status(200).json({ success: true, schedule });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};