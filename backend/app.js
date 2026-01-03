import express from "express";
import cookieParser from "cookie-parser";
import connectDb from "./configs/database.js";
import authRouter from "./routes/auth.js";
import http from "http";
import { Server } from "socket.io";
import dotenv from "dotenv";
import { templateRouter } from "./routes/interviewRoutes.js";
import { initSockets } from "./sockets/index.js";
import { reportRouter } from "./routes/reportRoutes.js";
import { domainRouter } from "./routes/domain.js";
import { questionRouter } from "./routes/questions.js";
import { questionProgressRouter } from "./routes/questionProgressRoutes.js";
import { documentRouter } from "./routes/documentRouter.js";
import upload from "./configs/multer.js";
import  router  from "./routes/portfolioPublicRoutes.js";
import path from "path";
import portfolioPublicRouter from "./routes/portfolioPublicRoutes.js";
import { portfolioRouter } from "./routes/portifolioRoutes.js";


dotenv.config();
const app = express();
const server = http.createServer(app);
const io = new Server(server);

app.use(express.json());
app.use(cookieParser());

app.use(
  "/portfolio",
  express.static(path.join(process.cwd(), "portfolios"))
);
app.use("/user", portfolioPublicRouter);

app.use("/api/auth", authRouter);
app.use("/api/carrer", reportRouter);
app.use("/api/carrer", templateRouter);
app.use("/api/domain/", domainRouter);
app.use("/api/questions/", questionRouter);
app.use("/api/progress/", questionProgressRouter);
app.use("/api/resume", upload.single("file"), documentRouter);
app.use("/api/portfolio", router);
app.use("/api/portifolio2", portfolioRouter);

initSockets(io);

await connectDb();

const port = process.env.PORT;
server.listen(port, () => {
  console.log(`server is running on the port ${port} `);
});