import mongoose from "mongoose";
import { format } from 'date-fns-tz';
import Attendance from "../models/attendanceModel.js";
import Anomaly from "../models/anomalyModel.js";
import User from "../models/userModel.js"
import dayjs from 'dayjs';
import Employee from "../models/employeeModel.js";
import Branch from "../models/branchModel.js";
import Company from "../models/companyModel.js";
import { calculateDistance } from "../utils/geoUtils.js";

const ObjectId = mongoose.Types.ObjectId;

// helper: find (or create) monthlyAttendance doc for user+company+year+month
async function findMonthlyDoc({ employeeId, companyId, year, month }) {
  let doc = await Attendance.findOne({
    employeeId: new ObjectId(employeeId),
    companyId: new ObjectId(companyId),
    "monthlyAttendance.year": year,
    "monthlyAttendance.month": month,
  });

  if (!doc) {
    // create root Attendance if missing
    doc = await Attendance.create({
      employeeId: new ObjectId(employeeId),
      companyId: new ObjectId(companyId),
      monthlyAttendance: [],
    });
  }

  // find month entry or create it
  let monthEntry = doc.monthlyAttendance.find(
    (m) => m.year === year && m.month === month
  );
  if (!monthEntry) {
    monthEntry = {
      year,
      month,
      records: [],
    };
    doc.monthlyAttendance.push(monthEntry);
  }

  return { doc, monthEntry };
}



// helper: get or create daily record inside monthEntry
function getOrCreateDailyRecord(monthEntry, jsDate) {
  const startOfDay = new Date(jsDate);
  startOfDay.setHours(0, 0, 0, 0);

  let record = monthEntry.records.find(
    (r) => new Date(r.date).getTime() === startOfDay.getTime()
  );

  if (!record) {
    record = {
      date: startOfDay,
      status: "Absent",
      punchIn: null,
      punchOut: null,
      remarks: "",
    };
    monthEntry.records.push(record);
  }

  return record;
}

function parseTimeForToday(timeStr) {
  if (!timeStr) return null;
  
  // timeStr example: "10:00 AM"
  const [timePart, modifier] = timeStr.split(' ');
  let [hours, minutes] = timePart.split(':').map(Number);

  if (modifier === 'PM' && hours !== 12) hours += 12;
  if (modifier === 'AM' && hours === 12) hours = 0;

  const now = new Date();
  // Create a Date object for TODAY with the shift's hours and minutes
  return new Date(now.getFullYear(), now.getMonth(), now.getDate(), hours, minutes, 0, 0);
}

// Get today's day key "Mon", "Tue", ... in same format as workTimings
function getTodayDayKey() {
  const days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
  return days[new Date().getDay()];
}

function getTodayShift(attendanceDoc) {
  if (!attendanceDoc.workTimings) return null;

  const { scheduleType, fixed, flexibles } = attendanceDoc.workTimings;
  const now = new Date();
  
  // 1. Handle FIXED Schedule
  if (scheduleType === "Fixed" && fixed?.days) {
    const todayKey = new Intl.DateTimeFormat('en-US', { weekday: 'short' }).format(now); // "Mon", "Tue"
    const dayConfig = fixed.days.find(d => d.day === todayKey);
    
    if (!dayConfig || dayConfig.isWeekoff || !dayConfig.selectedShift) return null;
    
    // selectedShift is now a populated object from the Shift model
    return dayConfig.selectedShift; 
  }

  // 2. Handle FLEXIBLE Schedule
  if (scheduleType === "Flexible" && flexibles) {
    const currentMonth = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
    const todayISO = now.toISOString().split('T')[0]; // "2026-01-10"
    
    const monthConfig = flexibles.find(m => m.month === currentMonth);
    if (!monthConfig) return null;

    const dayConfig = monthConfig.days.find(d => d.day === todayISO);
    if (!dayConfig || dayConfig.isWeekoff || !dayConfig.selectedShift) return null;

    return dayConfig.selectedShift;
  }

  return null;
}

