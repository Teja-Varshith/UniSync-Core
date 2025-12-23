import express from "express";
import cookieParser from "cookie-parser";
import connectDb from "./configs/database.js";
import authRouter from "./routes/auth.js";
import dotenv from "dotenv";
import { templateRouter } from "./routes/interviewRoutes.js";
dotenv.config();

const app = express();

app.use(express.json());
app.use(cookieParser());

app.use("/api/auth", authRouter);
app.use("/api/carrer", templateRouter);

await connectDb();

const port = process.env.PORT;
app.listen(port, () => {
  console.log(`server is running on the port ${port} `);
});
