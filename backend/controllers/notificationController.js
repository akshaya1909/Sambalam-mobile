import Notification from "../models/notificationModel.js";

export const getNotifications = async (req, res) => {
  try {
    const { companyId } = req.query;
    const { type, employeeId } = req.query; // Filters

    let query = { companyId };

    if (type && type !== 'All Notifications') {
      query.type = type;
    }

    if (employeeId) {
      query['data.employeeId'] = employeeId;
    }

    const notifications = await Notification.find(query)
      .sort({ createdAt: -1 }) // Newest first
      .limit(50); // Pagination recommended for prod

    res.status(200).json(notifications);
  } catch (error) {
    res.status(500).json({ message: "Failed to fetch notifications" });
  }
};