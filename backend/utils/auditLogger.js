import AuditLog from "../models/auditLogModel.js";

export const logAudit = async ({ req, action, resource, description, status = 'success' }) => {
  try {
    await AuditLog.create({
      user: req.user?.fullName || "Unknown",
      userId: req.user?._id,
      action,
      resource,
      description,
      ip: req.ip || req.headers['x-forwarded-for'] || "Internal",
      status
    });
  } catch (error) {
    console.error("Audit Logging Failed:", error.message);
  }
};