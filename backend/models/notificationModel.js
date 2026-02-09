import mongoose from "mongoose";

const notificationSchema = new mongoose.Schema({
  companyId: { type: mongoose.Schema.Types.ObjectId, ref: 'Company', required: true },
  // Removed 'recipientId' requirement because we are saving it generally for the company admins
  recipientId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }, 
  type: { 
    type: String, 
    enum: ['Attendance', 'Leave Request', 'Notes', 'Live Track', 'Payments', 'Announcement'], 
    required: true 
  },
  title: { type: String, required: true },
  body: { type: String, required: true },
  data: {
    employeeId: { type: mongoose.Schema.Types.ObjectId, ref: 'Employee' },
    employeeName: String,
    employeePhoto: String,
    image: String, // Selfie URL
    address: String,
    lat: Number,
    lng: Number,
    eventTime: Date,
    status: String // 'In', 'Out'
  },
  isRead: { type: Boolean, default: false },
}, { timestamps: true });

const Notification = mongoose.model('Notification', notificationSchema);
export default Notification;