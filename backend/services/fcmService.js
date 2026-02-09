import admin from 'firebase-admin';
import User from '../models/userModel.js';
import Notification from '../models/notificationModel.js';

// export const sendNotificationToCompanyAdmins = async (companyId, notificationData) => {
//   try {
//     // FIX: Check if companyId exists inside the 'companies' array
//     const admins = await User.find({ 
//       companies: { $in: [companyId] }, 
//       role: { $in: ['admin', 'manager'] } // Optional: target roles
//     });
    
//     console.log(`👥 Found ${admins.length} admins to notify`);

//     // 1. Save to DB
//     await Notification.create({
//       companyId,
//       type: notificationData.type,
//       title: notificationData.title,
//       body: notificationData.body,
//       data: notificationData.payload
//     });

//     // 2. Send Push
//     const tokens = [];
//     admins.forEach(admin => {
//       if (admin.fcmTokens && admin.fcmTokens.length > 0) {
//         admin.fcmTokens.forEach(t => tokens.push(t.token));
//       }
//     });

//     if (tokens.length > 0) {
//       // Unique tokens only
//       const uniqueTokens = [...new Set(tokens)];
      
//       const message = {
//         notification: {
//           title: notificationData.title,
//           body: notificationData.body,
//         },
//         data: {
//           type: notificationData.type,
//           employeeId: String(notificationData.payload.employeeId),
//           click_action: "FLUTTER_NOTIFICATION_CLICK"
//         },
//         tokens: uniqueTokens,
//       };

//       await admin.messaging().sendMulticast(message);
//       console.log('🚀 Push sent to', uniqueTokens.length, 'devices');
//     }
//   } catch (error) {
//     console.error('❌ Error sending notification:', error);
//   }
// };



export const sendNotificationToCompanyAdmins = async (companyId, notificationData) => {
  try {
    const { branchId, employeeId } = notificationData.payload;
    // FIND RECIPIENTS BASED ON YOUR LOGIC:
    // 1. Global Admins/Managers for the company
    // 2. Advanced Attendance Managers for the company
    // 3. Branch Admins ONLY IF they are assigned to the employee's branch
    const recipients = await User.find({
      memberships: {
        $elemMatch: {
          companyId: companyId,
          $or: [
            { roles: { $in: ['admin', 'manager', 'advanced attendance manager'] } },
            { 
              roles: 'branch admin', 
              assignedBranches: branchId // Matches the specific branch of the event
            }
          ]
        }
      }
    });

    console.log(`👥 Found ${recipients.length} eligible recipients to notify`);

    // 1. Save general notification to DB for the company logs
    await Notification.create({
      companyId,
      type: notificationData.type,
      title: notificationData.title,
      body: notificationData.body,
      data: notificationData.payload
    });

    // 2. Collect Tokens
    const tokens = [];
    recipients.forEach(user => {
      if (user.fcmTokens && user.fcmTokens.length > 0) {
        user.fcmTokens.forEach(t => tokens.push(t.token));
      }
    });

    if (tokens.length > 0) {
      const uniqueTokens = [...new Set(tokens)];
      
      const message = {
        notification: {
          title: notificationData.title,
          body: notificationData.body,
        },
        data: {
          type: String(notificationData.type),
          employeeId: String(employeeId),
          status: String(notificationData.payload.status || ""),
          click_action: "FLUTTER_NOTIFICATION_CLICK"
        },
        tokens: uniqueTokens,
      };

      const response = await admin.messaging().sendEachForMulticast(message);
      console.log(`🚀 Push sent. Success: ${response.successCount}, Failure: ${response.failureCount}`);
      
      // Optional: Cleanup invalid tokens
      if (response.failureCount > 0) {
        const failedTokens = [];
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            failedTokens.push(uniqueTokens[idx]);
          }
        });
        console.log('⚠️ Some tokens failed:', failedTokens.length);
      }
    }
  } catch (error) {
    console.error('❌ Error sending notification:', error);
  }
};