export const punchAttendance = async ({
  employeeId,
  companyId,
  punchedFrom,
  deviceId,         // "Mobile" / "Web" / "Biometric" / "Kiosk"
  photoUrl,            // selfie url
  location,  
  overrideNow,           // { lat, lng, address }
}) => {
  console.log('🎯 punchAttendance STARTED', { employeeId, companyId, date: new Date().toISOString() });
  const now = overrideNow || new Date();
  
  // const now = new Date();
  const year = now.getFullYear();
  const month = now.getMonth() + 1;          // 1..12
  const dateOnly = new Date(year, now.getMonth(), now.getDate());
  console.log('📅 Today:', dateOnly.toISOString());


  // 1. Validate employee + company mapping
  console.log('🔍 Finding employee...');
  const employee = await Employee.findOne({
    _id: employeeId,
    companyId: companyId,
  });

  if (!employee) {
    throw new Error("Employee not found in this company");
  }
  console.log('✅ Employee found');

  const company = await Company.findById(companyId);
  if (!company) {
    throw new Error("Company not found");
  }

  const user = await User.findOne({ 
    "memberships.companyId": companyId, 
    _id: employee.userId // Assuming employee model links to user model via userId
  });

  // ==========================================
  // FRAUD DETECTION START
  // ==========================================

  // A. BUDDY PUNCHING CHECK (Device Binding)
  if (punchedFrom === "Mobile" && deviceId && user) {
    // If user has a registered device and it doesn't match the incoming one
    if (user.deviceId && user.deviceId !== deviceId) {
      console.warn(`🚩 Buddy Punching detected for ${employee.basic.fullName}`);
      
      await Anomaly.create({
        companyId,
        userId: user._id,
        employeeName: employee.basic.fullName,
        companyName: company.name,
        type: 'Buddy Punching',
        severity: 'high',
        status: 'investigating',
        description: `Device Mismatch: Registered to ${user.deviceModel || 'another device'} but tried to punch from a new device.`,
        metadata: {
          deviceId: deviceId,
          providedLocation: location
        }
      });
      // Optional: throw new Error("Unauthorized device detected.");
    }
  }

  // 2. Get or create Attendance config doc
  console.log('📋 Finding attendance doc...');
  let attendance = await Attendance.findOne({ employeeId })
  .populate('workTimings.fixed.days.selectedShift') // This is critical
        .populate('workTimings.flexibles.days.selectedShift');

        if(attendance){
           const attendanceMode = attendance.attendanceModes?.smartphone;
  
  if (attendanceMode?.markAttendanceFrom === "Office") {
    // 1. Get employee's assigned branch
    const branchId = attendanceMode.branchId || employee.basic.branches[0]; // Assuming first assigned branch
    const branch = await Branch.findById(branchId);

    if (!branch || !branch.location?.coordinates) {
      throw new Error("Office location not configured for this branch.");
    }

    // if (branch && branch.location?.coordinates) {
      const [branchLng, branchLat] = branch.location.coordinates;
      const allowedRadius = branch.radius || 100; // default to 100m if not set

      if (!location.lat || !location.lng) {
        throw new Error("Location coordinates are required to punch from office.");
      }

      const actualDistance = calculateDistance(
        location.lat, 
        location.lng, 
        branchLat, 
        branchLng
      );

      // 2. Check if distance exceeds radius
      if (actualDistance > allowedRadius) {
        console.warn(`🚩 GPS Anomaly detected for ${employee.basic.fullName}`);
        
        await Anomaly.create({
          companyId,
          userId: employeeId, // or employee.userId if linking to auth user
          employeeName: employee.basic.fullName,
          companyName: company.name,
          type: 'GPS Spoofing',
          severity: 'high',
          status: 'investigating',
          description: `Location mismatch: Punched from ${Math.round(actualDistance)}m away. Allowed radius is ${allowedRadius}m.`,
          metadata: {
            providedLocation: { lat: location.lat, lng: location.lng },
            actualOfficeLocation: { lat: branchLat, lng: branchLng },
            ipAddress: "" // Can be captured from req if needed
          }
        });
        throw new Error(`Out of range. You are ${Math.round(actualDistance)}m away from the office premises.`);
        // Optional: Throw error if you want to block the punch entirely
        // throw new Error(`You are outside the allowed office radius (${Math.round(actualDistance)}m away)`);
      }
  }
        }

  if (!attendance) {
    console.log('➕ Creating new attendance doc');
    attendance = new Attendance({
      employeeId,
      workTimings: null,
      attendanceModes: {},
      automationRules: {},
      staffCanViewOwnAttendance: false,
      monthlyAttendance: [],
    });
  }
  console.log('📊 Attendance doc ready, monthlyAttendance length:', attendance.monthlyAttendance.length);
 
  const getPunchInStatus = (currentTime, startTime) => {
    if (!startTime) return "On Time";
    // Compare strictly: 10:00:01 is greater than 10:00:00
    return currentTime > startTime ? "Late" : "On Time";
  };

    // Get today's shift (if any)
const todayShift = getTodayShift(attendance);
let shiftStart = null;
let shiftEnd = null;
let shiftEndGrace = null;

// C. UNUSUAL HOURS CHECK
if (todayShift) {
  const punchTime = dayjs(now);
  const shiftStart = dayjs(parseTimeForToday(todayShift.startTime));
  const shiftEnd = dayjs(parseTimeForToday(todayShift.endTime));
  
  // Define "Unusual" as 4 hours outside shift boundaries
  const isTooEarly = punchTime.isBefore(shiftStart.subtract(4, 'hour'));
  const isTooLate = punchTime.isAfter(shiftEnd.add(4, 'hour'));

  if (shiftEnd) {
    shiftEndGrace = new Date(shiftEnd.getTime() + 30 * 60 * 1000); // +30 mins
  }

  if (isTooEarly || isTooLate || todayShift.isWeekoff) {
    const reason = todayShift.isWeekoff 
      ? "Punch on Week-off/Holiday" 
      : `Punch at irregular time (${punchTime.format('hh:mm A')})`;

    await Anomaly.create({
      companyId,
      userId: user?._id || employeeId,
      employeeName: employee.basic.fullName,
      companyName: company.name,
      type: 'Unusual Hours',
      severity: 'medium',
      status: 'investigating',
      description: `${reason}. Assigned shift: ${todayShift.startTime} - ${todayShift.endTime}`,
      metadata: {
        providedLocation: location,
        deviceId: deviceId
      }
    });
  }
}

  // 3. Find or create month object in monthlyAttendance - FIXED (single logic)
  let monthIndex = attendance.monthlyAttendance.findIndex(m => m.year === year && m.month === month);
  if (monthIndex === -1) {
    console.log('📅 Creating Dec 2025 month');
    const newMonthDoc = {
      user: employeeId,
      companyId: companyId,
      year,
      month,
      records: [],
    };
    attendance.monthlyAttendance.push(newMonthDoc);
    monthIndex = attendance.monthlyAttendance.length - 1;
  }
  const monthDoc = attendance.monthlyAttendance[monthIndex];
  console.log('📋 Month doc records length:', monthDoc.records.length);

  // 4. Find today's record index
let recordIndex = monthDoc.records.findIndex(r =>
  new Date(r.date.getFullYear(), r.date.getMonth(), r.date.getDate()).getTime() ===
  dateOnly.getTime()
);

// If not found → create
if (recordIndex === -1) {
  console.log("➕ Creating today record");

  const status = getPunchInStatus(now, shiftStart);

  monthDoc.records.push({
    date: dateOnly,
    status: "Present",
    // new record
    punchIn: {
      time: now,
      status: status,
      punchedInFrom: punchedFrom,
      punchInPhoto: photoUrl || null,
      location: {
        lat: location.lat || null,
        lng: location.lng || null,
        address: location.address || null,
      },
    },
    punchOut: null,
    remarks: "",
  });

  recordIndex = monthDoc.records.length - 1;
  console.log("Created new today record:", monthDoc.records[recordIndex]);

} else {
  console.log("🔍 Found existing today record");

  const todayRecord = monthDoc.records[recordIndex];
  
if (todayRecord && todayRecord.punchIn && !todayRecord.punchOut) {
  const lastPunchTime = dayjs(todayRecord.punchIn.time);
  const currentTime = dayjs(now);
  const secondsDifference = currentTime.diff(lastPunchTime, 'second');

  // Flag if user tries to punch out within 120 seconds (2 minutes) of punching in
  if (secondsDifference < 120) {
    console.warn(`🚩 Rapid Punching detected for ${employee.basic.fullName}`);

    await Anomaly.create({
      companyId,
      userId: user?._id || employeeId,
      employeeName: employee.basic.fullName,
      companyName: company.name,
      type: 'Rapid Punches',
      severity: 'medium',
      status: 'investigating',
      description: `Potential time theft: Punch out attempted only ${secondsDifference} seconds after punch in.`,
      metadata: {
        deviceId: deviceId,
        providedLocation: location
      }
    });
  }
}
  // Punch In / Punch Out logic
  if (!todayRecord.punchIn) {
    
    todayRecord.punchIn = {
      time: now,
      status: getPunchInStatus(now, shiftStart),
      punchedInFrom: punchedFrom,
      punchInPhoto: photoUrl || null,
      location: {
        lat: location.lat || null,
        lng: location.lng || null,
        address: location.address || null,
      },
    };
    todayRecord.status = "Present";
  } else if (!todayRecord.punchOut) {
    const punchOutStatus = (() => {
      if (!shiftEnd) return "Over Time";        // fallback
      if (now < shiftEnd) return "Early";       // before 7:00 / 5:00
      if (shiftEndGrace && now <= shiftEndGrace) return "Normal"; // 7:00–7:30 window
      return "Over Time";                       // after 7:30 / 5:30
    })();
    
    todayRecord.punchOut = {
      time: now,
      status: punchOutStatus,
      punchedOutFrom: punchedFrom,
      punchOutPhoto: photoUrl || null,
      location: {
        lat: location.lat || null,
        lng: location.lng || null,
        address: location.address || null,
      },
    };
  } else {
    console.log('✅ Already punched in and out for today');
  return { 
    attendance, 
    todayRecord,
    status: 'completed'  // Add status for frontend
  };
  }
}

const todayRecord = monthDoc.records[recordIndex];
console.log('💾 Saving FULL monthlyAttendance...');
await attendance.save({ 
  validateBeforeSave: false,
  strict: false 
});
console.log('✅ SAVED SUCCESSFULLY');
  return { attendance, todayRecord };
};


