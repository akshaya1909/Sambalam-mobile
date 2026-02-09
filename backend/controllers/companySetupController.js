import CompanySetup from '../models/companySetupModel.js';

// Step 1: Company Info
export const createCompanyInfo = async (req, res) => {
  try {
    const {
      companyName, companyType, industryType, businessCategory,
      registrationNumber, gstin, numberOfEmployees, createdBy
    } = req.body;

    const companyLogo = req.file ? `uploads/${req.file.filename}` : null;

    const setup = new CompanySetup({
      companyName,
      companyType,
      industryType,
      businessCategory,
      registrationNumber,
      gstin,
      numberOfEmployees,
      companyLogo,
      createdBy
    });

    const saved = await setup.save();
    res.status(201).json(saved);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Step 2: Contact Info
export const updateContactDetails = async (req, res) => {
  try {
    const { id } = req.params;
    const update = await CompanySetup.findByIdAndUpdate(
      id,
      { $set: req.body },
      { new: true }
    );
    res.json(update);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Step 3: Admin Info
export const updateAdminInfo = async (req, res) => {
  try {
    const { id } = req.params;
    const update = await CompanySetup.findByIdAndUpdate(
      id,
      { $set: { admin: req.body } },
      { new: true }
    );
    res.json(update);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Step 4: Settings
export const updateSettings = async (req, res) => {
  try {
    const { id } = req.params;
    const update = await CompanySetup.findByIdAndUpdate(
      id,
      { $set: { settings: req.body } },
      { new: true }
    );
    res.json(update);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Step 5: Compliance
export const updateCompliance = async (req, res) => {
  try {
    const { id } = req.params;
    const update = await CompanySetup.findByIdAndUpdate(
      id,
      { $set: { compliance: req.body } },
      { new: true }
    );
    res.json(update);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Step 6: Documents Upload
export const uploadDocuments = async (req, res) => {
  try {
    const { id } = req.params;
    const fileFields = [
      'certificateOfIncorporation',
      'panCard',
      'gstRegistration',
      'authorizedSignatoryId',
      'pfEsiRegistration',
      'moaAoa',
      'professionalTaxCertificate',
      'shopEstablishmentLicense',
      'leavePolicyDocument'
    ];

    const documentPaths = {};
    fileFields.forEach((field) => {
      if (req.files[field]) {
        documentPaths[`documents.${field}`] = req.files[field][0].path;
      }
    });

    const update = await CompanySetup.findByIdAndUpdate(id, { $set: documentPaths }, { new: true });
    res.json(update);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Get Final Data
export const getCompanySetup = async (req, res) => {
  try {
    const { id } = req.params;
    const data = await CompanySetup.findById(id);
    if (!data) return res.status(404).json({ error: 'Company setup not found' });
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
