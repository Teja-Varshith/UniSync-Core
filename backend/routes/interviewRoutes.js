import {
  createTemplatesController,
  getAllTemplates,
  getAllUserTemplate,
} from "../controllers/templateControllers.js";
import express from "express";

export const templateRouter = express.Router();

templateRouter.post("/create-template", createTemplatesController);
templateRouter.get("/get-templates", getAllTemplates);
templateRouter.get("/getAllUserTemplate/user/:userId", getAllUserTemplate)
