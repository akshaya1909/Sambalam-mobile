// models/CompanyHoliday.js
import mongoose from 'mongoose';

const companyHolidaySchema = new mongoose.Schema(
  {
    company: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Company',
      required: true,
      index: true,
    },
    year: {
      type: Number,
      required: true,
      index: true,
    },
    // Each element is a holiday for this company in this year
    holidays: [
      {
        name: {
          type: String,
          required: true,
          trim: true,
        },
        date: {
          type: Date,
          required: true,
        },
        source: {
          type: String,
          enum: ['calendarific', 'manual'],
          default: 'manual',
        },
        type: {
          type: [String], // optional classification
          default: [],
        },
      },
    ],
  },
  {
    timestamps: true,
  }
);

// one document per company+year
companyHolidaySchema.index({ company: 1, year: 1 }, { unique: true });

const CompanyHoliday = mongoose.model('CompanyHoliday', companyHolidaySchema);

export default CompanyHoliday;
