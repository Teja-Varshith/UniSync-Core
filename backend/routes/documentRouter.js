import express from "express";
import {
  createDocumentController,
  deleteDocumentController,
} from "../controllers/documentController.js";

export const documentRouter = express.Router();

documentRouter.post("/upload-document", createDocumentController);
documentRouter.delete("/delet-document/:documentId", deleteDocumentController);