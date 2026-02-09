// controllers/employeeController.js
import mongoose from "mongoose";
import bcrypt from "bcryptjs";
import Subscription from "../models/subscriptionModel.js";
import User from '../models/userModel.js';
import Company from "../models/companyModel.js";
import Attendance from "../models/attendanceModel.js"
import Department from "../models/departmentModel.js";
import UserDetails from "../models/UserDetailsModel.js";
import Employee from "../models/employeeModel.js";
import PDFDocument from 'pdfkit';
import { getEmployeeBasicDetails, getEmployeeByPhoneService } from "../services/employeeService.js";
import { getEmployeeProfileById } from '../services/employeeProfileService.js';

const formatFileSize = (bytes) => {
  if (bytes === 0) return '0 Bytes';
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
};

export const addEmployee = async (req, res) => {
  try {
    const {
      fullName,
      initials,
      jobTitle,
      branches,
      departments,
      phone,
      loginOtp,
      gender,
      officialEmail,
      dateOfJoining,
      currentAddress,
      companyId,
    } = req.body;

    if (!fullName || !phone || !branches?.length || !loginOtp || !companyId) {
      return res.status(400).json({ message: "Missing required fields" });
    }
    const companyObjectId = new mongoose.Types.ObjectId(companyId);

    const company = await Company.findById(companyObjectId).populate("subscriptionId");
    if (!company) return res.status(404).json({ message: "Company not found" });

    const subscription = await Subscription.findById(company.subscriptionId).populate("planId");
    
    if (subscription) {
      // 1. Check Expiry
      if (subscription.expiryDate && new Date(subscription.expiryDate) < new Date()) {
        return res.status(403).json({ 
          message: "PLAN_EXPIRED", 
          details: `Your ${subscription.planId.name} has expired. Please renew to add staff.` 
        });
      }

      // 2. Count shared pool of employees
      // Find all companies sharing this subscription
      const sharedCompanies = await Company.find({ subscriptionId: subscription._id }).select("_id");
      const companyIds = sharedCompanies.map(c => c._id);

      const totalEmployees = await Employee.countDocuments({ companyId: { $in: companyIds } });

      if (totalEmployees >= subscription.includedEmployeesCount) {
        return res.status(403).json({ 
          message: "LIMIT_REACHED", 
          planName: subscription.planId.name,
          limit: subscription.includedEmployeesCount
        });
      }
    }

    // 1. Find user by phone
    let user = await User.findOne({ phoneNumber: phone });

    if (!user) {
      // SCENARIO: Completely new user
      user = new User({
        phoneNumber: phone,
        isVerified: false,
        memberships: [{
          companyId: companyObjectId,
          roles: ['employee'],
          secure_pin: null, // Initialized as null as per request
          joinedAt: new Date()
        }],
      });
      await user.save();
    } else {
      // SCENARIO: Existing user - Check memberships
      const membershipIndex = user.memberships.findIndex(
        (m) => m.companyId.toString() === companyId
      );

      if (membershipIndex !== -1) {
        // User already has a membership in this company
        const roles = user.memberships[membershipIndex].roles;
        
        if (roles.includes('employee')) {
          return res.status(400).json({ message: "Employee already exists in this company" });
        } else {
          // User is in the company with different roles, add employee role
          user.memberships[membershipIndex].roles.push('employee');
          await user.save();
        }
      } else {
        // User exists but is new to THIS company
        user.memberships.push({
          companyId: companyObjectId,
          roles: ['employee'],
          secure_pin: null,
          joinedAt: new Date()
        });
        await user.save();
      }
    }

    // Add user to company.users if not present
    if (!company.users.includes(user._id)) {
      company.users.push(user._id);
      await company.save();
    }

    // 3. 🚫 Prevent duplicate UserDetails (user + company)
    const branchIds = branches.map((b) => new mongoose.Types.ObjectId(b));

const existingEmployee = await Employee.findOne({
  companyId: companyId,
  "basic.phone": phone,
  "basic.branches": { $in: branchIds },
});

    if (existingEmployee) {
      return res.status(400).json({ message: "Employee already exists in this company" });
    }

    if (!mongoose.Types.ObjectId.isValid(companyId)) {
      return res.status(400).json({ message: "Invalid Company ID format" });
  }

    // 4. Create UserDetails
    const employee = new Employee({
      companyId: companyObjectId,
      basic: {
          fullName,
          initials: initials || fullName.charAt(0),
          jobTitle: jobTitle || "",
          branches: branchIds,
          departments: (departments || []).map(d => new mongoose.Types.ObjectId(d)),
          phone,
          loginOtp,
          gender: gender || "Other",
          officialEmail: officialEmail || "",
          dateOfJoining: dateOfJoining || new Date(),
          currentAddress: currentAddress || "",
      },
      personal: {},
      employment: [{
          probationStatus: "No Probation", // Match your enum defaults
          employeeType: "Full Time"
      }],
  });

    await employee.save();
    if (departments && departments.length > 0) {
      const departmentIds = departments.map(d => new mongoose.Types.ObjectId(d));
      
      await Department.updateMany(
        { _id: { $in: departmentIds } },
        { $addToSet: { staff: employee._id } }
      );
      
      console.log(`Added employee ${employee._id} to ${departmentIds.length} departments`);
    }

    const attendance = new Attendance({
      employeeId: employee._id,
      companyId: companyObjectId,
      // FIX: Provide the required scheduleType and nested structure
      workTimings: {
        scheduleType: "Fixed", 
        fixed: {
          type: "Fixed",
          days: [] // You can populate this with defaults if needed
        }
      },
      attendanceModes: {
        enableSmartphoneAttendance: true,
        smartphone: {
          selfieAttendance: true,
          qrAttendance: false,
          gpsAttendance: true,
          markAttendanceFrom: "Anywhere"
        },
        biometric: { enabled: false },
        attendanceKiosk: { enabled: false }
      },
      automationRules: {
        autoPresentAtDayStart: false,
        presentOnPunchIn: true,
        // FIX: Use empty duration objects instead of null to avoid validation crashes
        autoHalfDayIfLateBy: { hours: 0, minutes: 0 },
        mandatoryHalfDayHours: { hours: 0, minutes: 0 },
        mandatoryFullDayHours: { hours: 0, minutes: 0 }
      },
      staffCanViewOwnAttendance: false,
      monthlyAttendance: [{
        user: user._id,
        companyId: companyObjectId,
        year: new Date().getFullYear(),
        month: new Date().getMonth() + 1,
        records: [{
            date: new Date(new Date().setUTCHours(0,0,0,0)),
            status: "Absent", // Or "Absent" as default
            remarks: "Initial Record"
        }]
      }]
    });
    
    await attendance.save();

    res.status(201).json({ message: "Employee created", user, employee });
  } catch (err) {
    console.error("DETAILED SERVER ERROR:", err); // This prints to your VS Code Terminal
    res.status(500).json({ 
        message: "Error creating employee", 
        error: err.message, // Send the real error back to Flutter
        stack: err.stack 
    });
}
};


