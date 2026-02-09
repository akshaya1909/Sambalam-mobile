import { LeaveAndBalance } from "../models/leaveBalanceModel.js";
import Employee from "../models/employeeModel.js";
import Company from "../models/companyModel.js";
import AdminDetails from "../models/adminDetailsModel.js";

function computeNewBalance(current, allowed, carry, taken, maxCarry) {
  let newBalance = carry + allowed - taken;
  if (newBalance < 0) newBalance = newBalance; // negative if overused
  else newBalance = Math.min(newBalance, allowed + maxCarry);
  return newBalance;
}


// Helper to recalculate balances based on policy changes
const recalculateBalances = (existingBalances, oldPolicies, newPolicies) => {
  // Create a map of Old Allowed values: { leaveTypeId: allowedLeaves }
  const oldAllowedMap = {};
  oldPolicies.forEach(p => {
    // Handle both populated object or direct ID
    const id = p.leaveTypeId._id ? p.leaveTypeId._id.toString() : p.leaveTypeId.toString();
    oldAllowedMap[id] = p.allowedLeaves;
  });

  return newPolicies.map(newPolicy => {
    const newTypeId = newPolicy.leaveTypeId;
    
    // Find existing balance for this type
    const existingBalance = existingBalances.find(b => 
      b.leaveTypeId.toString() === newTypeId.toString()
    );

    const newAllowed = Number(newPolicy.allowedLeaves);

    if (existingBalance) {
      // 1. Get the Old Allowed amount (default to 0 if not found)
      const oldAllowed = oldAllowedMap[newTypeId.toString()] || 0;
      
      // 2. Calculate the difference (Delta)
      // Example: Old = 6, New = 10. Delta = +4.
      // Example: Old = 10, New = 6. Delta = -4.
      const delta = newAllowed - oldAllowed;

      // 3. Apply Delta to Current Balance
      const updatedCurrent = existingBalance.current + delta;

      return {
        leaveTypeId: newTypeId,
        current: updatedCurrent < 0 ? 0 : updatedCurrent, // Prevent negative balance if desired
        taken: existingBalance.taken
      };
    } else {
      // New Leave Type being added? Initialize with full allowance
      return {
        leaveTypeId: newTypeId,
        current: newAllowed,
        taken: 0
      };
    }
  });
};

const mergeBalances = (existingBalances, newPolicies) => {
  // If a new policy is added, initialize its balance
  return newPolicies.map(policy => {
    const existing = existingBalances.find(b => b.leaveTypeId.toString() === policy.leaveTypeId.toString());
    if (existing) return existing;
    return {
      leaveTypeId: policy.leaveTypeId,
      current: policy.allowedLeaves, // Initialize with allowed
      taken: 0
    };
  });
};


