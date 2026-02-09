import mongoose from 'mongoose';

const attendanceKioskSchema = new mongoose.Schema({
    company: { type: mongoose.Schema.Types.ObjectId, ref: 'Company' },
    name: { type: String, required: true },
    dialCode: String,
    phoneNumber: String,
    branches: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Branch',
      },
    ],
    // Any more fields as needed
  }, { timestamps: true });
  
  const AttendanceKiosk = mongoose.model('AttendanceKiosk', attendanceKioskSchema);
  export default AttendanceKiosk;
  