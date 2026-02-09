import Announcement from '../models/announcementModel.js';
import AdminDetails from '../models/adminDetailsModel.js';
import Employee from '../models/employeeModel.js'; // Ensure this is imported
import Company from '../models/companyModel.js';
import admin from '../firebase.js';

export const createAnnouncement = async (announcementData, adminId) => {
  try {
    // Validate admin exists
    const admin = await AdminDetails.findById(adminId);
    if (!admin) throw new Error('Admin not found');

    // // Get admin's main company
    // const mainCompany = await Company.findById(admin.companyId);
    // if (!mainCompany) throw new Error('Company not found');

    // // Process target companies
    // let targetCompanies = [];
    // let isAllCompanies = false;

    // if (announcementData.isAllCompanies) {
    //   isAllCompanies = true;
    // } else if (announcementData.targetCompanyIds && announcementData.targetCompanyIds.length > 0) {
    //   // Validate all target companies exist and belong to admin's user
    //   targetCompanies = await Company.find({
    //     _id: { $in: announcementData.targetCompanyIds }
    //   });
    //   if (targetCompanies.length !== announcementData.targetCompanyIds.length) {
    //     throw new Error('Some target companies not found');
    //   }
    // } else {
    //   throw new Error('No target companies specified');
    // }

    const announcement = new Announcement({
      title: announcementData.title,
      description: announcementData.description,
      targetBranches: announcementData.targetBranchIds, // Renamed key
      isAllBranches: announcementData.isAllBranches,
      createdBy: adminId,
      companyId: announcementData.companyId,
      status: 'published',
      isActive: true
    });

    await announcement.save();

    // After saving, send push notifications
    await sendAnnouncementNotificationToCompany({
      companyId: announcement.companyId,
      title: announcement.title,
      body: announcement.description,
      announcementId: announcement._id.toString(),
      targetBranches: announcement.targetBranches, // Added this
  isAllBranches: announcement.isAllBranches
    });

    return announcement.populate('createdBy targetBranches');
  } catch (error) {
    throw new Error(`Failed to create announcement: ${error.message}`);
  }
};

// export const getCompanyAnnouncements = async (companyId, userCompanyIds = []) => {
//   const allCompaniesFilter = userCompanyIds.length
//     ? { isAllCompanies: true, companyId: { $in: userCompanyIds } }
//     : { isAllCompanies: false }; // if you don't know, exclude global ones

//   return await Announcement.find({
//     $or: [
//       { companyId },                 // announcements for this company
//       { targetBranches: companyId },// targeted to this company
//       allCompaniesFilter             // all-branches but only from user's companies
//     ],
//     isActive: true,
//     status: 'published'
//   })
//     .populate('createdBy', 'name')
//     .populate('targetBranches', 'name')
//     .sort({ createdAt: -1 });
// };


export const getCompanyAnnouncements = async (companyId, userBranchIds = [], isAdmin = false) => {
  // Construct the base query
  let query = {
    companyId: companyId,
    isActive: true,
    status: 'published'
  };

  // If NOT an admin, apply the branch filtering logic
  if (!isAdmin) {
    query.$or = [
      { isAllBranches: true },
      { targetBranches: { $in: userBranchIds } }
    ];
  }

  return await Announcement.find(query)
    .populate('createdBy', 'name')
    .populate('targetBranches', 'name')
    .sort({ isPinned: -1, createdAt: -1 }); // Pinned items appear at the top
};


export const sendAnnouncementNotificationToCompany = async ({ 
  companyId, title, body, announcementId, targetBranches, isAllBranches 
}) => {
  const company = await Company.findById(companyId).populate('users');
  if (!company) return;

  const users = company.users || [];
  const tokens = [];

  // Convert target branch IDs to strings for easy comparison
  const targetBranchStrings = targetBranches.map(id => id.toString());

  for (const user of users) {
    if (isAllBranches) {
      // If it's for everyone, just collect tokens
      if (user.fcmTokens) user.fcmTokens.forEach(t => tokens.push(t.token));
    } else {
      // 1. Find the Employee document for this specific user in this specific company
      const employee = await Employee.findOne({ 
        "basic.phone": user.phoneNumber, 
        companyId: companyId 
      });

      if (employee) {
        // 2. Check if any of the employee's branches match the announcement targets
        const employeeBranches = employee.basic.branches || [];
        const isMatch = employeeBranches.some(branchId => 
          targetBranchStrings.includes(branchId.toString())
        );

        if (isMatch && user.fcmTokens) {
          user.fcmTokens.forEach(t => tokens.push(t.token));
        }
      }
    }
  }

  const uniqueTokens = [...new Set(tokens)];
  if (uniqueTokens.length === 0) return;

  const message = {
    notification: { title, body },
    data: {
      type: 'announcement',
      announcementId: announcementId,
      companyId: companyId.toString(),
    },
  };

  // Send in batches
  const chunks = [];
  const size = 500;
  for (let i = 0; i < uniqueTokens.length; i += size) {
    chunks.push(uniqueTokens.slice(i, i + size));
  }

  for (const chunk of chunks) {
    await admin.messaging().sendEachForMulticast({
      tokens: chunk,
      ...message,
    });
  }
};