export const updateEmployee = async (req, res) => {
  try {
    const { id } = req.params;
    // Parse all fields you want to update from formData (flat for clarity here, can refactor)
    const {
      name, initials, phone, personalEmail, dob, gender, maritalStatus, bloodGroup,
      guardianName, emergencyContactName, emergencyContactNumber,
      emergencyContactRelationship, emergencyContactAddress,
      aadharNumber, panNumber, drivingLicenseNumber, voterIdNumber, uanNumber,
      permanentAddress, currentAddress, employeeProfile
    } = req.body;

    const user = await User.findById(id);
    if (!user)
      return res.status(404).json({ message: "No user found" });

    // 3. Find the employee
    const employee = await Employee.findOne({ "basic.phone": phone });
    if (!employee)
      return res.status(404).json({ message: "Employee not found for user" });

    // Update basic details
    employee.basic.fullName = name;
    employee.basic.initials = initials;
    employee.basic.phone = phone;
    employee.basic.currentAddress = currentAddress;

    // Update personal details
    employee.personal.personalEmail = personalEmail || null;
    employee.personal.dob = dob || null;
    employee.basic.gender = gender || null;
    employee.personal.maritalStatus = maritalStatus || null;
    employee.personal.bloodGroup = bloodGroup || null;
    employee.personal.guardianName = guardianName || null;
    employee.personal.emergencyContactName = emergencyContactName || null;
    employee.personal.emergencyContactNumber = emergencyContactNumber || null;
    employee.personal.emergencyContactRelationship = emergencyContactRelationship || null;
    employee.personal.emergencyContactAddress = emergencyContactAddress || null;
    employee.personal.aadharNumber = aadharNumber || null;
    employee.personal.panNumber = panNumber || null;
    employee.personal.drivingLicenseNumber = drivingLicenseNumber || null;
    employee.personal.voterIdNumber = voterIdNumber || null;
    employee.personal.uanNumber = uanNumber || null;
    employee.personal.permanentAddress = permanentAddress || null;
    employee.personal.employeeProfile = employeeProfile || null;

    await employee.save();
    res.status(200).json({ message: "Employee updated successfully", employee });
  } catch (err) {
    console.error("Error updating employee:", err);
    res.status(500).json({ message: "Failed to update employee" });
  }
};


