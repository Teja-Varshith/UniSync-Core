import {
  createTemplatesController,
  getAllTemplates,
} from "../controllers/interviewController.js";
import express from "express";

export const templateRouter = express.Router();

templateRouter.post("/create-template", createTemplatesController);
templateRouter.get("/get-templates", getAllTemplates);
