import cron from 'node-cron';
import Attendance from '../models/attendanceModel.js';
import Employee from '../models/employeeModel.js';

export const initializeDailyStatus = async () => {
    try {
        const now = new Date();
        const currentYear = now.getFullYear();
        const currentMonth = now.getMonth() + 1; // 1 = Jan, 2 = Feb...

        // Handle Timezone Offset to get correct Local Date String (e.g., IST)
        const offset = now.getTimezoneOffset();
        const localNow = new Date(now.getTime() - (offset * 60 * 1000));
        const todayStr = localNow.toISOString().split('T')[0];

        // Create a UTC normalized date for the "date" field (00:00:00)
        const startOfToday = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));

        console.log(`[Cron] Initializing records for: ${todayStr}`);

        // Fetch all attendance documents
        const attendanceDocs = await Attendance.find({})
            .populate('workTimings.fixed.days.selectedShift workTimings.flexibles.days.selectedShift');

        let totalUpdated = 0;
        let totalCreated = 0;
        let monthsCreated = 0;

        for (const doc of attendanceDocs) {
            // 1. Find or Initialize the Monthly Container (e.g., for Feb 2026)
            let monthDoc = doc.monthlyAttendance.find(m => m.year === currentYear && m.month === currentMonth);
            console.log("doc: ",doc)

            if (!monthDoc) {
                let finalCompanyId;
                let finalUserId;

                const employeeData = await Employee.findById(doc.employeeId).select('companyId user');
                if (!employeeData) {
                    console.error(`[Cron] Employee document not found for ID: ${doc.employeeId}`);
                    continue;
                }

                finalUserId = employeeData.user;

                if (!finalUserId) {
                    console.error(`[Cron] Missing data for User: ${finalUserId}`);
                    continue; 
                }

                if (doc.monthlyAttendance.length > 0) {
                    finalCompanyId = doc.monthlyAttendance[0].companyId;
                } else {
                    // 2. FALLBACK: Fetch from Employee model since array is empty
                    const employee = await Employee.findById(doc.employeeId).select('companyId');
                    finalCompanyId = employee?.companyId;
                }

                // 3. Safety Check: If still null, skip to avoid schema validation error
                if (!finalCompanyId) {
                    console.error(`[Cron] Could not find companyId for Employee: ${doc.employeeId}`);
                    continue; 
                }

                const newMonth = {
                    user: finalUserId, // Ensuring reference is maintained
                    companyId: finalCompanyId,
                    year: currentYear,
                    month: currentMonth,
                    records: []
                };
                doc.monthlyAttendance.push(newMonth);
                // Reference the newly pushed month
                monthDoc = doc.monthlyAttendance[doc.monthlyAttendance.length - 1];
                monthsCreated++;
            }

            // 2. Find or Create Today's Record inside that Month
            let recordIndex = monthDoc.records.findIndex(r => {
                const rDateLocal = new Date(r.date.getTime() - (offset * 60 * 1000));
                return rDateLocal.toISOString().split('T')[0] === todayStr;
            });

            // 3. Determine correct status for today
            const shiftConfig = await getShiftConfigForDate(doc, now);
            const isWeekoff = shiftConfig?.isWeekoff ?? false;
            
            let targetStatus = "Absent";
            if (isWeekoff) {
                const dayName = new Intl.DateTimeFormat('en-US', { weekday: 'long' }).format(now);
                targetStatus = (dayName === 'Sunday') ? "Sunday" : "Week Off";
            }

            if (recordIndex === -1) {
                // Record doesn't exist: Create it
                monthDoc.records.push({
                    date: startOfToday,
                    status: targetStatus,
                    remarks: `Auto-initialized: ${targetStatus}`,
                    punchIn: null,
                    punchOut: null
                });
                totalCreated++;
            } else {
                // Record exists: Update it ONLY if they haven't punched in yet
                const record = monthDoc.records[recordIndex];
                if (!record.punchIn) {
                    record.status = targetStatus;
                    // record.remarks = `Status confirmed as ${targetStatus} by Cron`;
                    totalUpdated++;
                }
            }

            // 4. Save the Document
            // IMPORTANT: Mark the path as modified so Mongoose saves the nested array changes
            doc.markModified('monthlyAttendance'); 
            await doc.save();
        }

        console.log(`[Cron Result] Local Date: ${todayStr} | New Months: ${monthsCreated} | Records Created: ${totalCreated} | Updated: ${totalUpdated}`);
    } catch (error) {
        console.error("Critical Initialization Cron Error:", error);
    }
};

/**
 * Helper: Detects Weekoff status from Fixed or Flexible schedule
 */
async function getShiftConfigForDate(doc, date) {
    if (!doc.workTimings) return null;

    if (doc.workTimings.scheduleType === "Fixed") {
        const dayName = new Intl.DateTimeFormat('en-US', { weekday: 'short' }).format(date);
        const dayConfig = doc.workTimings.fixed.days.find(d => d.day === dayName);
        return { isWeekoff: dayConfig?.isWeekoff };
    } else {
        const dateStr = date.toISOString().split('T')[0];
        const monthStr = dateStr.substring(0, 7);
        const monthConfig = doc.workTimings.flexibles.find(m => m.month === monthStr);
        const dayConfig = monthConfig?.days.find(d => d.day === dateStr);
        return { isWeekoff: dayConfig?.isWeekoff };
    }
}