export const upsertLeaveAndBalance = async (req, res) => {
  try {
    const { employeeId, policyType, policies } = req.body; // policies is array of {leaveTypeId, allowed, carry}

    if (!employeeId || !policyType || !policies) {
      return res.status(400).json({ message: "Missing fields" });
    }

    let doc = await LeaveAndBalance.findOne({ employeeId });

    if (!doc) {
      // Create New
      const initialBalances = policies.map(p => ({
        leaveTypeId: p.leaveTypeId,
        current: Number(p.allowedLeaves), // Initial balance = allowed
        taken: 0
      }));

      doc = new LeaveAndBalance({
        employeeId,
        policyType,
        policies,
        balances: initialBalances
      });
    } else {
      // Update Existing
      // If switching types (Monthly <-> Yearly), reset balances logic might be needed
      // Here we assume frontend handles the confirmation and sends fresh data
      const oldPolicies = doc.toObject().policies;
      doc.policyType = policyType;
      doc.policies = policies;
      
      // Ensure balances exist for all active policies
      doc.balances = recalculateBalances(doc.balances, oldPolicies, policies);
    }

    await doc.save();
    // Populate leave type names for frontend
    await doc.populate('policies.leaveTypeId balances.leaveTypeId');
    
    res.status(200).json({ message: "Leave policy saved", data: doc });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Error saving leave policy" });
  }
};

  export const getLeavePolicyByEmployeeId = async (req, res) => {
    try {
      const { employeeId } = req.params;
      if (!employeeId) {
        return res.status(400).json({ message: "EmployeeId parameter missing" });
      }

      const employee = await Employee.findById(employeeId);
      if (!employee) return res.status(404).json({ message: "Employee not found" });
  
      const doc = await LeaveAndBalance.findOne({ employeeId })
      .populate('policies.leaveTypeId')
      .populate('balances.leaveTypeId');
      if (!doc) {
      return res.status(200).json({ data: null }); 
    }
  
      res.status(200).json({ data: doc });
    } catch (err) {
      res.status(500).json({ message: "Error fetching leave policy" });
    }
  };
  
  export const resetLeavePolicy = async (req, res) => {
    try {
      const { employeeId } = req.params;
      if (!employeeId) {
        return res.status(400).json({ message: "EmployeeId parameter missing" });
      }
  
      const employee = await Employee.findById(employeeId);
      if (!employee) return res.status(404).json({ message: "Employee not found" });
  
      // Option 1: Remove the entire leave policy document for this employee
      // await LeaveAndBalance.findOneAndUpdate({ employeeId });
  
      // Option 2: Or clear leavePolicy field but keep the document 
      await LeaveAndBalance.findOneAndDelete({ employeeId });
  
      res.status(200).json({ message: "Leave policy reset successfully" });
    } catch (err) {
      res.status(500).json({ message: "Error resetting" });
    }
  };
  
  export const updateLeaveBalances = async (req, res) => {
    // This function handles the periodic cron job logic (month/year end)
    // Kept as per your previous code for periodic updates
    const { employeeId } = req.body;
    const doc = await LeaveAndBalance.findOne({ employeeId });
    if (!doc) return res.status(404).json({ message: "Not found" });
  
    const { policyType, policies, balances, lastProcessed } = doc;
    const now = new Date();
    let shouldUpdate = false;
    let periodStart;

    if (policyType === "Monthly") {
      periodStart = new Date(now.getFullYear(), now.getMonth(), 1);
    } else {
      periodStart = new Date(now.getFullYear(), 0, 1);
    }
    
    // Simple check if processed this period
    if (!lastProcessed || lastProcessed < periodStart) shouldUpdate = true;
  
    if (shouldUpdate) {
       // Loop through policies and update balances array
       doc.balances = policies.map(policy => {
            const existingBal = balances.find(b => b.leaveTypeId.toString() === policy.leaveTypeId.toString());
            const prevCurrent = existingBal ? existingBal.current : 0;
            const allowed = policy.allowedLeaves;
            const maxCarry = policy.carryForwardLeaves;

            // Simple carry logic: New Balance = Allowed + Min(Previous, MaxCarry)
            // Note: This logic assumes 'prevCurrent' is what remains at end of period. 
            let carryAmount = Math.min(prevCurrent, maxCarry);
            
            return {
                leaveTypeId: policy.leaveTypeId,
                current: allowed + carryAmount,
                taken: 0
            };
       });

      doc.lastProcessed = now;
      await doc.save();
    }
  
    res.status(200).json({ data: doc });
};

  // In controllers/leaveAndBalanceController.js

export const updateEmployeeLeaveBalance = async (req, res) => {
    try {
      const { employeeId, balances } = req.body; 
      
      const doc = await LeaveAndBalance.findOne({ employeeId });
      if (!doc) return res.status(404).json({ message: "Policy not found" });
  
      balances.forEach(update => {
        const target = doc.balances.find(b => b.leaveTypeId.toString() === update.leaveTypeId);
        if (target) {
          target.current = Number(update.current);
        }
      });
  
      await doc.save();
      // Populate to return full data for UI update
      await doc.populate('policies.leaveTypeId balances.leaveTypeId');

      res.status(200).json({ message: "Balances updated", data: doc });
    } catch (err) {
      res.status(500).json({ message: "Error updating balances" });
    }
};

