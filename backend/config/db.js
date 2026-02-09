import mongoose from "mongoose";

// Connect to MongoDB database using mongoose library using connection string in .env
const connectDB = async () => {
    try {

        //promise
        const conn = await mongoose.connect(process.env.MONGO_URI);
        console.log(`MongoDB Connected: ${conn.connection.host}`)
    } catch (error) {
        console.log(`Errorr: ${error.message}`);
        process.exit(1);
    }
}

// like private or public - helps to export to other parts of application
export default connectDB;