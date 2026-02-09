import mongoose from "mongoose";
import dotenv from 'dotenv';
import colors from 'colors'
import users from "./data/users.js";
import companies from "./data/companies.js";
import User from './models/userModel.js'
import Company from "./models/companyModel.js";
import connectDB from './config/db.js'

dotenv.config();

connectDB();

const importData = async () => {
    try {

    await Company.deleteMany();
    await User.deleteMany();

    // Type: User Schema
    const createdUsers = await User.insertMany(users);
    companies[0].users = [createdUsers[0]._id, createdUsers[2]._id]
    companies[0].created_by = createdUsers[0]._id

    companies[1].users = [createdUsers[1]._id]
    companies[1].created_by = createdUsers[1]._id

     const createdCompanies = await Company.insertMany(companies);

     createdUsers[0].companies = [createdCompanies[0]._id];
     createdUsers[1].companies = [createdCompanies[1]._id];
     createdUsers[2].companies = [createdCompanies[0]._id];

  await createdUsers[0].save();
  await createdUsers[1].save();
  await createdUsers[2].save();

    console.log('Data Imported!'.green.inverse);
    process.exit();

    } catch (error) {
        console.error(`${error}`.red.inverse)
        process.exit(1);
    }
}

const destroyData = async () => {
    try {
    await Company.deleteMany();
    await User.deleteMany();

    console.log('Data Destroyed!'.red.inverse);
    process.exit();
    } catch (error) {
        console.error(`${error}`.red.inverse)
        process.exit(1);
    }
}

if(process.argv[2] === '-d'){
    destroyData();
}
else{
    importData();
}