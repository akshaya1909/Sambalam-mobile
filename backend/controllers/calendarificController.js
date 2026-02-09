// controllers/calendarificController.js
import axios from 'axios';

export const getIndiaPublicHolidays = async (req, res) => {
  try {
    const { year } = req.params;
    const yearNum = Number(year);
    const apiKey = process.env.CALENDARIFIC_KEY;

    if (!apiKey) {
      console.error('CALENDARIFIC_KEY missing');
      return res.status(500).json({ message: 'API key not configured' });
    }
    if (!yearNum) {
      return res.status(400).json({ message: 'Invalid year' });
    }

    const response = await axios.get('https://calendarific.com/api/v2/holidays', {
      params: {
        api_key: apiKey,
        country: 'IN',
        year: yearNum,
      },
    }); // Calendarific returns response.holidays with name/date/type. [web:265][web:254]

    const holidays = response.data?.response?.holidays || [];

    const mapped = holidays.map((h) => ({
      name: h.name,
      date: h.date.iso, // "YYYY-MM-DD"
      source: 'calendarific',
      type: h.type || [],
    }));

    return res.json(mapped);
  } catch (err) {
    if (err.response) {
      console.error('Calendarific error', err.response.status, err.response.data);
      if (err.response.status === 429) {
        return res.status(429).json({ message: 'API limit reached' });
      }
    } else {
      console.error('Calendarific network error', err.message);
    }
    return res.status(500).json({ message: 'Failed to fetch holidays' });
  }
};
