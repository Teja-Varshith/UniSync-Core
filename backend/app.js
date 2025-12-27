import express from "express";
import cookieParser from "cookie-parser";
import connectDb from "./configs/database.js";
import authRouter from "./routes/auth.js";
import http from "http";
import { Server } from "socket.io";
import dotenv from "dotenv";
import { templateRouter } from "./routes/interviewRoutes.js";
import { initSockets } from "./sockets/index.js";



dotenv.config();
const app = express();
const server = http.createServer(app);
const io = new Server(server);

app.use(express.json());
app.use(cookieParser());

app.use("/api/auth", authRouter);
app.use("/api/carrer", templateRouter);

initSockets(io);




await connectDb();

const port = process.env.PORT;
server.listen(port, () => {
  console.log(`server is running on the port ${port} `);
});
