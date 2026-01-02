import express from "express";
import { getNextQuestion, updateQuestionProgress } from "../controllers/questionProgressController.js";

export const questionProgressRouter = express.Router();

questionProgressRouter.post("/updateQuestionProgress", updateQuestionProgress);
questionProgressRouter.get("/getNextQuestion", getNextQuestion);