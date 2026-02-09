import express from 'express';
import dotenv from 'dotenv';
dotenv.config();
import cors from 'cors';
import { fileURLToPath } from 'url';
import path from 'path';
import connectDB from './config/db.js';
import cron from 'node-cron';
import bcrypt from 'bcryptjs';
import User from './models/userModel.js';
import Company from './models/companyModel.js';
import Employee from './models/employeeModel.js';
import AdminDetails from './models/adminDetailsModel.js';
import userRoutes from './routes/userRoutes.js'
import companyRoutes from './routes/companyRoutes.js'
import companySetupRoutes from './routes/companySetupRoutes.js'
import employeeRoutes from "./routes/employeeRoutes.js";
import adminDetailsRoutes from "./routes/adminDetailsRoutes.js";
import adminRoutes from "./routes/adminRoutes.js";
import advertiseDetailsRoutes from "./routes/advertiseDetailsRoutes.js";
import attendanceRoutes from "./routes/attendanceRoutes.js";
import leaveRoutes from "./routes/leaveRoutes.js";
import bankDetailsRoutes from "./routes/bankDetailsRoutes.js";
import leaveAndBalanceRoutes from './routes/leaveAndBalanceRoutes.js'  
import salaryDetailsRoutes from './routes/salaryDetailsRoutes.js'
import payrollRoutes from "./routes/payrollRoutes.js";
import reportRoutes from './routes/reportRoutes.js';
import tdsRoutes from './routes/tdsRoutes.js';
import branchRoutes from "./routes/branchRoutes.js";
import shiftRoutes from './routes/shiftRoutes.js';
import companyBreakRoutes from './routes/companyBreakRoutes.js';
import penaltyAndOvertimeRoutes from './routes/penaltyAndOvertimeRoutes.js'
import departmentRoutes from "./routes/departmentRoutes.js";
import biometricDeviceRoutes from './routes/biometricDeviceRoutes.js';
import attendanceKioskRoutes from './routes/attendanceKioskRoutes.js';
import announcementRoutes from './routes/announcementRoutes.js';
import holidayRoutes from './routes/holidayRoutes.js';
import leaveTypeRoutes from './routes/leaveTypeRoutes.js';
import incentiveRoutes from './routes/incentiveRoutes.js';
import salaryTemplateRoutes from './routes/salaryTemplateRoutes.js'
import salaryImportRoutes from './routes/salaryImportRoutes.js'
import customFieldRoutes from './routes/customFieldRoutes.js';
import reimbursementRoutes from './routes/reimbursementRoutes.js';
import notificationRoutes from './routes/notificationRoutes.js';
import workReportRoutes from './routes/workReportRoutes.js'
import notesRoutes from './routes/notesRoutes.js'
import UserDetails from './models/userDetailsModel.js';
import Anomaly from './models/anomalyModel.js';
import newDeviceVerificationRequestModel from './models/newDeviceVerificationRequestModel.js';
import planRoutes from './routes/planRoutes.js';
import addonRoutes from './routes/addonRoutes.js'
import systemSettingsRoutes from './routes/systemSettingsRoutes.js'
import { initializeDailyStatus } from './services/attendanceCronService.js';

const port = process.env.PORT || 5000;
connectDB();
const app = express();

app.use(cors());
app.use(express.json());

app.get('/',(req, res) => {
    res.send('API is running');
});

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const uploadsDir = path.join(__dirname, 'uploads');

