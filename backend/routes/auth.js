import express from "express";
import {
  getUserDetailsController,
  loginUserController,
  updateUserController,
} from "../controllers/authControllers.js";

const authRouter = express.Router();

authRouter.post("/login", loginUserController);
authRouter.patch("/complete-profile", updateUserController);
authRouter.get("/user-details", getUserDetailsController);

export default authRouter;