export const getTodayStatus = async ({ employeeId, companyId }) => {
  const now = new Date();
  const year = now.getFullYear();
  const month = now.getMonth() + 1;
  
  const attendance = await Attendance.findOne({ employeeId });
  if (!attendance) return "none";

  const monthDoc = attendance.monthlyAttendance.find(m => m.year === year && m.month === month);
  if (!monthDoc) return "none";

  const todayRecord = monthDoc.records.find(r => 
    new Date(r.date.getFullYear(), r.date.getMonth(), r.date.getDate()).getTime() === 
    new Date(year, now.getMonth(), now.getDate()).getTime()
  );

  if (!todayRecord) return "none";
  if (todayRecord.punchIn && !todayRecord.punchOut) return "in";
  if (todayRecord.punchOut) return "out";
  return "none";
};

export const getMonthlyAttendance = async ({
  employeeId,
  companyId,
  year,
  month,
}) => {
  const attendance = await Attendance.findOne({
    employeeId,
    'monthlyAttendance.companyId': companyId,
  }).lean();
  if (!attendance) {
    return null; // frontend can treat as all "none"
  }

  const monthDoc = attendance.monthlyAttendance.find(
    (m) => m.year === year && m.month === month && String(m.companyId) === String(companyId)
  );
  if (!monthDoc) {
    return { records: [] };
  }

  return {
    user: monthDoc.user,
    companyId: monthDoc.companyId,
    year: monthDoc.year,
    month: monthDoc.month,
    records: monthDoc.records,
  };
};


