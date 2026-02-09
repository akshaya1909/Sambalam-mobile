// controllers/leaveController.js
import { getLeaveBalanceForEmployee, createLeaveRequest, getEmployeeLeaveRequests, getCompanyPendingLeaveRequests, updateLeaveRequestStatus } from "../services/leaveService.js";

export const getLeaveBalanceController = async (req, res) => {
  try {
    const { employeeId, companyId } = req.query;

    if (!employeeId || !companyId) {
      return res
        .status(400)
        .json({ message: "employeeId and companyId are required" });
    }

    const result = await getLeaveBalanceForEmployee({ employeeId, companyId });

    return res.status(200).json(result);
  } catch (err) {
    console.error("Leave balance error:", err);
    return res
      .status(400)
      .json({ message: err.message || "Unable to fetch leave balance" });
  }
};


export const createLeaveRequestController = async (req, res) => {
    try {
      const {
        employeeId,
        companyId,
        fromDate,
        toDate,
        isHalfDay,
        type,
        reason,
        documentUrl,
      } = req.body;
  
      if (!employeeId || !companyId || !fromDate || !toDate || !type) {
        return res.status(400).json({ message: "Missing required fields" });
      }
  
      const request = await createLeaveRequest({
        employeeId,
        companyId,
        fromDate: new Date(fromDate),
        toDate: new Date(toDate),
        isHalfDay: !!isHalfDay,
        type,
        reason: reason || "",
        documentUrl,
      });
  
      return res.status(201).json({ message: "Leave request created", request });
    } catch (err) {
      console.error("Create leave request error:", err);
      return res
        .status(400)
        .json({ message: err.message || "Unable to create leave request" });
    }
  };


  export const getEmployeeLeaveRequestsController = async (req, res) => {
    try {
      const { employeeId } = req.query;
  
      if (!employeeId) {
        return res.status(400).json({ message: "employeeId is required" });
      }
  
      const result = await getEmployeeLeaveRequests({ employeeId });
      return res.status(200).json(result);
    } catch (err) {
      console.error("Leave requests error:", err);
      return res.status(400).json({ 
        message: err.message || "Unable to fetch leave requests" 
      });
    }
  };

  export const getPendingLeaveRequestsController = async (req, res) => {
    try {
      const { companyId } = req.query;
      if (!companyId) {
        return res.status(400).json({ message: "companyId is required" });
      }
  
      const items = await getCompanyPendingLeaveRequests(companyId);
  
      return res.status(200).json({
        items,
        total: items.length,
      });
    } catch (err) {
      console.error("Get pending leave requests error:", err);
      return res
        .status(400)
        .json({ message: err.message || "Unable to fetch pending leaves" });
    }
  };

  export const updateLeaveStatusController = async (req, res) => {
    try {
      const { employeeId, leaveRequestId, status } = req.body;
  
      if (!employeeId || !leaveRequestId || !status) {
        return res
          .status(400)
          .json({ message: "employeeId, leaveRequestId and status are required" });
      }
  
      const result = await updateLeaveRequestStatus({
        employeeId,
        leaveRequestId,
        status,
      });
  
      return res.status(200).json({
        message: "Leave status updated",
        result,
      });
    } catch (err) {
      console.error("Update leave status error:", err);
      return res
        .status(400)
        .json({ message: err.message || "Unable to update leave status" });
    }
  };