app.use('/api/company', (req, res, next) => {
  console.log('🔥 ALL COMPANY ROUTES:', req.method, req.path, req.params, req.query);
  next();
}, companyRoutes);
app.use('/api/v1', userRoutes)
app.use('/api/company-setup', companySetupRoutes);
app.use("/api/employees", employeeRoutes);
app.use('/api/admin-details', adminDetailsRoutes);
app.use('/api/advertise-details', advertiseDetailsRoutes);
app.use("/api/attendance", attendanceRoutes);
app.use('/api/salary', salaryDetailsRoutes);
app.use('/api/bank', bankDetailsRoutes);
app.use("/api/leaves", leaveRoutes);
app.use('/api/leave-and-balance', leaveAndBalanceRoutes);
app.use('/api/reports', reportRoutes);
app.use('/api/tds', tdsRoutes);
app.use('/api/penalty-and-overtime', penaltyAndOvertimeRoutes);
app.use('/api/announcements', announcementRoutes);
app.use('/api/branches', branchRoutes);
app.use('/api/department', departmentRoutes);
app.use('/api/admins', adminRoutes);
app.use('/api/shifts', shiftRoutes);
app.use("/api/payroll", payrollRoutes);
app.use('/api/company-breaks', companyBreakRoutes);
app.use('/api/biometrics', biometricDeviceRoutes);
app.use('/api/attendance-kiosks', attendanceKioskRoutes);
app.use('/api', holidayRoutes);
app.use('/api/leave-type', leaveTypeRoutes);
app.use('/api/incentives', incentiveRoutes);
app.use('/api/salary-templates', salaryTemplateRoutes);
app.use('/api/salary-import', salaryImportRoutes);
app.use('/api/custom', customFieldRoutes);
app.use('/api/reimbursements', reimbursementRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/work-report', workReportRoutes);
app.use('/api/notes', notesRoutes);
app.use('/api/plans', planRoutes);
app.use('/api/addons', addonRoutes);
app.use('/api/system', systemSettingsRoutes);

app.get('/api/companies', async (req, res) => {
    const phoneNumber = req.query.phone;

    if (!phoneNumber) {
        return res.status(400).json({ message: 'Phone number is required' });
    }

    try {
        const user = await User.findOne({ phoneNumber })
            .populate('memberships.companyId')
            .populate('memberships.assignedBranches');

        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        const flattenedCompanies = [];

        // Loop through each membership (company)
        user.memberships.forEach(membership => {
            if (!membership.companyId) return;

            // Loop through each role in that specific company
            membership.roles.forEach(role => {
                flattenedCompanies.push({
                    ...membership.companyId.toObject(), // Base company details
                    hasPin: !!membership.secure_pin,
                    role: role, // Singular role for this specific list item
                    // Only include branch names if the role is 'branch admin'
                    assignedBranchNames: role === 'branch admin' && membership.assignedBranches 
                        ? membership.assignedBranches.map(b => b.name) 
                        : []
                });
            });
        });

        res.json(flattenedCompanies);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

app.post('/api/check-phone', async (req, res) => {
  const { phoneNumber } = req.body;

  try {
    // Populate company details so the app can show names/logos
    const user = await User.findOne({ phoneNumber })
    .populate('memberships.companyId')
    .populate('memberships.assignedBranches');

    if (!user) {
      return res.json({ exists: false });
    }

    const otpValid = user.otp?.expiresAt && new Date() < new Date(user.otp.expiresAt);

    // Logic: Does this user have at least one company membership with a PIN set?
    const hasAnySecurePin = user.memberships.some(m => !!m.secure_pin);

    res.json({
      exists: true,
      isVerified: user.isVerified || false,
      hasSecurePin: hasAnySecurePin,
      otpExpired: !otpValid,
      // FIX: Added filter and optional chaining to prevent the null _id error
      memberships: user.memberships
        .filter(m => m.companyId) // Remove any memberships where companyId didn't populate
        .map(m => ({
          companyId: m.companyId._id,
          companyName: m.companyId.name || "Unknown Company",
          companyLogo: m.companyId.logo || null,
          roles: m.roles,
          hasPin: !!m.secure_pin,
          assignedBranchNames: m.assignedBranches.map(b => b.name)
        }))
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

app.post('/api/reset-pin', async (req, res) => {
  const { phoneNumber, newPin, companyId } = req.body; // Added companyId

  try {
    const user = await User.findOne({ phoneNumber });
    if (!user) return res.status(404).json({ message: "User not found" });

    // 1. Find the specific membership for the requested company
    const membership = user.memberships.find(
      (m) => m.companyId.toString() === companyId
    );

    if (!membership) {
      return res.status(404).json({ 
        message: "Membership not found for this company" 
      });
    }

    // 2. Update the PIN inside that membership entry
    // The pre('save') hook in your model will hash this automatically 
    // because it loops through the memberships array.
    membership.secure_pin = newPin; 

    // 3. Mark the sub-document as modified (Mongoose requirement for nested arrays)
    user.markModified('memberships');
    await user.save();

    res.status(200).json({ 
      success: true, 
      message: "PIN reset successfully for this company" 
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});


// POST /api/users/auth
app.post('/api/users/auth', async (req, res) => {
  try {
    const { phoneNumber, pin, companyId, deviceId, deviceModel, role } = req.body;

    // 1. Basic User & PIN Verification
    const user = await User.findOne({ phoneNumber });
    if (!user) {
      return res.status(401).json({ message: 'Phone number not found' });
    }

    // 2. Company Verification
    const company = await Company.findById(companyId);
    if (!company) {
      return res.status(404).json({ message: 'Company not found' });
    }

    const isMatch = await user.matchSecurePin(companyId, pin);
    if (!isMatch) {
      return res.status(401).json({ message: 'Incorrect PIN for this company' });
    }

    // 3. Verify Company Membership & Resolve Roles
    const membership = user.memberships.find(m => m.companyId.toString() === companyId);
    if (!membership) {
      return res.status(403).json({ message: 'You are not a member of this company' });
    }
    if (!membership.roles.includes(role)) {
    return res.status(403).json({ message: 'Unauthorized role for this company' });
  }

    // roles is an array now, e.g., ['admin', 'manager']
    // const roles = membership.roles; 
    // const primaryRole = roles.includes('admin') ? 'admin' : roles[0];

    // 3. Resolve IDs for Session
    const employee = await Employee.findOne({
      'basic.phone': phoneNumber,
      companyId: companyId,
    });

    const employeeId = employee ? employee._id : null;
    let adminId = null;

    if (role === 'admin' || role === 'branch admin') {
      const admin = await AdminDetails.findOne({ userId: user._id, companyIds: companyId }).select('_id');
      adminId = admin ? admin._id : null;
    }

    let loginStatus = "success"; // Default status

    // if (roles.includes('admin')) {
    //   const admin = await AdminDetails.findOne({
    //     userId: user._id,
    //     companyIds: companyId,
    //   }).select('_id');
    //   adminId = admin ? admin._id : null;
    // }

    // --- 4. DEVICE VERIFICATION LOGIC ---
    // If the user is an employee, we must check their hardware ID 
    if (employee) {
      // Case 1: Initial device registration (First time ever logging in)
      if (!user.deviceId) {
        user.deviceId = deviceId;
        user.deviceModel = deviceModel;
        user.isDeviceVerified = true;
        await user.save();

        employee.device = {
          status: "verified",
          verifiedOn: new Date(),
          remarks: "Initial device"
        };
        await employee.save();
      } 
      // Case 2: Mismatch - Existing device ID does not match current physical phone
      else if (user.deviceId !== deviceId) {
        loginStatus = "device_pending";

        await Anomaly.create({
          companyId,
          userId: user._id,
          employeeName: employee.basic.fullName,
          companyName: company.name,
          type: 'Device Tampering',
          severity: 'high', // Tampering is critical security risk
          description: `Unauthorized device switch: Registered on ${user.deviceModel} but attempted login from ${deviceModel}.`,
          metadata: {
            deviceId: deviceId, // The new suspicious ID
            actualDeviceId: user.deviceId // The original bound ID
          }
        });

        const existingRequest = await newDeviceVerificationRequestModel.findOne({
          userId: user._id,
          newDeviceId: deviceId,
          status: 'pending'
        });

        // Create a request if one doesn't exist for this specific new device
        if (!existingRequest) {
          await newDeviceVerificationRequestModel.create({
            userId: user._id,
            employeeId: employee._id,
            companyId,
            name: employee.basic.fullName,
            phoneNumber: user.phoneNumber,
            newDeviceId: deviceId,
            newDeviceModel: deviceModel
          });

          employee.device = {
            status: "pending",
            newDeviceId: deviceId,
            newDeviceModel: deviceModel
          };
          await employee.save();
        }
      }
    }

    // 5. Final Response
    return res.status(200).json({
      success: true,
      message: loginStatus === 'device_pending' 
        ? 'New device detected. Awaiting admin approval.' 
        : 'Login successful',
      status: loginStatus, // Flutter app uses this to decide which screen to show
      role: role,
      phoneNumber: user.phoneNumber,
      companyId,
      employeeId,
      adminId,
      userId: user._id
    });

  } catch (err) {
    console.error('Login Error:', err);
    return res.status(500).json({ message: 'Server error' });
  }
});


// POST /verify-otp
app.post('/api/verify-otp', async (req, res) => {
  const { phoneNumber, otp } = req.body;

  if (!phoneNumber || !otp) {
    return res.status(400).json({ message: 'Phone number and OTP are required' });
  }

  try {
    let user = await User.findOne({ phoneNumber }); // Changed to 'let'

    const expiresAt = new Date(Date.now() + 5 * 60 * 1000); 

    if (user) {
      // CASE 1: Existing user
      user.otp = { code: otp, expiresAt };
      user.isVerified = true;
      await user.save();
    } else {
      // CASE 2: New user - Assign to the 'user' variable so it's not null below
      user = new User({
        phoneNumber,
        isVerified: true,
        otp: { code: otp, expiresAt },
        memberships: [] 
      });
      await user.save();
    }

    // Now 'user' is guaranteed to be non-null here
    return res.json({ 
      message: 'OTP verified and user updated/created', 
      hasCompanies: user.memberships.length > 0 
    });

  } catch (err) {
    console.error("OTP Verification Error:", err);
    res.status(500).json({ message: 'Server error' });
  }
});


// Check if user exists and is verified
app.post("/api/check-user-status", async (req, res) => {
  const { phoneNumber } = req.body;

  try {
    const user = await User.findOne({ phoneNumber });

    if (!user) {
      return res.status(404).json({ exists: false });
    }

    res.json({ exists: true, isVerified: user.isVerified });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error" });
  }
});


app.post("/api/update-secure-pin", async (req, res) => {
  const { phoneNumber, secure_pin, companyId } = req.body;

  try {
    const user = await User.findOne({ phoneNumber });
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    if (!user.isVerified) {
      return res.status(403).json({ message: "Phone number not verified" });
    }

    const targetCompanyId = companyId.toString().trim();

    // NEW LOGIC: Find the specific membership for this company
    const membershipIndex = user.memberships.findIndex(
      (m) => m.companyId.toString() === targetCompanyId
    );

    if (membershipIndex === -1) {
      console.log(`Mismatch! Target: ${targetCompanyId}`);
      console.log(`Available: ${user.memberships.map(m => m.companyId.toString())}`);
      return res.status(404).json({ message: "User is not a member of this company" });
    }

    // Update the PIN inside the array
    user.memberships[membershipIndex].secure_pin = secure_pin;
    
    // Save triggers the pre-save hook in your model to hash the PIN
    await user.save();

    res.json({ 
      message: "Secure PIN set successfully for this company",
      companyId: companyId 
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error" });
  }
});


app.get('/api/dashboard-info', async (req, res) => {
  const { phone, companyId } = req.query;

  if (!phone || !companyId) {
    return res.status(400).json({ message: 'Phone number and CompanyId is required' });
  }

  try {
    const user = await User.findOne({ phoneNumber: phone });

    if (!user) return res.status(404).json({ message: 'User not found' });

    const company = await Company.findOne({
      _id: companyId,
      users: user._id,
});

    if (!company) return res.status(404).json({ message: 'Company not found' });

    const userDetails = await UserDetails.findOne({ user: user._id })
      .select('basic_info.name basic_info.profilePic basic_info.jobTitle');

    const createdByUser = await User.findById(company.created_by);

    res.json({
      company: {
        _id: company._id,
        name: company.name,
        code: company.company_code,
        logo: company.logo,
        users: company.users,
      },
      user: {
        _id: user._id,
        name: userDetails?.basic_info?.name || user.name || 'Unknown User',
        profilePic: userDetails?.basic_info?.profilePic || null,
        role: userDetails?.basic_info?.jobTitle || null,
        companies: user.companies
      },
    });
  } 
  catch (err) {
    console.error('Dashboard info error:', err);
    res.status(500).json({ message: 'Server error' });
  }
});

app.use('/uploads', express.static(uploadsDir));

// Run exactly at 12:00 AM every day
cron.schedule('0 0 * * *', () => {
    console.log('Running Daily Attendance Initialization at 12:00 AM...');
    initializeDailyStatus();
});

console.log("Triggering manual test...");
initializeDailyStatus();

app.listen(port,() => console.log(`server running on port ${port}`));