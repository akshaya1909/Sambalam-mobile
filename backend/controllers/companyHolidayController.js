// controllers/companyHolidayController.js
import CompanyHoliday from '../models/holidayModel.js';
import Company from '../models/companyModel.js';

export const getCompanyHolidays = async (req, res) => {
  try {
    const { companyId, year } = req.params;
    const yearNum = Number(year);

    if (!companyId || !yearNum) {
      return res.status(400).json({ message: 'companyId and year are required' });
    }

    const doc = await CompanyHoliday.findOne({ company: companyId, year: yearNum });
    if (!doc) {
      return res.json({ company: companyId, year: yearNum, holidays: [] });
    }

    // send normalized dates as YYYY-MM-DD strings
    const mapped = doc.holidays.map((h) => ({
      id: `${h.date.toISOString().slice(0, 10)}-${h._id}`,
      name: h.name,
      date: h.date.toISOString().slice(0, 10),
      source: h.source,
      type: h.type,
    }));

    return res.json({ company: companyId, year: yearNum, holidays: mapped });
  } catch (err) {
    console.error('getCompanyHolidays error', err.message);
    return res.status(500).json({ message: 'Failed to load company holidays' });
  }
};


// controllers/companyHolidayController.js (cont.)
export const upsertCompanyHolidays = async (req, res) => {
    try {
      const { companyId, year } = req.params;
      const yearNum = Number(year);
      const { holidays } = req.body; // [{ name, date, source?, type? }]
  
      if (!companyId || !yearNum) {
        return res.status(400).json({ message: 'companyId and year are required' });
      }
  
      if (!Array.isArray(holidays)) {
        return res.status(400).json({ message: 'holidays must be an array' });
      }
  
      const normalized = holidays.map((h) => ({
        name: h.name,
        date: new Date(h.date), // expects YYYY-MM-DD
        source: h.source || 'manual',
        type: h.type || [],
      }));
  
      const doc = await CompanyHoliday.findOneAndUpdate(
        { company: companyId, year: yearNum },
        { company: companyId, year: yearNum, holidays: normalized },
        { upsert: true, new: true }
      );

      await Company.updateOne(
        { _id: companyId },
        { $addToSet: { companyHolidays: doc._id } }
      );
  
      return res.json({ message: 'Company holidays saved', id: doc._id });
    } catch (err) {
      console.error('upsertCompanyHolidays error', err.message);
      return res.status(500).json({ message: 'Failed to save company holidays' });
    }
  };
  