import express from "express";
import cookieParser from "cookie-parser";
import connectDb from "./configs/database";
import authRouter from "./routes/auth";
import dotenv from "dotenv";
dotenv.config();

const app = express();

app.use(express.json());
app.use(cookieParser());

app.use("/api/auth", authRouter);

await connectDb();

const port = process.env.PORT;
app.listen(port, () => {
  console.log(`server is running on the port ${port} `);
});
