import mongoose from "mongoose";
import { PenaltyAndOvertime } from "../models/penaltyAndOvertimeModel.js";
import Employee from "../models/employeeModel.js";

export const getEarlyLeavingPolicy = async (req, res) => {
    const { employeeId } = req.params;
    let doc = await PenaltyAndOvertime.findOne({ employeeId });
    if (!doc) {
      doc = new PenaltyAndOvertime({
        employeeId,
        earlyLeavingPolicy: {
          allowedEarlyLeavingDays: 0,
          onlyDeductIfEarlierThan: 0,
          deductionMode: "No, use a fixed deduction for early leaving",
          deductionType: "Fixed Daily Rate",
          amount: 0
        },
        // You may want to set defaults for other required subschemas!
        lateComingPolicy: {
          allowedLateDays: 0,
          onlyDeductIfLateByMoreThan: 0,
          deductionMode: "No, use a fixed deduction for late arrival",
          deductionType: "Fixed Daily Rate",
          amount: 0
        },
        overtimePolicy: {
          workingDays: {
            overtimeConsideredAfter: 0,
            extraHoursPay: "0.5x Hourly Salary",
            amount: 0
          },
          weekoffsAndHolidays: {
            publicHolidayPay: "Half Day Salary",
            amountPublicHolidayPay: 0,
            weekOffPay: "Half Day Salary",
            amountWeekOffPay: 0
          }
        }
      });
    }
    res.status(200).json({ earlyLeavingPolicy: doc.earlyLeavingPolicy });
  };
  
  export const updateEarlyLeavingPolicy = async (req, res) => {
    const { employeeId } = req.params;
    const { earlyLeavingPolicy } = req.body;

    if (!earlyLeavingPolicy || !employeeId)
      return res.status(400).json({ message: "Missing required fields" });
  
    let doc = await PenaltyAndOvertime.findOne({ employeeId });
    if (!doc) {
    doc = new PenaltyAndOvertime({
      employeeId,
      earlyLeavingPolicy,
      // You may want to set defaults for other required subschemas!
      lateComingPolicy: {
        allowedLateDays: 0,
        onlyDeductIfLateByMoreThan: 0,
        deductionMode: "No, use a fixed deduction for late arrival",
        deductionType: "Fixed Daily Rate",
        amount: 0
      },
      overtimePolicy: {
        workingDays: {
          overtimeConsideredAfter: 0,
          extraHoursPay: "0.5x Hourly Salary",
          amount: 0
        },
        weekoffsAndHolidays: {
          publicHolidayPay: "Half Day Salary",
          amountPublicHolidayPay: 0,
          weekOffPay: "Half Day Salary",
          amountWeekOffPay: 0
        }
      }
    });
  } else {
    doc.earlyLeavingPolicy = earlyLeavingPolicy;
  }
    await doc.save();
    res.status(200).json({ message: "Early Leaving Policy updated", data: doc.earlyLeavingPolicy });
  };

  export const updateLateComingPolicy = async (req, res) => {
    const { employeeId } = req.params;
    const { lateComingPolicy } = req.body;

    if (!lateComingPolicy || !employeeId)
      return res.status(400).json({ message: "Missing required fields" });
  
    let doc = await PenaltyAndOvertime.findOne({ employeeId });
    if (!doc) {
    doc = new PenaltyAndOvertime({
      employeeId,
      lateComingPolicy,
      // You may want to set defaults for other required subschemas!
      earlyLeavingPolicy: {
        allowedEarlyLeavingDays: 0,
        onlyDeductIfEarlierThan: 0,
        deductionMode: "No, use a fixed deduction for early leaving",
        deductionType: "Fixed Daily Rate",
        amount: 0
      },
      overtimePolicy: {
        workingDays: {
          overtimeConsideredAfter: 0,
          extraHoursPay: "0.5x Hourly Salary",
          amount: 0
        },
        weekoffsAndHolidays: {
          publicHolidayPay: "Half Day Salary",
          amountPublicHolidayPay: 0,
          weekOffPay: "Half Day Salary",
          amountWeekOffPay: 0
        }
      }
    });
  } else {
    doc.lateComingPolicy = lateComingPolicy;
  }
    await doc.save();
    res.status(200).json({ message: "Late Coming Policy updated", data: doc.lateComingPolicy });
  };

  export const getLateComingPolicy = async (req, res) => {
    const { employeeId } = req.params;
    let doc = await PenaltyAndOvertime.findOne({ employeeId });
    if (!doc) {
      doc = new PenaltyAndOvertime({
        employeeId,
        earlyLeavingPolicy: {
          allowedEarlyLeavingDays: 0,
          onlyDeductIfEarlierThan: 0,
          deductionMode: "No, use a fixed deduction for early leaving",
          deductionType: "Fixed Daily Rate",
          amount: 0
        },
        // You may want to set defaults for other required subschemas!
        lateComingPolicy: {
          allowedLateDays: 0,
          onlyDeductIfLateByMoreThan: 0,
          deductionMode: "No, use a fixed deduction for late arrival",
          deductionType: "Fixed Daily Rate",
          amount: 0
        },
        overtimePolicy: {
          workingDays: {
            overtimeConsideredAfter: 0,
            extraHoursPay: "0.5x Hourly Salary",
            amount: 0
          },
          weekoffsAndHolidays: {
            publicHolidayPay: "Half Day Salary",
            amountPublicHolidayPay: 0,
            weekOffPay: "Half Day Salary",
            amountWeekOffPay: 0
          }
        }
      });
    }
    res.status(200).json({ lateComingPolicy: doc.lateComingPolicy });
  };

  export const updateOvertimePolicy = async (req, res) => {
    const { employeeId } = req.params;
    const { overtimePolicy } = req.body;

    if (!overtimePolicy || !employeeId)
      return res.status(400).json({ message: "Missing required fields" });
  
    let doc = await PenaltyAndOvertime.findOne({ employeeId });
    if (!doc) {
    doc = new PenaltyAndOvertime({
      employeeId,
      overtimePolicy,
      // You may want to set defaults for other required subschemas!
      earlyLeavingPolicy: {
        allowedEarlyLeavingDays: 0,
        onlyDeductIfEarlierThan: 0,
        deductionMode: "No, use a fixed deduction for early leaving",
        deductionType: "Fixed Daily Rate",
        amount: 0
      },
      lateComingPolicy: {
        allowedLateDays: 0,
        onlyDeductIfLateByMoreThan: 0,
        deductionMode: "No, use a fixed deduction for late arrival",
        deductionType: "Fixed Daily Rate",
        amount: 0
      },
    });
  } else {
    doc.overtimePolicy = overtimePolicy;
  }
    await doc.save();
    res.status(200).json({ message: "Overtime Policy updated", data: doc.overtimePolicy });
  };

  export const getOvertimePolicy = async (req, res) => {
    const { employeeId } = req.params;
    let doc = await PenaltyAndOvertime.findOne({ employeeId });
    if (!doc) {
      doc = new PenaltyAndOvertime({
        employeeId,
        earlyLeavingPolicy: {
          allowedEarlyLeavingDays: 0,
          onlyDeductIfEarlierThan: 0,
          deductionMode: "No, use a fixed deduction for early leaving",
          deductionType: "Fixed Daily Rate",
          amount: 0
        },
        // You may want to set defaults for other required subschemas!
        lateComingPolicy: {
          allowedLateDays: 0,
          onlyDeductIfLateByMoreThan: 0,
          deductionMode: "No, use a fixed deduction for late arrival",
          deductionType: "Fixed Daily Rate",
          amount: 0
        },
        overtimePolicy: {
          workingDays: {
            overtimeConsideredAfter: 0,
            extraHoursPay: "0.5x Hourly Salary",
            amount: 0
          },
          weekoffsAndHolidays: {
            publicHolidayPay: "Half Day Salary",
            amountPublicHolidayPay: 0,
            weekOffPay: "Half Day Salary",
            amountWeekOffPay: 0
          }
        }
      });
    }
    res.status(200).json({ overtimePolicy: doc.overtimePolicy });
  };

  export const getCompanyPenaltyDetails = async (req, res) => {
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
  
      // Fetch all employee IDs in the company
      const employees = await Employee.find(empFilter)
        .select("_id basic.fullName basic.phone basic.jobTitle basic.profilePic")
        .lean();
  
      const empIds = employees.map(emp => emp._id);
  
      // Fetch bank details for these employees
      const penaltyDetailsList = await PenaltyAndOvertime.find({ employeeId: { $in: empIds } }).lean();
  
      // Map employeeId to bank details for quick access
      const empIdToPenalty = {};
    penaltyDetailsList.forEach(penalty => {
      if (penalty.employeeId) {
        empIdToPenalty[penalty.employeeId.toString()] = penalty;
      }
    });
  
      // Merge employees with their bank details
      const data = employees.map(emp => {
        const penaltyData = empIdToPenalty[emp._id.toString()] || null;
        return {
          _id: emp._id,
          fullName: emp.basic.fullName,
          phone: emp.basic.phone,
          jobTitle: emp.basic.jobTitle,
          profilePic: emp.basic.profilePic,
          penaltyAndOvertime: penaltyData,
          // fallback if you want specific fields as separate keys:
        earlyLeavingPolicy: penaltyData?.earlyLeavingPolicy || {},
        lateComingPolicy: penaltyData?.lateComingPolicy || {},
        overtimePolicy: penaltyData?.overtimePolicy || {}
        };
      });
  
      res.status(200).json(data);
  
    } catch (error) {
      console.error("Error fetching company penalty details:", error);
    return res.status(500).json({ message: "Failed to get penalty details" });
    }
  };