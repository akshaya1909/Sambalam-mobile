import mongoose from 'mongoose';

const companySetupSchema = new mongoose.Schema({
  // createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },

  // Step 1: Company Info
  companyName: String,
  companyType: String,
  industryType: String,
  businessCategory: String,
  registrationNumber: String,
  gstin: String,
  numberOfEmployees: String,
  companyLogo: String,

  // Step 2: Contact Info
  email: String,
  phone: String,
  website: String,
  address1: String,
  address2: String,
  city: String,
  state: String,
  pin: String,
  country: { type: String, default: 'India' },

  // Step 3: Admin Info
  admin: {
    name: String,
    designation: String,
    number: String,
    email: String,
  },

  // Step 4: Company Settings
  settings: {
    workingDays: [String],
    offDays: [String],
    officeStartTime: String,
    officeStartAmPm: String,
    officeEndTime: String,
    officeEndAmPm: String,
    breakDuration: String,
    salaryCycleStart: String,
    salaryPayMode: String,
    currency: String
  },
  
  // Step 5: Compliance
   compliance: {
    pfApplicable: String,
    esicApplicable: String,
    ptApplicable: String,
    wageZone: String,
    jurisdiction: { type: String, default: 'Tamil Nadu' },
    leavePolicy: String
  },


  // Step 6: Documents
  documents: {
    certificateOfIncorporation: String,
    panCard: String,
    gstRegistration: String,
    authorizedSignatoryId: String,
    pfEsiRegistration: String,
    moaAoa: String,
    professionalTaxCertificate: String,
    shopEstablishmentLicense: String,
    leavePolicyDocument: String,
  },
}, { timestamps: true });

const CompanySetup = mongoose.model('CompanySetup', companySetupSchema);
export default CompanySetup;
