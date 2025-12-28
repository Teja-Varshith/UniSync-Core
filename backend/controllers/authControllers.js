import { User } from "../models/user.js";

export const loginUserController = async (req, res) => {
  try {
    console.log("login request started");
    const { emailId, name, photoUrl } = req.body;
    console.log(photoUrl);
    if (!emailId || !name) {
      return res.status(404).json({
        success: false,
        message:
          "user email or user name is not provoded,please provide the email and user name ",
      });
    }

    //  check i user is existed or not
    const isUserExised = await User.findOne({
      emailId: emailId,
    });
            //TODO: Photourl bug
    if (isUserExised) {
      isUserExised.photoUrl = photoUrl;
      if (isUserExised.profileComplete == false) {
        res.status(200).json({
          success: true,
          message: "Loggedin but incomplete pro",
          user: isUserExised,
          profileStatus: isUserExised.profileComplete
            ? "user profile is completed"
            : "user profile is incompleted",
        });
      } else {
        res.status(200).json({
          success: true,
          message: "user logined successfully",
          user: isUserExised,
        });
      }
    } else {
      const newUser = new User(req.body);
      console.log(newUser);
      newUser.profileComplete = false;
      newUser.photoUrl = photoUrl;
      console.log(newUser);
      await newUser.save();
      return res.json({
        message: "pending_profile",
        user: newUser,
      });
    }
  } catch (e) {
    console.log("error while user is login :", e);
    res.status(400).json({
      success: false,
      message: "user logined is failed",
      error: e,
    });
  }
};

export const updateUserController = async (req, res) => {
  try {
    const { emailId, name, collegeName, semester, year, about } = req.body;
    // if (!emailId || !name || !collegeName || !semester || !year || !about) {
    //   return res.status(404).json({
    //     success: false,
    //     message: "please provide the user details ",
    //   });
    // }

    // retrieve the user and update the user
    const updatedUser = await User.findOneAndUpdate(
      { emailId },
      {
        name,
        collegeName,
        year,
        semester,
        about,
        profileComplete: true,
      },
      { new: true }
    );
    console.log(updatedUser);

    return res.json({
      success: true,
      message: "user is upadated successfully",
      user: updatedUser,
    });
  } catch (e) {
    console.log("error while updating the user :", e);
    res.status(400).json({
      success: false,
      message: "error while updating the user",
      error: e,
    });
  }
};

export const getUserDetailsController = async (req, res) => {
  try {
    const { emailId } = req.body;
    if (!emailId) {
      return res.status(404).json({
        success: false,
        message: "email is not found please provide the email",
      });
    }

    // fetch retrive the user from the database
    const userDetails = await User.findOne({
      emailId: emailId,
    });

    if (!userDetails) {
      return res.status(404).json({
        success: false,
        message: "user is not found",
      });
    }
    console.log("user details are :", userDetails);

    res.status(200).json({
      success: true,
      message: "user details is fetched successfully",
      data: userDetails,
    });
  } catch (error) {
    console.log("error while fetching the user details");
    res.status(400).json({
      success: false,
      message: "error while fetching the user details",
      error: error,
    });
  }
};
