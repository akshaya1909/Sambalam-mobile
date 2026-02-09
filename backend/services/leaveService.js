// services/leaveService.js
import Employee from "../models/employeeModel.js";
import Company from "../models/companyModel.js";
import { LeaveAndBalance } from "../models/leaveBalanceModel.js";

export const getLeaveBalanceForEmployee = async ({ employeeId, companyId }) => {
  // 1. make sure company exists
  const company = await Company.findById(companyId).lean();
  if (!company) {
    throw new Error("Company not found");
  }

  // 2. make sure employee exists and belongs to that company
  const employee = await Employee.findOne({
    _id: employeeId,
    companyId: companyId,
  }).lean();

  if (!employee) {
    throw new Error("Employee not found in this company");
  }

  // 3. get leave balance doc
  const doc = await LeaveAndBalance.findOne({ employeeId }).lean();
  if (!doc) {
    // no document yet → return zeros
    return {
      employeeId,
      companyId,
      leaveBalance: {
        priviledgeLeave: { current: 0, taken: 0 },
        sickLeave: { current: 0, taken: 0 },
        casualLeave: { current: 0, taken: 0 },
      },
    };
  }

  return {
    employeeId,
    companyId,
    leaveBalance: doc.leaveBalance,
    leavePolicy: doc.leavePolicy,
  };
};


export const createLeaveRequest = async ({
    employeeId,
    companyId,
    fromDate,
    toDate,
    isHalfDay,
    type,
    reason,
    documentUrl,
  }) => {
    // 1. Ensure employee belongs to this company
    const employee = await Employee.findOne({ _id: employeeId, companyId }).lean();
    if (!employee) {
      throw new Error("Employee not found in this company");
    }
  
    // 2. Ensure a LeaveAndBalance doc exists
    let doc = await LeaveAndBalance.findOne({ employeeId });
    if (!doc) {
      throw new Error("Leave setup not found for this employee");
    }
  
    // 3. Push new request
    const request = {
      fromDate,
      toDate,
      isHalfDay,
      type,       // "Casual" | "Privileged" | "Sick" | "Unpaid"
      reason,
      documentUrl: documentUrl || null,
      status: "pending",
    };
  
    doc.leaveRequests.push(request);
    await doc.save();

    await Company.findByIdAndUpdate(
        companyId,
        { $push: { leaveRequests: doc.leaveRequests[doc.leaveRequests.length - 1]._id } }
      );
  
    // Return the last pushed request (with _id, timestamps, etc.)
    const created = doc.leaveRequests[doc.leaveRequests.length - 1];
    return created;
  };


  export const getEmployeeLeaveRequests = async ({ employeeId }) => {
    const doc = await LeaveAndBalance.findOne({ employeeId })
      .select('leaveRequests')
      .lean();
    
    if (!doc) {
      return { pending: [], history: [] };
    }
  
    // Filter requests
    const pending = doc.leaveRequests.filter(req => req.status === 'pending');
    const history = doc.leaveRequests.filter(req => req.status !== 'pending');
  
    return {
      pending,
      history,
      totalPending: pending.length,
      totalHistory: history.length
    };
  };


  export const getCompanyPendingLeaveRequests = async (companyId) => {
    // 1. Get company users -> employees of this company
    const employees = await Employee.find({ companyId })
      .select("_id basic.fullName basic.initials basic.phone")
      .lean();
  
    if (!employees.length) return [];
  
    const employeeIdMap = new Map(
      employees.map((e) => [e._id.toString(), e])
    );
    const employeeIds = employees.map((e) => e._id);
  
    // 2. Get LeaveAndBalance docs for these employees
    const labs = await LeaveAndBalance.find({
      employeeId: { $in: employeeIds },
    })
      .select("employeeId leaveRequests")
      .populate("leaveRequests.leaveTypeId", "name")
      .lean();
  
    const pendingItems = [];
  
    labs.forEach((lab) => {
      const empId = lab.employeeId.toString();
      const emp = employeeIdMap.get(empId);
      if (!emp) return;
  
      (lab.leaveRequests || []).forEach((lr) => {
        if (lr.status !== "pending") return;
  
        const from = new Date(lr.fromDate);
        const to = new Date(lr.toDate);
  
        // inclusive days
        const diffMs = to.setHours(0, 0, 0, 0) - from.setHours(0, 0, 0, 0);
        const days = (diffMs / (1000 * 60 * 60 * 24)) + 1;
        const durationLabel = lr.isHalfDay ? "Half Day" : `${days} Day${days > 1 ? "s" : ""}`;
  
        pendingItems.push({
          id: lr._id.toString(),
          employeeId: empId,
          name: emp.basic.fullName,
          initials: emp.basic.initials || (emp.basic.fullName?.[0] || "U").toUpperCase(),
          fromDate: lr.fromDate,
          toDate: lr.toDate,
          isHalfDay: lr.isHalfDay,
          type: lr.type,
          leaveTypeName: lr.leaveTypeId?.name || "Unspecified",
          reason: lr.reason,
          documentUrl: lr.documentUrl,
          requestedAt: lr.requestedAt,
          status: lr.status,
          durationLabel,
        });
      });
    });
  
    // sort latest first
    pendingItems.sort(
      (a, b) => new Date(b.requestedAt) - new Date(a.requestedAt)
    );
  
    return pendingItems;
  };

  export const updateLeaveRequestStatus = async ({
    employeeId,
    leaveRequestId,
    status,
  }) => {
    if (!["approved", "rejected"].includes(status)) {
      throw new Error("Invalid status");
    }
  
    const lab = await LeaveAndBalance.findOne({ employeeId }).exec();
    if (!lab) {
      throw new Error("LeaveAndBalance not found for employee");
    }
  
    const reqSubdoc = lab.leaveRequests.id(leaveRequestId);
    if (!reqSubdoc) {
      throw new Error("Leave request not found");
    }
  
    reqSubdoc.status = status;
    reqSubdoc.decidedAt = new Date();
  
    await lab.save();
  
    return {
      id: reqSubdoc._id.toString(),
      status: reqSubdoc.status,
      decidedAt: reqSubdoc.decidedAt,
    };
  };