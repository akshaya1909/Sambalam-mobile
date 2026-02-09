import SystemSettings from "../models/systemSettingsModel.js";

/**
 * @desc    Get System Settings (Publicly accessible for Layout check)
 * @route   GET /api/system/settings
 */
export const getSystemSettings = async (req, res) => {
  try {
    // We assume there is only one settings document
    let settings = await SystemSettings.findOne();
    
    if (!settings) {
      // Create default settings if they don't exist
      settings = await SystemSettings.create({
        companyName: "Sambalam",
        isMaintenanceMode: false
      });
    }
    
    res.status(200).json(settings);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

/**
 * @desc    Toggle Maintenance Mode
 * @route   PATCH /api/system/maintenance
 */
export const toggleMaintenanceMode = async (req, res) => {
  try {
    const { isMaintenanceMode } = req.body;
    
    const settings = await SystemSettings.findOneAndUpdate(
      {}, 
      { isMaintenanceMode }, 
      { new: true, upsert: true }
    );
    
    res.status(200).json(settings);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};