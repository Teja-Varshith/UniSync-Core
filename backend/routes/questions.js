import express from "express";
import { createQuestions } from "../controllers/questionsController.js";

export const questionRouter = express.Router();

questionRouter.post("/createQuestions", createQuestions);