export const deleteEmployee = async (req, res) => {
  try {
    const { id } = req.params; // userId

    const employee = await Employee.findById(id);
    if (!employee) {
      return res.status(404).json({ message: "Employee not found" });
    }

    const employeeId = employee._id;

    // 2. Remove this employee from all Departments' staff arrays
    // This cleans up the other side of the relationship
    await Department.updateMany(
      { staff: employeeId }, 
      { $pull: { staff: employeeId } }
    );

    // Find employee details by user reference
    const userDetails = await UserDetails.findOne({ user: id });
    if (!userDetails) {
      return res.status(404).json({ message: "Employee not found" });
    }

    const companyId = req.body.companyId || null; // send from frontend if available

    // Remove from Company.users
    if (companyId) {
      await Company.updateOne(
        { _id: companyId },
        { $pull: { users: userDetails.user } }
      );
    } else {
      await Company.updateMany(
        { users: userDetails.user },
        { $pull: { users: userDetails.user } }
      );
    }

    // Remove company reference from User.companies
    await User.updateOne(
      { _id: userDetails.user },
      { $pull: { companies: companyId } }
    );

    // Delete UserDetails
    await UserDetails.findByIdAndDelete(userDetails._id);

    // Check if user still belongs to any companies
    const user = await User.findById(userDetails.user);
    if (user && user.companies.length === 0) {
      await User.findByIdAndDelete(userDetails.user);
      return res.status(200).json({ message: "Employee and user deleted successfully" });
    }

    res.status(200).json({ message: "Employee deleted successfully" });
  } catch (err) {
    console.error("Error deleting employee:", err);
    res.status(500).json({ message: "Failed to delete employee" });
  }
};

export const updateEmploymentDetails = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      phone,
      branches,
      departments,
      employeeType,
      dateOfJoining,
      dateOfLeaving,
      employeeId,
      jobTitle,
      officialEmail,
      esiNumber,
      pfNumber,
      probationPeriod,
      probationStatus,
      probationEndDate,
    } = req.body;

    const user = await User.findById(id);
    if (!user)
      return res.status(404).json({ message: "No user found" });
    // 3. Find the employee
    const employee = await Employee.findOne({ "basic.phone": phone });
    if (!employee) return res.status(404).json({ message: "Employee not found" });

    // Update fields under basic
    if (branches) employee.basic.branches = branches;
    if (departments) {
      employee.basic.departments = departments;
      
      // 1. Remove employee from all departments in this company first (optional, to handle department changes)
      await Department.updateMany(
          { company: employee.companyId },
          { $pull: { staff: employee._id } }
      );
  
      // 2. Add to the new selection
      const departmentIds = departments.map(d => new mongoose.Types.ObjectId(d));
      await Department.updateMany(
          { _id: { $in: departmentIds } },
          { $addToSet: { staff: employee._id } }
      );
  }
    if (jobTitle) employee.basic.jobTitle = jobTitle;
    if (officialEmail) employee.basic.officialEmail = officialEmail;
    if (dateOfJoining) employee.basic.dateOfJoining = new Date(dateOfJoining);

    // Update employment details (first element in array assumed current employment)
    if (!employee.employment || employee.employment.length === 0) {
      employee.employment = [{}]; // initialize if empty
    }
    employee.employment[0].employeeType = employeeType || null;
    employee.employment[0].dateOfLeaving = dateOfLeaving ? new Date(dateOfLeaving) : employee.employment[0].dateOfLeaving;
    employee.employment[0].employeeId = employeeId || employee.employment[0].employeeId;
    employee.employment[0].esiNumber = esiNumber || employee.employment[0].esiNumber;
    employee.employment[0].pfNumber = pfNumber || employee.employment[0].pfNumber;
    if (typeof probationPeriod === "number")
    employee.employment[0].probationPeriod = probationPeriod;

    if (probationStatus)
    employee.employment[0].probationStatus = probationStatus;

    if (probationEndDate)
    employee.employment[0].probationEndDate = new Date(probationEndDate);
    else if (probationPeriod === 0)
    employee.employment[0].probationEndDate = null;


    await employee.save();
    res.status(200).json({ message: "Employment details updated successfully", employee });
  } catch (err) {
    console.error("Error updating employment details:", err);
    res.status(500).json({ message: "Failed to update employment details" });
  }
};

