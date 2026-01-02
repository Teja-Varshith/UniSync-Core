import mongoose from "mongoose";

const subDomainSchema = new mongoose.Schema(
  {
    label: {
       type: String,
      required: true,
      trim: true,
    },
    logo: {
      type: String,
      default: "",
    }
  },
  { _id: true }
);

const domainSchema = new mongoose.Schema({
  domain: {
    type: String,
    required: true,
    unique: true,
    trim: true,
    lowercase: true,
  },

  subDomains: {
    type: [subDomainSchema],
    default: [],
  },
});

export const Domain = mongoose.model("Domain", domainSchema);
