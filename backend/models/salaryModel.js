import mongoose from "mongoose";

const salarySchema = new mongoose.Schema({
  employee_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Employee' },
  salary_month: String,
  ctc: Number,
  basic: Number,
  hra: Number,
  allowances: Number,
  deductions: Number,
  net_pay: Number
}, { timestamps: true });

export const Salary = mongoose.model('Salary', salarySchema);