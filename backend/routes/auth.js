import express from "express";
import {
  getUserDetailsController,
  loginUserController,
  updateTenantDetails,
  updateUserController,
} from "../controllers/authControllers.js";

const authRouter = express.Router();

authRouter.post("/login", loginUserController);
authRouter.patch("/complete-profile", updateUserController);
authRouter.get("/user-details", getUserDetailsController);
authRouter.post("/updateTenantDetails", updateTenantDetails);

export default authRouter;
