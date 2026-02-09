// controllers/branchController.js
import Branch from '../models/branchModel.js';
import Company from '../models/companyModel.js';

// POST /api/companies/:companyId/branches
export const createBranch = async (req, res) => {
  try {
    const { companyId } = req.params;
    const { name, address, radius, latitude, longitude } = req.body;

    if (!name || !address || latitude == null || longitude == null) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    const company = await Company.findById(companyId);
    if (!company) {
      return res.status(404).json({ message: 'Company not found' });
    }

    const branch = await Branch.create({
      company: companyId,
      name,
      address,
      radius: radius || 100,
      location: {
        type: 'Point',
        coordinates: [longitude, latitude],
      },
    });

    company.branches.push(branch._id);
    await company.save();

    return res.status(201).json(branch);
  } catch (err) {
    console.error('createBranch error', err);
    return res.status(500).json({ message: 'Server error' });
  }
};


export const getCompanyBranches = async (req, res) => {
    try {
      const { companyId } = req.params;
  
      const company = await Company.findById(companyId).populate('branches');
      if (!company) {
        return res.status(404).json({ message: 'Company not found' });
      }
  
      return res.status(200).json(company.branches);
    } catch (err) {
      console.error('getCompanyBranches error', err);
      return res.status(500).json({ message: 'Server error' });
    }
  };


  export const getBranchById = async (req, res) => {
    try {
      const { branchId } = req.params;
      const branch = await Branch.findById(branchId);
  
      if (!branch) {
        return res.status(404).json({ message: 'Branch not found' });
      }
  
      return res.status(200).json(branch);
    } catch (err) {
      console.error('getBranchById error', err);
      return res.status(500).json({ message: 'Server error' });
    }
  };


  // PUT /api/branch/:branchId
export const updateBranch = async (req, res) => {
    try {
      const { branchId } = req.params;
      const { name, address, radius, latitude, longitude } = req.body;
  
      const branch = await Branch.findById(branchId);
      if (!branch) {
        return res.status(404).json({ message: 'Branch not found' });
      }
  
      if (name != null) branch.name = name;
      if (address != null) branch.address = address;
      if (radius != null) branch.radius = radius;
      if (latitude != null && longitude != null) {
        branch.location = {
          type: 'Point',
          coordinates: [longitude, latitude],
        };
      }
  
      const updated = await branch.save();
      return res.status(200).json(updated);
    } catch (err) {
      console.error('updateBranch error', err);
      return res.status(500).json({ message: 'Server error' });
    }
  };


  // DELETE /api/branch/:branchId
export const deleteBranch = async (req, res) => {
    try {
      const { branchId } = req.params;
  
      const branch = await Branch.findById(branchId);
      if (!branch) {
        return res.status(404).json({ message: 'Branch not found' });
      }
  
      // remove branch id from company.branches
      await Company.updateOne(
        { _id: branch.company },
        { $pull: { branches: branch._id } }
      );
  
      await branch.deleteOne();
  
      return res.status(200).json({ message: 'Branch deleted' });
    } catch (err) {
      console.error('deleteBranch error', err);
      return res.status(500).json({ message: 'Server error' });
    }
  };