export const getEmployeeBasicDetailsController = async (req, res) => {
  try {
    const { employeeId, companyId } = req.query;

    if (!employeeId || !companyId) {
      return res
        .status(400)
        .json({ message: "employeeId and companyId are required" });
    }

    const data = await getEmployeeBasicDetails({ employeeId, companyId });

    return res.status(200).json(data);
  } catch (err) {
    console.error("getEmployeeBasicDetails error:", err);
    return res
      .status(400)
      .json({ message: err.message || "Unable to fetch employee details" });
  }
};

export const getEmployeeProfileController = async (req, res) => {
  try {
    const { employeeId } = req.params;
    if (!employeeId) {
      return res.status(400).json({ message: 'employeeId is required' });
    }

    const profile = await getEmployeeProfileById(employeeId);
    return res.status(200).json(profile);
  } catch (err) {
    console.error('getEmployeeProfile error:', err);
    return res.status(400).json({
      message: err.message || 'Unable to fetch employee profile',
    });
  }
};

export const getEmployeeByPhoneController = async (req, res) => {
  try {
    const { phoneNumber, companyId } = req.query;

    if (!phoneNumber || !companyId) {
      return res
        .status(400)
        .json({ message: 'phoneNumber and companyId are required' });
    }

    const employee = await getEmployeeByPhoneService(phoneNumber, companyId);
    return res.status(200).json(employee);
  } catch (err) {
    console.error('getEmployeeByPhone error:', err);
    return res
      .status(400)
      .json({ message: err.message || 'Unable to fetch employee' });
  }
};

export const getCompanyEmployees = async (req, res) => {
  try {
    const { companyId } = req.params;

    const employees = await Employee.find({ companyId }).select(
      'basic.fullName basic.initials basic.jobTitle basic.phone basic.officialEmail basic.branches basic.departments'
    );

    return res.status(200).json(employees);
  } catch (err) {
    console.error('getCompanyEmployees error', err);
    return res.status(500).json({ message: 'Server error' });
  }
};

export const updateEmployeeCustomDetails = async (req, res) => {
  try {
    const { id } = req.params;
    const { customFieldValues } = req.body;

    if (!Array.isArray(customFieldValues)) {
      return res.status(400).json({ message: "Invalid data format" });
    }

    let employee;

    // 1. Determine how to find the employee (By _id or Custom ID)
    if (mongoose.Types.ObjectId.isValid(id)) {
      employee = await Employee.findById(id);
    } else {
      // Search recursively in the employment array for the custom employeeId
      employee = await Employee.findOne({ "employment.employeeId": id });
    }

    if (!employee) {
      return res.status(404).json({ message: "Employee not found" });
    }

    // 2. Update the values
    employee.customFieldValues = customFieldValues.filter(
      (item) => item.value !== "" && item.value !== null && item.value !== undefined
    );

    await employee.save();

    return res.status(200).json({
      message: "Custom details updated successfully",
      customFieldValues: employee.customFieldValues,
    });
  } catch (error) {
    console.error("Error updating custom details:", error);
    return res.status(500).json({ message: "Server error" });
  }
};