export const getCompanyDailyAttendanceStats = async (companyId, branchId) => {
  // console.log('📊 getCompanyDailyAttendanceStats for:', companyId);
  
  try {
    // IST Today
    const now = new Date();
    const today = new Date(now.toLocaleString("en-US", { timeZone: 'Asia/Kolkata' }));
    const todayStart = new Date(today.getFullYear(), today.getMonth(), today.getDate());
    todayStart.setHours(0, 0, 0, 0);
    const todayEnd = new Date(todayStart);
    todayEnd.setHours(23, 59, 59, 999);

    // console.log('📅 Today IST:', todayStart.toISOString().split('T')[0]);

    // 1. Company users → phone numbers → employees
    const company = await Company.findById(companyId)
      .populate('users', '_id phoneNumber')
      .lean();
    
    const userPhoneNumbers = company?.users?.map(u => u.phoneNumber).filter(Boolean) || [];
    // console.log('👥 Users found:', userPhoneNumbers.length);

    let employeeQuery = {
      'basic.phone': { $in: userPhoneNumbers }
    };

    // --- NEW FILTER LOGIC ---
    if (branchId && branchId !== 'null' && branchId !== 'undefined' && branchId !== 'ALL') {
      employeeQuery['basic.branches'] = new mongoose.Types.ObjectId(branchId);
    }

    const employees = await Employee.find(employeeQuery)
      .select('_id basic.fullName basic.phone employment.employeeId')
      .lean();

    const employeeIds = employees.map(emp => emp._id);
    // console.log('👷 Employees found:', employees.length);  // ✅ totalStaff

    if (employeeIds.length === 0) {
      return { inCount: 0, outCount: 0, noPunchInCount: 0, totalStaff: 0 };
    }

    // 2. TODAY's attendance records
    const todayAttendance = await Attendance.find({
      'employeeId': { $in: employeeIds },
      'monthlyAttendance.records.date': {
        $gte: todayStart,
        $lt: todayEnd
      }
    })
      .select('employeeId monthlyAttendance.records')
      .lean();

    // console.log('📋 Today attendance records:', todayAttendance.length);

    // 3. No PunchIn logic (employees WITH records but no punch today)
    const employeesWithRecords = new Set();
    const employeeStats = {};

    todayAttendance.forEach(att => {
      const empId = att.employeeId.toString();
      employeesWithRecords.add(empId);
      
      att.monthlyAttendance?.forEach(month => {
        month.records?.forEach(record => {
          const recordDate = new Date(record.date);
          if (recordDate >= todayStart && recordDate < todayEnd) {
            if (!employeeStats[empId]) {
              employeeStats[empId] = { hasPunchIn: false, hasPunchOut: false };
            }
            
            if (record.punchIn) employeeStats[empId].hasPunchIn = true;
            if (record.punchOut) employeeStats[empId].hasPunchOut = true;
          }
        });
      });
    });

    // 4. Calculate stats
    let inCount = 0, outCount = 0;
    
    Object.values(employeeStats).forEach(stats => {
      if (stats.hasPunchIn) inCount++;
      if (stats.hasPunchOut) outCount++;
    });

    const noPunchInTodayCount = employees.length - inCount;

    const totalStaff = employees.length;  // ✅ Total employeeIds fetched

    const stats = { 
      inCount, 
      outCount, 
      noPunchInCount: noPunchInTodayCount,
      totalStaff 
    };

    // console.log('📊 Final stats:', stats);
    return stats;

  } catch (error) {
    console.error('❌ Attendance stats error:', error);
    throw new Error(`Attendance stats failed: ${error.message}`);
  }
};


