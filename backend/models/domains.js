import mongoose from "mongoose";

const subDomainSchema = new mongoose.Schema(
  {
    label: {
      type: String,
      // required: true,
    },
    logo: {
      type: String,
    }
  },
  { _id: false }
);

const domainSchema = new mongoose.Schema({
  domain: {
    type: String,
    required: true,
    unique: true,
  },

  subDomains: {
    type: [subDomainSchema],
    default: [],
  },
});

export const Domain = mongoose.model("Domain", domainSchema);