export const uploadDocument = async (req, res) => {
  try {
    const { id } = req.params;
    const { category, name } = req.body;
    const file = req.file;

    if (!file) return res.status(400).json({ message: "No file uploaded" });

    const employee = await Employee.findById(id);
    if (!employee) return res.status(404).json({ message: "Employee not found" });

    const type = file.mimetype.includes('pdf') ? 'pdf' : 'image';
    const filePath = `/uploads/${file.filename}`;
    const fileSize = formatFileSize(file.size);

    const newDocObj = {
        name: name || file.originalname,
        category: category || 'Other',
        type: type,
        size: fileSize,
        filePath: filePath,
        uploadedOn: new Date(),
        verified: false
    };

    // 1. Check if document of this category already exists
    const existingDocIndex = employee.documents.findIndex(
        (doc) => doc.category === category
    );

    if (existingDocIndex !== -1) {
        // 2. If exists, delete the OLD file from server to save space
        const oldDoc = employee.documents[existingDocIndex];
        const relativePath = oldDoc.filePath.startsWith('/') 
        ? oldDoc.filePath.substring(1) 
        : oldDoc.filePath;
        
    const oldFilePath = path.join(process.cwd(), relativePath);
        if (fs.existsSync(oldFilePath)) {
            try {
                fs.unlinkSync(oldFilePath);
            } catch (err) {
                console.error("Failed to delete old file:", err);
            }
        }

        // 3. Update the existing array entry
        employee.documents[existingDocIndex] = {
            ...newDocObj,
            _id: oldDoc._id // Keep the same ID if you want, or generate new
        };
    } else {
        // 4. Push new if doesn't exist
        employee.documents.push(newDocObj);
    }

    await employee.save();

    // Return the updated document
    const updatedDoc = existingDocIndex !== -1 
        ? employee.documents[existingDocIndex] 
        : employee.documents[employee.documents.length - 1];

    res.status(201).json({ message: "Document uploaded", document: updatedDoc });
  } catch (err) {
    console.error("Upload Error:", err);
    res.status(500).json({ message: "Upload failed" });
  }
};

export const deleteDocument = async (req, res) => {
  try {
    const { id, docId } = req.params;

    const employee = await Employee.findById(id);
    if (!employee) return res.status(404).json({ message: "Employee not found" });

    // Find doc to get path for deletion
    const doc = employee.documents.id(docId);
    if (!doc) return res.status(404).json({ message: "Document not found" });

    // Remove file from server (optional, but good practice)
    // Note: Adjust path based on your folder structure relative to this controller
    const filePath = path.join(process.cwd(), doc.filePath); 
    if (fs.existsSync(filePath)) {
        fs.unlinkSync(filePath);
    }

    // Remove from DB
    employee.documents.pull(docId);
    await employee.save();

    res.status(200).json({ message: "Document deleted" });
  } catch (err) {
    console.error("Delete Error:", err);
    res.status(500).json({ message: "Delete failed" });
  }
};

export const updatePersonalDetails = async (req, res) => {
  try {
    const { id } = req.params;
    const updates = req.body; // Expecting { uanNumber: "123", panNumber: "ABC" }

    const employee = await Employee.findById(id);
    if (!employee) {
      return res.status(404).json({ message: "Employee not found" });
    }

    // Initialize personal object if it doesn't exist
    if (!employee.personal) {
      employee.personal = {};
    }

    // Loop through the body and update fields in employee.personal
    Object.keys(updates).forEach((key) => {
      // Security check: Only allow updates to fields defined in your personalDetailsSchema
      // You can add a whitelist array here if you want strict security
      employee.personal[key] = updates[key];
    });

    await employee.save();

    res.status(200).json({ 
      message: "Personal details updated successfully", 
      personal: employee.personal 
    });

  } catch (err) {
    console.error("Error updating personal details:", err);
    res.status(500).json({ message: "Failed to update details" });
  }
};

// ✅ 2. Verify Employee Attribute (Toggle status to 'verified')
export const verifyAttribute = async (req, res) => {
  try {
    const { id } = req.params;
    const { attribute } = req.body; // e.g., "aadhar", "uan", "face"

    // Whitelist valid verification keys based on your Schema
    const validAttributes = [
      "aadhar", 
      "pan", 
      "drivingLicense", 
      "voterId", 
      "uan", 
      "face", 
      "address", 
      "pastEmployment"
    ];

    if (!validAttributes.includes(attribute)) {
      return res.status(400).json({ message: `Invalid verification attribute: ${attribute}` });
    }

    const employee = await Employee.findById(id);
    if (!employee) {
      return res.status(404).json({ message: "Employee not found" });
    }

    // Initialize verification object if missing
    if (!employee.verification) {
      employee.verification = {};
    }
    
    // Initialize specific attribute object if missing
    if (!employee.verification[attribute]) {
      employee.verification[attribute] = {};
    }

    // Update status and timestamp
    employee.verification[attribute].status = "verified";
    employee.verification[attribute].verifiedOn = new Date();

    await employee.save();

    res.status(200).json({ 
      message: `${attribute} marked as verified`, 
      verification: employee.verification 
    });

  } catch (err) {
    console.error("Error verifying attribute:", err);
    res.status(500).json({ message: "Failed to verify attribute" });
  }
};


