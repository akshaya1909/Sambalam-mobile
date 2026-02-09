import Reimbursement from "../models/reimbursementModel.js";
import Company from "../models/companyModel.js";
import EarningTransaction from "../models/EarningTransactionModel.js"; // To auto-add to payroll if approved

// POST Create Request
export const createReimbursement = async (req, res) => {
  try {
    const { employeeId, companyId, amount, dateOfPayment, notes } = req.body;
    
    // Handle File Uploads (Assuming multer middleware processed them)
    // req.files would be array if multiple, or req.file if single. 
    // Adjust based on your multer setup. Here assuming array 'attachments'
    const attachments = req.files ? req.files.map(f => ({
      name: f.originalname,
      url: `/uploads/${f.filename}`, // or S3 URL
      type: f.mimetype.includes('pdf') ? 'pdf' : 'image'
    })) : [];

    const reimbursement = await Reimbursement.create({
      employeeId,
      companyId,
      amount: Number(amount),
      dateOfPayment: dateOfPayment ? new Date(dateOfPayment) : new Date(),
      notes,
      attachments,
      status: 'pending'
    });

    // Optional: Push to Company Model if you want direct ref (Not strictly needed if you query by companyId)
    // await Company.findByIdAndUpdate(companyId, { $push: { reimbursements: reimbursement._id } });

    res.status(201).json({ message: "Reimbursement requested", reimbursement });
  } catch (error) {
    console.error("Create Reimbursement Error:", error);
    res.status(500).json({ message: "Server error", error: error.message });
  }
};

// GET Requests (Filter by status/month)
export const getReimbursements = async (req, res) => {
  try {
    const { companyId, employeeId, status, month, year } = req.query;
    
    let query = { companyId };
    if (employeeId) query.employeeId = employeeId;
    if (status && status !== 'All') query.status = status.toLowerCase();

    // Date Filter (Requested Date or Date of Payment)
    if (month && year) {
        const start = new Date(year, month - 1, 1);
        const end = new Date(year, month, 0, 23, 59, 59);
        query.requestedOn = { $gte: start, $lte: end };
    }

    const reimbursements = await Reimbursement.find(query).sort({ requestedOn: -1 });
    res.json(reimbursements);
  } catch (error) {
    res.status(500).json({ message: "Failed to fetch reimbursements" });
  }
};

// PUT Update Status (Approve/Reject)
export const updateReimbursementStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status, adminId } = req.body; // 'approved' or 'rejected'

    const reimbursement = await Reimbursement.findByIdAndUpdate(
      id, 
      { status, processedBy: adminId, processedOn: new Date() },
      { new: true }
    );

    if (status === 'approved') {
        // AUTO-ADD TO PAYROLL EARNINGS
        await EarningTransaction.create({
            employeeId: reimbursement.employeeId,
            type: 'Reimbursement',
            amount: reimbursement.amount,
            description: `Reimbursement Approved: ${reimbursement.notes || ''}`,
            transactionDate: new Date(),
            payMonth: new Date().getMonth() + 1, // Current Month Payroll
            payYear: new Date().getFullYear(),
            processed: false
        });
    }

    res.json({ message: `Reimbursement ${status}`, reimbursement });
  } catch (error) {
    res.status(500).json({ message: "Update failed" });
  }
};

export const getPendingReimbursements = async (req, res) => {
    try {
      const { companyId } = req.query;
      if (!companyId) return res.status(400).json({ message: "Company ID required" });
  
      // 1. Find requests
      const requests = await Reimbursement.find({ 
        companyId, 
        status: 'pending' 
      })
      .sort({ requestedOn: -1 })
      .populate({
          path: 'employeeId',
          select: 'basic.fullName basic.profilePic' // Adjust based on your Employee Schema structure
      })
      .lean();
  
      // 2. Format response to include flat employeeName
      const formattedRequests = requests.map(req => ({
          ...req,
          employeeName: req.employeeId?.basic?.fullName || 'Unknown Employee',
          employeePhoto: req.employeeId?.basic?.profilePic || null,
          // Keep original employeeId string for updates
          employeeId: req.employeeId?._id || req.employeeId 
      }));
  
      res.status(200).json(formattedRequests);
    } catch (error) {
      console.error("Get Pending Reimbursements Error:", error);
      res.status(500).json({ message: "Server error" });
    }
  };
  
  // PUT Update Reimbursement Status (Approve/Reject)
  export const updateReimbursementStatusByAdmin = async (req, res) => {
    try {
      const { id } = req.params;
      const { status, adminId } = req.body; // status: 'approved' | 'rejected'
  
      if (!['approved', 'rejected'].includes(status)) {
        return res.status(400).json({ message: "Invalid status" });
      }
  
      const reimbursement = await Reimbursement.findByIdAndUpdate(
        id,
        { 
          status, 
          processedBy: adminId, 
          processedOn: new Date() 
        },
        { new: true }
      );
  
      if (!reimbursement) {
        return res.status(404).json({ message: "Reimbursement not found" });
      }
  
      // Logic: If approved, add to Payroll Earnings automatically
      if (status === 'approved') {
        await EarningTransaction.create({
          employeeId: reimbursement.employeeId,
          type: 'Reimbursement',
          amount: reimbursement.amount,
          description: `Approved: ${reimbursement.notes || 'Expense claim'}`,
          transactionDate: new Date(),
          payMonth: new Date().getMonth() + 1,
          payYear: new Date().getFullYear(),
          processed: false
        });
      }
  
      res.json({ message: `Reimbursement ${status} successfully`, reimbursement });
    } catch (error) {
      console.error("Update Reimbursement Error:", error);
      res.status(500).json({ message: "Update failed" });
    }
  };