export const getCompanyLiveAttendanceList = async (companyId, branchId) => {
  // IST today range
  const now = new Date();
  const today = new Date(now.toLocaleString('en-US', { timeZone: 'Asia/Kolkata' }));
  const start = new Date(today.getFullYear(), today.getMonth(), today.getDate(), 0, 0, 0, 0);
  const end   = new Date(today.getFullYear(), today.getMonth(), today.getDate(), 23, 59, 59, 999);

  // company users → employees
  const company = await Company.findById(companyId)
    .populate('users', '_id phoneNumber')
    .lean();

  const phones =
    (company && company.users
      ? company.users.map(u => u.phoneNumber).filter(Boolean)
      : []) || [];

      let employeeQuery = { 'basic.phone': { $in: phones } };

  // ADD BRANCH FILTER HERE
  if (branchId && branchId !== 'null' && branchId !== 'undefined') {
    employeeQuery['basic.branches'] = new mongoose.Types.ObjectId(branchId);
  }

  const employees = await Employee.find(employeeQuery)
    .select('_id basic.fullName basic.phone employment.employeeId')
    .lean();

  const employeeIds = employees.map(e => e._id);
  if (!employeeIds.length) return [];

  // all attendance docs for these employees which have a record today
  const attendanceDocs = await Attendance.find({
    employeeId: { $in: employeeIds },
    'monthlyAttendance.records.date': { $gte: start, $lt: end },
  })
    .select('employeeId monthlyAttendance.records')
    .lean();

  const result = [];

  employees.forEach(emp => {
    const empIdStr = emp._id.toString();
    const attDoc = attendanceDocs.find(doc => doc.employeeId.toString() === empIdStr);

    let todayRecord = null;

    if (attDoc) {
      for (const month of attDoc.monthlyAttendance || []) {
        for (const rec of month.records || []) {
          const d = new Date(rec.date);
          if (d >= start && d < end) {
            todayRecord = rec;
            break;
          }
        }
        if (todayRecord) break;
      }
    }

    let status = 'no_punch_in';
    let dbStatus = todayRecord && todayRecord.status ? todayRecord.status : 'Absent';
    let inTime = null;
    let inTimeIst = null;       // formatted IST string
    let hoursWorked = null;
    let punchInAddress = null;
    let punchInPhoto = null;

    let punchOutTimeIst = null;
let punchOutAddress = null;
let punchOutPhoto = null;

    if (todayRecord) {
      const hasIn = !!todayRecord.punchIn;
      const hasOut = !!todayRecord.punchOut;

      if (hasIn) {
        const utcDate = new Date(todayRecord.punchIn.time);

        // convert to IST and format as "hh:mm a"
        const istDate = new Date(
          utcDate.toLocaleString('en-US', { timeZone: 'Asia/Kolkata' })
        );
        const hours = istDate.getHours();
        const minutes = istDate.getMinutes();
        const h12 = ((hours + 11) % 12) + 1;
        const ampm = hours >= 12 ? 'PM' : 'AM';
        const mm = minutes.toString().padStart(2, '0');

        inTime = utcDate;
        inTimeIst = `${h12}:${mm} ${ampm}`;

        punchInAddress = todayRecord.punchIn.location?.address || null;
        punchInPhoto = todayRecord.punchIn.punchInPhoto || null;
      }

      if (hasOut) {
        const utcOut = new Date(todayRecord.punchOut.time);
        const istOut = new Date(
          utcOut.toLocaleString('en-US', { timeZone: 'Asia/Kolkata' })
        );
        const outHours = istOut.getHours();
        const outMinutes = istOut.getMinutes();
        const outH12 = ((outHours + 11) % 12) + 1;
        const outAmpm = outHours >= 12 ? 'PM' : 'AM';
        const outMM = outMinutes.toString().padStart(2, '0');
    
        punchOutTimeIst = `${outH12}:${outMM} ${outAmpm}`;
        punchOutAddress = todayRecord.punchOut.location?.address || null;
        punchOutPhoto = todayRecord.punchOut.punchOutPhoto || null;
      }

      if (hasIn && !hasOut) {
        status = 'in';
      } else if (hasIn && hasOut) {
        status = 'out';
      } else {
        status = 'no_punch_in';
      }

      if (hasIn && hasOut) {
        const diffMs =
          new Date(todayRecord.punchOut.time).getTime() -
          new Date(todayRecord.punchIn.time).getTime();
        const hours = diffMs / (1000 * 60 * 60);
        hoursWorked = hours.toFixed(2);
      }

      if (todayRecord.punchIn && todayRecord.punchIn.status === 'Late') {
        status = 'late';
      }
      if (todayRecord.punchOut && todayRecord.punchOut.status === 'Early') {
        status = 'early_leaving';
      }
    }

    const hwNum = hoursWorked ? parseFloat(hoursWorked) : null;

const isHalfDay = hwNum !== null && hwNum > 0 && hwNum < 4.5;
const isOvertime = hwNum !== null && hwNum > 10;

    result.push({
      employeeId: empIdStr,
      name: emp.basic.fullName,
      phoneNumber: emp.basic.phone,
      empCode: emp.employment.employeeId,
      status,
      attendanceStatus: dbStatus,
      inTime,
      inTimeIst,
      hoursWorked,
      punchInAddress,
      punchInPhoto,
      punchOutTimeIst,
  punchOutAddress,
  punchOutPhoto,
      isHalfDay,
  isOvertime,
    });
  });

  return result;
};

