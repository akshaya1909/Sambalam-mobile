import User from "../models/userModel.js";
import Company from "../models/companyModel.js";
import admin from "firebase-admin";

export const sendAttendanceNotification = async (attendanceData, employeeName) => {
  const { companyId, branchId, status } = attendanceData;

  try {
    // 1. Check if Company allows notifications
    const company = await Company.findById(companyId);
    if (!company || !company.appNotifications) return;

    // 2. Find eligible recipients
    // We want: 
    // - Global Admins
    // - Advanced Attendance Managers
    // - Branch Admins (only if they belong to the specific branch)
    const recipients = await User.find({
      memberships: {
        $elemMatch: {
          companyId: companyId,
          $or: [
            { roles: { $in: ["admin", "advanced attendance manager"] } },
            { 
              roles: "branch admin", 
              assignedBranches: branchId // Only admins for THIS branch
            }
          ]
        }
      }
    });

    // 3. Extract FCM Tokens
    const allTokens = [];
    recipients.forEach(u => {
      if (u.fcmTokens && u.fcmTokens.length > 0) {
        u.fcmTokens.forEach(t => allTokens.push(t.token));
      }
    });

    if (allTokens.length === 0) return;

    // 4. Construct the Message
    const payload = {
      notification: {
        title: `Attendance Alert: ${employeeName}`,
        body: `${employeeName} has just punched ${status === 'in' ? 'IN' : 'OUT'}.`,
      },
      data: {
        type: "ATTENDANCE_EVENT",
        companyId: companyId.toString(),
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      }
    };

    // 5. Send using Firebase Admin SDK
    const response = await admin.messaging().sendToDevice(allTokens, payload);
    console.log(`Notifications sent: ${response.successCount}`);

  } catch (error) {
    console.error("FCM Error:", error);
  }
};