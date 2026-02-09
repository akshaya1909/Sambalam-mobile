// controllers/departmentController.js
import mongoose from 'mongoose';
import Employee from "../models/employeeModel.js";
import Department from '../models/departmentModel.js';
import Company from '../models/companyModel.js';

// POST /api/department/:companyId
export const createDepartment = async (req, res) => {
  try {
    const { companyId } = req.params;
    const { name, branchId, description } = req.body;

    if (!name) {
      return res.status(400).json({ message: 'Department name is required' });
    }

    const company = await Company.findById(companyId);
    if (!company) {
      return res.status(404).json({ message: 'Company not found' });
    }

    const department = await Department.create({
      company: companyId,
      branch: branchId || null, // optional: department for specific branch
      name,
      description: description || '',
      staff: [],
    });

    company.departments.push(department._id);
    await company.save();

    return res.status(201).json(department);
  } catch (err) {
    console.error('createDepartment error', err);
    return res.status(500).json({ message: 'Server error' });
  }
};

// GET /api/department/company/:companyId
export const getCompanyDepartments = async (req, res) => {
  try {
    const { companyId } = req.params;

    const departments = await Department.find({ company: companyId }).sort({
      createdAt: 1,
    });

    return res.status(200).json(departments);
  } catch (err) {
    console.error('getCompanyDepartments error', err);
    return res.status(500).json({ message: 'Server error' });
  }
};


export const addDepartmentStaff = async (req, res) => {
  try {
    const { departmentId } = req.params;
    const { employeeId } = req.body;
    
    if (!employeeId) {
      return res.status(400).json({ message: 'employeeId is required' });
    }
    
    const dept = await Department.findById(departmentId);
    if (!dept) {
      return res.status(404).json({ message: 'Department not found' });
    }

    const employee = await Employee.findById(employeeId);
    if (!employee) {
      return res.status(404).json({ message: 'Employee not found' });
    }
    
    const employeeObjectId = new mongoose.Types.ObjectId(employeeId);
    const departmentObjectId = new mongoose.Types.ObjectId(departmentId);
    
    if (!dept.staff.some((id) => id.equals(employeeObjectId))) {
      dept.staff.push(employeeObjectId);
      await dept.save();
    }

    await Employee.findByIdAndUpdate(employeeId, {
      $addToSet: { "basic.departments": departmentObjectId }
    });
    
    console.log('AFTER ADD staff=', dept.staff);
    return res.status(200).json(dept);
  } catch (err) {
    console.error('addDepartmentStaff error', err);
    return res.status(500).json({ message: 'Server error' });
  }
};

export const removeDepartmentStaff = async (req, res) => {
  try {
    const { departmentId, employeeId } = req.params;
    const employeeObjectId = new mongoose.Types.ObjectId(employeeId);
    
    const dept = await Department.findById(departmentId);
    if (!dept) {
      return res.status(404).json({ message: 'Department not found' });
    }
    
    dept.staff = dept.staff.filter(id => !id.equals(employeeObjectId));
    await dept.save();
    
    console.log('AFTER REMOVE staff=', dept.staff);
    return res.status(200).json(dept);
  } catch (err) {
    console.error('removeDepartmentStaff error', err);
    return res.status(500).json({ message: 'Server error' });
  }
};

export const deleteDepartment = async (req, res) => {
  try {
    const { departmentId } = req.params;

    const dept = await Department.findById(departmentId);
    if (!dept) {
      return res.status(404).json({ message: 'Department not found' });
    }

    // Remove reference from Company
    await Company.updateOne(
      { _id: dept.company },
      { $pull: { departments: departmentId } }
    );

    await Employee.updateMany(
      { "basic.departments": departmentId },
      { $pull: { "basic.departments": departmentId } }
    );

    await Department.deleteOne({ _id: departmentId });

    return res.status(200).json({ message: 'Department deleted and staff updated successfully' });
  } catch (err) {
    console.error('deleteDepartment error', err);
    return res.status(500).json({ message: 'Server error' });
  }
};