// routes/employeeRoutes.js
import express from "express";
import { addEmployee, updateEmployee, deleteEmployee, updateEmploymentDetails, getEmployeeBasicDetailsController, getEmployeeProfileController, getEmployeeByPhoneController, getCompanyEmployees,
  updateEmployeeCustomDetails, uploadDocument, deleteDocument, updatePersonalDetails, verifyAttribute, getCompanyVerificationSummary, getEmployeeById, getEmployeeByUserId, toggleEmploymentStatus,
  downloadEmployeeBiodata } from "../controllers/employeeController.js";
import upload from "../middleware/uploadMiddleware.js";
import UserDetails from "../models/userDetailsModel.js";

const router = express.Router();

// ✅ Add new employee
router.post("/", upload.single("profilePic"), addEmployee);
router.get("/basic", getEmployeeBasicDetailsController);
router.get('/by-phone', getEmployeeByPhoneController);
router.get('/profile/:employeeId', getEmployeeProfileController);
router.get('/company/:companyId', getCompanyEmployees);
router.get('/company/:companyId/verification-summary', getCompanyVerificationSummary);
router.get("/get/:id", getEmployeeById);
router.get("/user/:id", getEmployeeByUserId);
router.get("/biodata/:employeeId", downloadEmployeeBiodata);
// ✅ Update employee
router.put("/:id", upload.single("profilePic"), updateEmployee);

router.delete("/:id", deleteEmployee);
router.put("/:id/employment", updateEmploymentDetails);

// ✅ Get employee (user details) by ID
router.get("/:id", async (req, res) => {
  try {
    const user = await UserDetails.findOne({ user: req.params.id });

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }
    res.json(user);
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});
router.put("/:id/custom-details", updateEmployeeCustomDetails);
router.post("/:id/documents", upload.single('file'), uploadDocument);
router.delete("/:id/documents/:docId", deleteDocument);
router.put("/:id/personal", updatePersonalDetails);
router.post("/:id/verify", verifyAttribute);
router.put("/:id/toggle-status", toggleEmploymentStatus);

export default router;
