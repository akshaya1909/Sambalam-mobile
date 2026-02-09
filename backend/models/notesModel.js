import mongoose from 'mongoose';

const messageSchema = new mongoose.Schema({
  senderId: { type: mongoose.Schema.Types.ObjectId, required: true }, // Admin ID or Employee ID
  senderName: { type: String, required: true },
  senderType: { type: String, enum: ['admin', 'manager', 'employee', 'branch admin', 'attendance manager', 'advanced attendance manager'], required: true },
  text: { type: String },
  fileUrl: { type: String },
  fileType: { type: String },
  createdAt: { type: Date, default: Date.now }
}, { _id: true }); // _id for each message helps if you want to delete a specific one later

const noteThreadSchema = new mongoose.Schema({
  employeeId: { type: mongoose.Schema.Types.ObjectId, ref: 'Employee', required: true },
  companyId: { type: mongoose.Schema.Types.ObjectId, ref: 'Company', required: true },
  messages: [messageSchema],
}, { timestamps: true });

// Ensure unique index so one employee has only one thread per company
noteThreadSchema.index({ employeeId: 1, companyId: 1 }, { unique: true });

const Note = mongoose.model('Note', noteThreadSchema);
export default Note;