export const getCompanyDailyAttendanceList = async ({
  companyId,
  branchId,
  start,
  end,
}) => {
  // company users → employees
  const company = await Company.findById(companyId)
    .populate('users', '_id phoneNumber')
    .lean();

  const phones =
    (company && company.users
      ? company.users.map(u => u.phoneNumber).filter(Boolean)
      : []) || [];

      let employeeQuery = { 'basic.phone': { $in: phones } };

  // ADD BRANCH FILTER HERE
  if (branchId && branchId !== 'null' && branchId !== 'undefined') {
    employeeQuery['basic.branches'] = new mongoose.Types.ObjectId(branchId);
  }

  const employees = await Employee.find(employeeQuery)
    .select('_id basic.fullName basic.phone employment.employeeId')
    .lean();

  const employeeIds = employees.map(e => e._id);
  if (!employeeIds.length) return [];

  // all attendance docs for these employees which have a record in [start, end)
  const attendanceDocs = await Attendance.find({
    employeeId: { $in: employeeIds },
    'monthlyAttendance.records.date': { $gte: start, $lt: end },
  })
    .select('employeeId monthlyAttendance.records')
    .lean();

  const result = [];

  employees.forEach(emp => {
    const empIdStr = emp._id.toString();
    const attDoc = attendanceDocs.find(
      doc => doc.employeeId.toString() === empIdStr,
    );

    let dayRecord = null;

    if (attDoc) {
      for (const month of attDoc.monthlyAttendance || []) {
        for (const rec of month.records || []) {
          const d = new Date(rec.date);
          if (d >= start && d < end) {
            dayRecord = rec;
            break;
          }
        }
        if (dayRecord) break;
      }
    }

    let status = 'no_punch_in';
    let dbStatus = dayRecord && dayRecord.status ? dayRecord.status : 'Absent';
    let inTime = null;
    let inTimeIst = null;
    let hoursWorked = null;
    let punchInAddress = null;
    let punchInPhoto = null;

    let punchOutTimeIst = null;
    let punchOutAddress = null;
    let punchOutPhoto = null;

    if (dayRecord) {
      const hasIn = !!dayRecord.punchIn;
      const hasOut = !!dayRecord.punchOut;

      if (hasIn) {
        const utcDate = new Date(dayRecord.punchIn.time);
        const istDate = new Date(
          utcDate.toLocaleString('en-US', { timeZone: 'Asia/Kolkata' }),
        );
        const hours = istDate.getHours();
        const minutes = istDate.getMinutes();
        const h12 = ((hours + 11) % 12) + 1;
        const ampm = hours >= 12 ? 'PM' : 'AM';
        const mm = minutes.toString().padStart(2, '0');

        inTime = utcDate;
        inTimeIst = `${h12}:${mm} ${ampm}`;

        punchInAddress = dayRecord.punchIn.location?.address || null;
        punchInPhoto = dayRecord.punchIn.punchInPhoto || null;
      }

      if (hasOut) {
        const utcOut = new Date(dayRecord.punchOut.time);
        const istOut = new Date(
          utcOut.toLocaleString('en-US', { timeZone: 'Asia/Kolkata' }),
        );
        const outHours = istOut.getHours();
        const outMinutes = istOut.getMinutes();
        const outH12 = ((outHours + 11) % 12) + 1;
        const outAmpm = outHours >= 12 ? 'PM' : 'AM';
        const outMM = outMinutes.toString().padStart(2, '0');

        punchOutTimeIst = `${outH12}:${outMM} ${outAmpm}`;
        punchOutAddress = dayRecord.punchOut.location?.address || null;
        punchOutPhoto = dayRecord.punchOut.punchOutPhoto || null;
      }

      if (hasIn && !hasOut) {
        status = 'in';
      } else if (hasIn && hasOut) {
        status = 'out';
      } else {
        status = 'no_punch_in';
      }

      if (hasIn && hasOut) {
        const diffMs =
          new Date(dayRecord.punchOut.time).getTime() -
          new Date(dayRecord.punchIn.time).getTime();
        const hours = diffMs / (1000 * 60 * 60);
        hoursWorked = hours.toFixed(2);
      }

      if (dayRecord.punchIn && dayRecord.punchIn.status === 'Late') {
        status = 'late';
      }
      if (dayRecord.punchOut && dayRecord.punchOut.status === 'Early') {
        status = 'early_leaving';
      }
    }

    const hwNum = hoursWorked ? parseFloat(hoursWorked) : null;
    const isHalfDay = hwNum !== null && hwNum > 0 && hwNum < 4.5;
    const isOvertime = hwNum !== null && hwNum > 10;

    result.push({
      employeeId: empIdStr,
      name: emp.basic.fullName,
      phoneNumber: emp.basic.phone,
      empCode: emp.employment.employeeId,
      status,
      attendanceStatus: dbStatus,
      inTime,
      inTimeIst,
      hoursWorked,
      punchInAddress,
      punchInPhoto,
      punchOutTimeIst,
      punchOutAddress,
      punchOutPhoto,
      isHalfDay,
      isOvertime,
    });
  });

  return result;
};

