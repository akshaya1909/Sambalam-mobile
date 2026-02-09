import User from '../models/userModel.js'
import Announcement from '../models/announcementModel.js';
import Employee from '../models/employeeModel.js'; // Ensure this is imported
import { createAnnouncement, getCompanyAnnouncements } from '../services/announcementService.js';

export const createAnnouncementController = async (req, res) => {
  try {
    const { title, description, targetBranchIds, isAllBranches, companyId } = req.body;
    const adminId = req.params.adminId || req.headers['x-admin-id'];

    if (!adminId) {
      return res.status(400).json({ 
        success: false, 
        message: 'Admin ID is required' 
      });
    }

    if (!title?.trim()) {
      return res.status(400).json({ 
        success: false, 
        message: 'Title is required' 
      });
    }

    if (!description?.trim()) {
      return res.status(400).json({ 
        success: false, 
        message: 'Description is required' 
      });
    }

    const announcementData = {
      title: title.trim(),
      description: description.trim(),
      targetBranchIds: targetBranchIds || [],
      isAllBranches: isAllBranches || false,
      companyId: companyId
    };

    const announcement = await createAnnouncement(announcementData, adminId);
    
    res.status(201).json({
      success: true,
      message: 'Announcement created successfully',
      data: announcement
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

export const getCompanyAnnouncementsController = async (req, res) => {
  try {
    const { companyId } = req.params;
    const userId = req.query.userId || (req.user ? req.user.id : null);

    if (!userId) return res.status(400).json({ message: "User ID required" });

    // 1. Fetch the User to check roles
    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ message: "User not found" });

    // 2. Determine if user is an Admin/Manager for this company
    const membership = user.memberships.find(m => m.companyId.toString() === companyId);
    const isAdmin = membership && (membership.roles.includes('admin') || membership.roles.includes('manager'));

    let announcements;

    if (isAdmin) {
      // 3. Admin Logic: Call service with isAdmin flag set to true
      announcements = await getCompanyAnnouncements(companyId, [], true);
    } else {
      // 4. Employee Logic: Find branch associations from Employee Model
      const employee = await Employee.findOne({ 
        "basic.phone": user.phoneNumber, 
        companyId: companyId 
      });

      const userBranchIds = employee && employee.basic.branches ? employee.basic.branches : [];

      // Call service with specific branches
      announcements = await getCompanyAnnouncements(companyId, userBranchIds, false);
    }

    res.status(200).json({
      success: true,
      data: announcements
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};


export const markAnnouncementAsRead = async (req, res) => {
  try {
    const { announcementId } = req.params;
    const { userId } = req.body;

    const announcement = await Announcement.findByIdAndUpdate(
      announcementId,
      {
        $addToSet: { readBy: { userId: userId, readAt: Date.now() } },
        $inc: { totalViews: 1 }
      },
      { new: true }
    );

    res.status(200).json({ success: true, data: announcement });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const getUnreadAnnouncementCount = async (req, res) => {
  try {
    const { companyId, userId } = req.params;

    // Count announcements where company matches AND userId is NOT in the readBy array
    const count = await Announcement.countDocuments({
      companyId,
      isActive: true,
      status: 'published',
      'readBy.userId': { $ne: userId }
    });

    res.status(200).json({ success: true, unreadCount: count });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};