export const getCompanyLeaveDetails = async (req, res) => {
  try {
    const { companyId } = req.params;
    const { branchId, departmentIds } = req.query;

    const empFilter = { companyId };
    if (branchId && branchId !== 'null') {
      empFilter["basic.branches"] = { $in: [branchId] };
    }
    if (departmentIds) {
  const depts = departmentIds.split(',');
  empFilter["basic.departments"] = { $in: depts };
}

    // 1. Fetch Employees
    const employees = await Employee.find(empFilter) // Used direct companyId check
      .select("_id basic.fullName basic.phone basic.jobTitle basic.profilePic")
      .lean();

    const empIds = employees.map(emp => emp._id);

    // 2. Fetch Leave Records
    const leaveDetailsList = await LeaveAndBalance.find({ employeeId: { $in: empIds } })
      .populate("balances.leaveTypeId", "name code") // Try to populate
      .lean();

    // Map for quick lookup
    const empIdToLeave = {};
    leaveDetailsList.forEach(leave => {
      if (leave.employeeId) {
        empIdToLeave[leave.employeeId.toString()] = leave;
      }
    });

    // 3. Construct Response
    const data = employees.map(emp => {
      const record = empIdToLeave[emp._id.toString()] || null;
      
      const balanceMap = {};
      let policyType = "-";

      if (record) {
        policyType = record.policyType || "Monthly";
        
        if (Array.isArray(record.balances)) {
          record.balances.forEach(b => {
             // --- FIX: Handle both Populated Object AND Raw String ID ---
             // If populated, use _id. If raw string, use it directly.
             const typeId = b.leaveTypeId?._id 
                ? b.leaveTypeId._id.toString() 
                : b.leaveTypeId?.toString();

             if (typeId) {
               balanceMap[typeId] = b.current;
             }
          });
        }
      }

      return {
        _id: emp._id,
        fullName: emp.basic.fullName,
        phone: emp.basic.phone,
        jobTitle: emp.basic.jobTitle,
        profilePic: emp.basic.profilePic,
        leavePolicyType: policyType,
        balanceMap: balanceMap, // Correctly keyed map
        rawBalances: record?.balances || []
      };
    });

    res.status(200).json(data);

  } catch (error) {
    console.error("Error fetching company leave details:", error);
    res.status(500).json({ message: "Failed to get leave and balance details" });
  }
};


export const createLeaveRequest = async (req, res) => {
  try {
    const { employeeId, companyId, fromDate, toDate, isHalfDay, leaveTypeId, reason } = req.body;
    const file = req.file; // From multer middleware

    if (!employeeId || !companyId || !leaveTypeId || !reason) {
      return res.status(400).json({ message: "All required fields must be filled" });
    }

    const doc = await LeaveAndBalance.findOne({ employeeId });
    if (!doc) return res.status(404).json({ message: "Leave policy not found for employee" });

    const newRequest = {
      leaveTypeId,
      fromDate: new Date(fromDate),
      toDate: new Date(toDate),
      isHalfDay: isHalfDay === 'true', // Handle form-data boolean
      reason,
      documentUrl: file ? `/uploads/${file.filename}` : null,
      status: "pending"
    };

    // 1. Save to Employee's Leave Record
    doc.leaveRequests.push(newRequest);
    await doc.save();

    // 2. Get the generated ID of the last request
    const createdRequest = doc.leaveRequests[doc.leaveRequests.length - 1];

    // 3. Store reference in Company model
    await Company.findByIdAndUpdate(companyId, {
      $push: { leaveRequests: createdRequest._id }
    });

    res.status(201).json({ message: "Leave request submitted successfully", data: createdRequest });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Failed to submit leave request" });
  }
};

