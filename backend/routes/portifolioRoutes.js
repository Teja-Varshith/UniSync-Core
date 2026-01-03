import express from "express";
import { generatePortfolioController } from "../controllers/porfolioController.js";

export const portfolioRouter = express.Router();

portfolioRouter.get("/portfolio-files", generatePortfolioController);