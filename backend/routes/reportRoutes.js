import express from "express";
import { reportControllers } from "../controllers/reportControllers.js";

export const reportRouter = express.Router();


reportRouter.get("/getAllReports", reportControllers);