export const getCompanyLeaveRequests = async (req, res) => {
  try {
    const { companyId } = req.params;
    const { branchId, departmentIds } = req.query;

    const empFilter = { companyId };
    if (branchId && branchId !== 'null') empFilter["basic.branches"] = { $in: [branchId] };
    if (departmentIds) empFilter["basic.departments"] = { $in: departmentIds.split(',') };

    // Get authorized employee IDs
    const employees = await Employee.find(empFilter).select("_id basic.fullName basic.profilePic").lean();
    const empIds = employees.map(e => e._id);

    // Find leave records for these employees
    const leaveDocs = await LeaveAndBalance.find({ employeeId: { $in: empIds } })
      .populate("leaveRequests.leaveTypeId", "name")
      .lean();

    let allRequests = [];
    leaveDocs.forEach(doc => {
      const empInfo = employees.find(e => e._id.toString() === doc.employeeId.toString());
      
      doc.leaveRequests.forEach(req => {
        allRequests.push({
          ...req,
          employeeId: doc.employeeId,
          employeeName: empInfo?.basic?.fullName || "Unknown",
          profilePic: empInfo?.basic?.profilePic,
          leaveType: req.leaveTypeId?.name || "Leave",
          // Format dates for frontend
          startDate: req.fromDate.toISOString().split('T')[0],
          endDate: req.toDate.toISOString().split('T')[0],
          days: Math.ceil((req.toDate - req.fromDate) / (1000 * 60 * 60 * 24)) + 1
        });
      });
    });

    res.status(200).json(allRequests);
  } catch (error) {
    res.status(500).json({ message: "Failed to fetch leave requests" });
  }
};

// Handle Approve/Decline
// Handle Approve/Decline
export const updateLeaveRequestStatus = async (req, res) => {
  try {
    const { employeeId, requestId, status, deciderUserId } = req.body; 

    if (!['approved', 'rejected'].includes(status)) {
      return res.status(400).json({ message: "Invalid status" });
    }

    const doc = await LeaveAndBalance.findOne({ employeeId });
    if (!doc) return res.status(404).json({ message: "Leave policy not found" });

    const leaveReq = doc.leaveRequests.id(requestId);
    if (!leaveReq) return res.status(404).json({ message: "Request not found" });

    // 1. Find the AdminDetail record for the decider
    const decider = await AdminDetails.findOne({ userId: deciderUserId });

    leaveReq.status = status;
    leaveReq.decidedAt = new Date();
    leaveReq.decidedBy = decider ? decider._id : null;
    
    // 2. Logic: If approved, adjust balances
    if (status === 'approved') {
      const balanceObj = doc.balances.find(
        b => b.leaveTypeId.toString() === leaveReq.leaveTypeId.toString()
      );

      if (balanceObj) {
        // Calculate days: (endDate - startDate) + 1
        let daysTaken = 0;
        if (leaveReq.isHalfDay) {
          daysTaken = 0.5;
        } else {
          const diffTime = Math.abs(new Date(leaveReq.toDate) - new Date(leaveReq.fromDate));
          daysTaken = Math.ceil(diffTime / (1000 * 60 * 60 * 24)) + 1;
        }

        // Allow negative balance as requested
        balanceObj.current -= daysTaken;
        balanceObj.taken += daysTaken;
      }
    }

    await doc.save();
    res.status(200).json({ 
      message: `Request ${status} successfully`, 
      newBalance: doc.balances 
    });
  } catch (error) {
    console.error("Update Status Error:", error);
    res.status(500).json({ message: "Update failed", error: error.message });
  }
};

export const getEmployeeLeaveRequests = async (req, res) => {
  try {
    const { employeeId } = req.params;

    // Find the leave document for this specific employee
    const doc = await LeaveAndBalance.findOne({ employeeId })
      .populate("leaveRequests.leaveTypeId", "name")
      .lean();

    if (!doc) {
      return res.status(200).json({ pending: [], history: [] });
    }

    // Separate requests based on status
    const pending = doc.leaveRequests.filter(r => r.status === 'pending');
    const history = doc.leaveRequests.filter(r => r.status !== 'pending');

    // Sort by most recent first
    const sortByDate = (a, b) => new Date(b.requestedAt) - new Date(a.requestedAt);

    res.status(200).json({
      pending: pending.sort(sortByDate),
      history: history.sort(sortByDate)
    });
  } catch (error) {
    console.error("Error fetching employee leave requests:", error);
    res.status(500).json({ message: "Failed to fetch your leave requests" });
  }
};