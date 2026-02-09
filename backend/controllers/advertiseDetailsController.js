import asyncHandler from "../middleware/asyncHandler.js";
import Company from "../models/companyModel.js";
import AdminDetails from "../models/adminDetailsModel.js";
import AdvertiseDetails from "../models/advertiseDetailsModel.js";

export const createAdvertiseDetails = asyncHandler(async (req, res) => {
  const {
    adminDetailsId,
    companyId,
    featuresInterestedIn,
    heardFrom,
    salaryRange,
  } = req.body;

  if (!adminDetailsId || !companyId) {
    return res
      .status(400)
      .json({ message: "adminDetailsId and companyId are required" });
  }

  const adminDetails = await AdminDetails.findById(adminDetailsId);
  const company = await Company.findById(companyId);

  if (!adminDetails || !company) {
    return res.status(404).json({ message: "AdminDetails or Company not found" });
  }

  const adv = await AdvertiseDetails.create({
    adminId: adminDetailsId,  // ✅ Match schema field name
    companyId: companyId,     // ✅ Match schema field name
    featuresInterestedIn: Array.isArray(featuresInterestedIn) 
      ? featuresInterestedIn : [],
    heardFrom: heardFrom || null,
    salaryRange: salaryRange || null,
  });

  company.advertiseDetails = adv._id;
  await company.save();

  res.status(201).json({
    message: "Advertise details saved",
    advertiseDetailsId: adv._id,
  });
});
