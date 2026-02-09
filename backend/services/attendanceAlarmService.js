// services/attendanceAlarmService.js
import Attendance from '../models/attendanceModel.js';

export async function getMobileAlarms({ employeeId }) {
  const attendance = await Attendance.findOne({ employeeId }).lean().exec();
  if (!attendance) return null;
//   console.log("attendance.mobileAlarms", attendance.mobileAlarms)
  return attendance.mobileAlarms || [];
}
