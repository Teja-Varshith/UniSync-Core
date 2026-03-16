import {
  createTemplateController,
  deleteTemplateController,
  createTemplatesController,
  getAllTemplates,
  getAllUserTemplate,
  updateTemplateController,
} from "../controllers/templateControllers.js";
import express from "express";

export const templateRouter = express.Router();

// templateRouter.post("/create-template", createTemplatesController);
templateRouter.post("/template", createTemplateController);
templateRouter.get("/get-templates", getAllTemplates);
templateRouter.get("/getAllUserTemplate/user/:userId", getAllUserTemplate)
templateRouter.patch("/template/:templateId", updateTemplateController);
templateRouter.delete("/template/:templateId", deleteTemplateController);
