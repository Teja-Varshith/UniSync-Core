import express from "express";
import { generatePortfolioFromTextController } from "../controllers/porfolioController.js";

export const portfolioRouter = express.Router();

portfolioRouter.post("/generate", generatePortfolioFromTextController);