import mongoose from mongoose;


const userSchema = new mongoose.Schema({
  emailId: {
    type: String,
    required: true,
  },
  name: {
    type: String,
    required: true,
  },
  photoUrl: {
    type: String,
    default: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQf1fiSQO7JfDw0uv1Ae_Ye-Bo9nhGNg27dwg&s"
  },
  profileComplete: {
    type: Boolean,
    default: false,
  },
  collegeName: String,
  year: Number,
  semester: Number,
  about: String,
  tenantId: String,
  role: {
    type: String,
    default: "user",
  },

}, { timestamps: true });

 export const User = mongoose.model("User",userSchema)