// ✅ GET COMPANY VERIFICATION SUMMARY
export const getCompanyVerificationSummary = async (req, res) => {
  try {
    const { companyId } = req.params;

    const employees = await Employee.find({ companyId })
      .select('basic.fullName basic.jobTitle verification'); // Select only needed fields

    const summary = employees.map(emp => {
      const v = emp.verification || {};
      
      // Calculate overall status
      let status = "Not Started";
      
      // Check if ANY key item is verified
      const isVerified = 
          v.aadhar?.status === 'verified' || 
          v.pan?.status === 'verified' || 
          v.drivingLicense?.status === 'verified' ||
          v.voterId?.status === 'verified' ||
          v.uan?.status === 'verified' ||
          v.face?.status === 'verified' ||
          v.address?.status === 'verified' ||
          v.pastEmployment?.status === 'verified';

      // Check for pending/in-progress
      const isPending = Object.values(v).some((item) => 
          ['pending', 'in-progress'].includes(item?.status)
      );

      if (isVerified) status = "Verified";
      else if (isPending) status = "Pending";
      
      return {
        _id: emp._id,
        name: emp.basic.fullName,
        designation: emp.basic.jobTitle,
        status: status
      };
    });

    res.status(200).json(summary);
  } catch (err) {
    console.error("Error fetching verification summary:", err);
    res.status(500).json({ message: "Server error" });
  }
};

export const getEmployeeById = async (req, res) => {
  console.log("--- DEBUG START: getEmployeeById ---");

  try {
    const { id } = req.params;
    const { companyId } = req.query;
    
    // START DEBUG LOGS
    console.log(`1. Inputs Received -> EmployeeID: ${id}, CompanyID: ${companyId}`);

    // IMPORTANT: Assuming 'user' comes from authentication middleware (req.user)
    // const user = req.user; 
    // console.log("2. Authenticated User:", user ? user._id : "User is UNDEFINED (Check Auth Middleware)");

    if (!companyId) {
      console.log("ERROR: companyId missing in query");
      return res.status(400).json({ message: "companyId is required" });
    }

    // 3. Find the employee
    console.log("3. Querying Database for Employee...");
    const employee = await Employee.findById(id)
      .populate("basic.branches", "name")
      .populate("basic.departments", "name");

    if (!employee) {
      console.log("ERROR: Employee not found in DB (Returning 404)");
      return res.status(404).json({ message: "Employee not found for user" });
    }
    console.log("SUCCESS: Employee found ->", employee._id);

    // 4. Confirm companyId
    console.log("4. Querying Database for Company...");
    const company = await Company.findById(companyId);

    if (!company) {
      console.log("ERROR: Company not found in DB (Returning 404)");
      return res.status(404).json({ message: "Company not found" });
    }
    console.log("SUCCESS: Company found ->", company.name);

    // // 5. Logic Checks
    // // Safety check: ensure user is defined before accessing properties
    // if (!user) {
    //     console.log("CRITICAL ERROR: 'user' variable is undefined. Cannot check permissions.");
    //     return res.status(500).json({ message: "Server Error: User not authenticated" });
    // }

    // const isUserInCompany = user.companies.some((cid) => cid.equals(company._id));
    // const isEmployeeInCompany = employee.companyId.equals(company._id);
    // const isUserListedInCompany = company.users.some((uid) => uid.equals(user._id));

    // console.log("5. Permission Checks:", {
    //     isUserInCompany,
    //     isEmployeeInCompany,
    //     isUserListedInCompany
    // });

    // if (!isUserInCompany) {
    //   console.log("ERROR: User not part of this company");
    //   return res.status(400).json({ message: "User not part of this company" });
    // }

    // if (!isEmployeeInCompany) {
    //   console.log("ERROR: Employee record not linked to this company");
    //   return res.status(400).json({ message: "Employee record not linked to this company" });
    // }

    // if (!isUserListedInCompany) {
    //   console.log("ERROR: User not listed in company users array");
    //   return res.status(400).json({ message: "User not listed in company users array" });
    // }

    // Send the employee data
    console.log("SUCCESS: Sending Data");
    res.status(200).json({ employee });
    
  } catch (err) {
    console.error("SERVER ERROR inside getEmployeeById:", err);
    res.status(500).json({ message: "Server error fetching employee" });
  }
};

