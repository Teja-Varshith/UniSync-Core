import mongoose from "mongoose";
import dotenv from "dotenv";
dotenv.config();
const connectDb = async () => {
  try {
    const connection = await mongoose.connect(process.env.MONGO_URL);
    console.log(
      `mongoDb is connected successfully and the connection object is ${connection}`
    );
  } catch (error) {
    console.log("mongoDb is failed to connected :", error);
  }
};

export default connectDb;
