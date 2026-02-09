import Attendance from "../models/attendanceModel.js"; // Adjust path

export const calculatePayableDays = async (employeeId, companyId, year, month) => {
  const attendance = await Attendance.findOne({
    employeeId,
    "monthlyAttendance.companyId": companyId,
  }).lean();

  if (!attendance) return { payableDays: 0, weekOffs: 0, totalDaysInMonth: 0 };

  const monthDoc = attendance.monthlyAttendance.find(
    (m) => m.year === year && m.month === month
  );

  if (!monthDoc || !monthDoc.records) return { payableDays: 0, weekOffs: 0, totalDaysInMonth: 0 };

  let paidDaysCount = 0;
  let weekOffCount = 0;

  monthDoc.records.forEach((record) => {
    const status = record.status;
    // Count Week Offs specifically for the UI split
    if (["Week Off", "Sunday"].includes(status)) {
      weekOffCount++;
      paidDaysCount += 1;
    } else if (status === "Present" || status === "Holiday") {
      paidDaysCount += 1;
    } else if (status === "Half Day") {
      paidDaysCount += 0.5;
    }
  });

  const totalDaysInMonth = new Date(year, month, 0).getDate();

  return {
    payableDays: paidDaysCount, // Total days used for calculation
    weekOffs: weekOffCount,
    totalDaysInMonth,
    lossOfPay: totalDaysInMonth - paidDaysCount,
    records: monthDoc.records
  };
};