export const getEmployeeByUserId = async (req, res) => {
  try {
    const { id } = req.params;
    const { companyId } = req.query;

   if (id === "new") {
        return res.status(200).json({ employee: null, isCreationMode: true });
    }

    // B. Validation check: Prevent Mongoose from crashing on invalid strings
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ message: "Invalid Employee ID format" });
    }

    // C. Check for companyId
    if (!companyId || !mongoose.Types.ObjectId.isValid(companyId)) {
      return res.status(400).json({ message: "Valid companyId is required" });
    }
    // 1. Find user by id
    const user = await User.findById(id);
    if (!user)
      return res.status(404).json({ message: "No user found" });

    // 2. Get the phone
    const phone = user.phoneNumber;

    // 3. Find the employee
    const employee = await Employee.findOne({ "basic.phone": phone })
    .populate("basic.branches", "name")
  .populate("basic.departments", "name");
    if (!employee)
      return res.status(404).json({ message: "Employee not found for user" });

    // 4. Confirm companyId is in user's companies, and user is in company.users
    const company = await Company.findById(companyId);
    if (!company)
      return res.status(404).json({ message: "Company not found" });

      const isUserInCompany = user.memberships.some(m => m.companyId.equals(company._id));
      const isEmployeeInCompany = employee.companyId.equals(company._id);
      const isUserListedInCompany = company.users.some(uid => uid.equals(user._id));

      if (!isUserInCompany) {
        return res.status(400).json({ message: "User does not have a membership in this company" });
      }

      if (!isEmployeeInCompany)
      return res
        .status(400)
        .json({ message: "Employee record not linked to this company" });

    if (!isUserListedInCompany)
      return res.status(400).json({ message: "User not listed in company users array" });

    // Send the employee data
    res.status(200).json({ employee });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error fetching employee" });
  }
};

export const toggleEmploymentStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const employee = await Employee.findById(id);

    if (!employee) {
      return res.status(404).json({ message: "Employee not found" });
    }

    // Toggle the status
    const newStatus = employee.employmentStatus === 'active' ? 'inactive' : 'active';
    employee.employmentStatus = newStatus;
    
    await employee.save();

    res.status(200).json({ 
      message: `Employee marked as ${newStatus}`, 
      status: newStatus 
    });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
};