export async function updateDailyStatus({
  employeeId,
  companyId,
  date,
  status,
}) {
  const jsDate = new Date(date);
  const year = jsDate.getFullYear();
  const month = jsDate.getMonth() + 1;

  const { doc, monthEntry } = await findMonthlyDoc({
    employeeId,
    companyId,
    year,
    month,
  });

  const record = getOrCreateDailyRecord(monthEntry, jsDate);
  record.status = status; // e.g. "Present", "Absent", "Half Day", ...

  await doc.save();
  return record;
}

// -------------------- REMARKS --------------------

export async function updateDailyRemarks({
  employeeId,
  companyId,
  date,
  remarks,
}) {
  const jsDate = new Date(date);
  const year = jsDate.getFullYear();
  const month = jsDate.getMonth() + 1;

  const { doc, monthEntry } = await findMonthlyDoc({
    employeeId,
    companyId,
    year,
    month,
  });

  const record = getOrCreateDailyRecord(monthEntry, jsDate);
  record.remarks = remarks ?? "";

  await doc.save();
  return record;
}

export const getEmployeeWorkSchedule = async (employeeId) => {
  const attendanceDoc = await Attendance.findOne({ employeeId }).select('workTimings');
  if (!attendanceDoc) return null;
  return attendanceDoc.workTimings;
};