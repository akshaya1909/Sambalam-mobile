import mongoose from "mongoose";
import User from "../models/userModel";
import Employee from "../models/employeeModel";

export const checkDeviceStatus = async (userId, incomingDeviceId, deviceModel) => {
    const user = await User.findById(userId);
    const employee = await Employee.findOne({ user: userId });
  
    // Case 1: First time ever logging in
    if (!user.deviceId) {
      user.deviceId = incomingDeviceId;
      user.deviceModel = deviceModel;
      user.isDeviceVerified = true; // Auto-verify the very first device
      await user.save();
      return { status: "verified" };
    }
  
    // Case 2: Using the registered device
    if (user.deviceId === incomingDeviceId && user.isDeviceVerified) {
      return { status: "verified" };
    }
  
    // Case 3: Different device detected (New phone, same SIM)
    if (user.deviceId !== incomingDeviceId) {
      // Check if a request is already pending
      if (employee.device.status === "pending" && employee.device.newDeviceId === incomingDeviceId) {
        return { status: "pending" };
      }
  
      // Create a new verification request
      employee.device.status = "pending";
      employee.device.newDeviceId = incomingDeviceId;
      employee.device.newDeviceModel = deviceModel;
      await employee.save();
      
      return { status: "pending" };
    }
  
    return { status: "denied" };
  };