export const downloadEmployeeBiodata = async (req, res) => {
  try {
      const { employeeId } = req.params;

      // Fetch employee and populate branches/departments if necessary
      const employee = await Employee.findById(employeeId)
          .populate('basic.branches basic.departments')
          .lean();

      if (!employee) return res.status(404).json({ message: "Employee not found" });

      const doc = new PDFDocument({ margin: 50, size: 'A4' });
      const filename = `Biodata_${employee.basic.fullName.replace(/\s+/g, '_')}.pdf`;

      // ADD THESE CACHE CONTROL HEADERS
      res.setHeader('Content-disposition', `attachment; filename="${filename}"`);
      res.setHeader('Content-type', 'application/pdf');
      res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate'); // <--- CRITICAL
      res.setHeader('Pragma', 'no-cache'); // <--- CRITICAL
      res.setHeader('Expires', '0');       // <--- CRITICAL

      doc.pipe(res);

      res.setHeader('Content-disposition', `attachment; filename="${filename}"`);
      res.setHeader('Content-type', 'application/pdf');
      doc.pipe(res);

      // --- STYLING HELPERS ---
      const primaryColor = '#206C5E';
      const secondaryColor = '#475569';
      const dividerColor = '#E2E8F0';

      // --- HEADER SECTION ---
      doc.rect(0, 0, 612, 120).fill(primaryColor); // Top Banner
      doc.fillColor('white').fontSize(24).text(employee.basic.fullName.toUpperCase(), 50, 40, { characterSpacing: 1 });
      doc.fontSize(12).text(employee.basic.jobTitle || 'Employee', 50, 70);
      doc.fontSize(10).text(`ID: ${employee.employment?.[0]?.employeeId || 'N/A'}`, 50, 88);

      // --- 1. BASIC INFORMATION ---
      doc.fillColor('black').fontSize(14).text('BASIC INFORMATION', 50, 150);
      doc.moveTo(50, 168).lineTo(540, 168).strokeColor(dividerColor).stroke();

      let y = 180;
      const drawField = (label, value, xPos) => {
        doc.fillColor(secondaryColor).fontSize(9).text(label, xPos, y);
        // Safety check: ensure value is a string and not null/undefined
        const displayValue = (value && value.toString()) ? value.toString() : '—';
        doc.fillColor('black').fontSize(10).text(displayValue, xPos, y + 12);
    };
    
    // Ensure date strings are valid before passing to new Date()
    const formatDate = (date) => {
        if (!date) return '—';
        const d = new Date(date);
        return isNaN(d.getTime()) ? '—' : d.toDateString();
    };
    
    // Use the wrapper:
    

      drawField('PHONE NUMBER', employee.basic.phone, 50);
      drawField('OFFICIAL EMAIL', employee.basic.officialEmail, 220);
      drawField('DATE OF JOINING', formatDate(employee.basic.dateOfJoining), 400);

      y += 40;
      drawField('GENDER', employee.basic.gender, 50);
      drawField('BRANCHES', employee.basic.branches?.map(b => b.name).join(', '), 220);
      drawField('DEPARTMENTS', employee.basic.departments?.map(d => d.name).join(', '), 400);

      // --- 2. PERSONAL DETAILS ---
      y += 60;
      doc.fillColor('black').fontSize(14).text('PERSONAL DETAILS', 50, y);
      doc.moveTo(50, y + 18).lineTo(540, y + 18).strokeColor(dividerColor).stroke();
      
      y += 30;
      drawField('DATE OF BIRTH', employee.personal?.dob ? new Date(employee.personal.dob).toDateString() : null, 50);
      drawField('BLOOD GROUP', employee.personal?.bloodGroup, 220);
      drawField('MARITAL STATUS', employee.personal?.maritalStatus, 400);

      y += 40;
      drawField('AADHAR NUMBER', employee.personal?.aadharNumber, 50);
      drawField('PAN NUMBER', employee.personal?.panNumber, 220);
      drawField('UAN NUMBER', employee.personal?.uanNumber, 400);

      y += 40;
      drawField('PERMANENT ADDRESS', employee.personal?.permanentAddress, 50);

      // --- 3. EMPLOYMENT HISTORY ---
      y += 60;
      doc.fillColor('black').fontSize(14).text('EMPLOYMENT HISTORY', 50, y);
      doc.moveTo(50, y + 18).lineTo(540, y + 18).strokeColor(dividerColor).stroke();
      
      y += 30;
      const currentJob = employee.employment?.[0] || {};
      drawField('EMPLOYEE TYPE', currentJob.employeeType, 50);
      drawField('PROBATION STATUS', currentJob.probationStatus, 220);
      drawField('ESI NUMBER', currentJob.esiNumber, 400);

      // --- 4. VERIFICATION STATUS ---
      y += 60;
      doc.rect(50, y, 490, 80).fill('#F8FAFC'); // Light background for box
      doc.fillColor(primaryColor).fontSize(11).text('VERIFICATION SUMMARY', 65, y + 15);
      
      const verifY = y + 40;
      const drawStatus = (label, status, x) => {
          const color = status === 'verified' ? '#10B981' : '#F59E0B';
          doc.fillColor('black').fontSize(8).text(label, x, verifY);
          doc.fillColor(color).fontSize(8).text(status?.toUpperCase() || 'NOT SUBMITTED', x, verifY + 12);
      };

      drawStatus('IDENTITY (KYC)', employee.verification?.aadhar?.status, 65);
      drawStatus('FACE VERIF', employee.verification?.face?.status, 165);
      drawStatus('ADDRESS', employee.verification?.address?.status, 265);
      drawStatus('DEVICE', employee.device?.status, 365);
      drawStatus('PREV. JOB', employee.verification?.pastEmployment?.status, 465);

      // --- FOOTER ---
      const pageCount = doc.bufferedPageRange().count;
      doc.fontSize(8).fillColor(secondaryColor).text(
          `Generated on ${new Date().toLocaleString()} | Sambalam HR Management System`,
          50,
          780,
          { align: 'center' }
      );

      doc.end();

  } catch (err) {
      console.error(err);
      res.status(500).json({ message: err.message });
  }
};