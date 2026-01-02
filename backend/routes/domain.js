import express from "express";
import { createDomains, getAllDomains, addSubDomain } from "../controllers/domainControllers.js";

export const domainRouter = express.Router();

domainRouter.post("/createDomains", createDomains)
domainRouter.get("/getAllDomains",getAllDomains)
domainRouter.post("/:domain/subdomains",addSubDomain)