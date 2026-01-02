import { Domain } from "../models/domains.js";     

export const createDomains = async (req,res) => {
    try{
    const {domain} = req.body;
    if(!domain ){
        return  res.json({
            message: "failed",
            erorr: "bodyy"
        })
    }
    const newDomain = await Domain.create({
        domain,
    });

    newDomain.save();

    return res.json({
        message: "Success",
        domain: newDomain,
    });
    }catch(e){
        res.json({
            message: "failed",
            erorr: e
        })
    }
}
export const addSubDomain = async (req, res) => {
  const { domain } = req.params; 
  const { subDomains } = req.body;

  if (!Array.isArray(subDomains) || subDomains.length === 0) {
    return res.status(400).json({ message: "subDomains must be a non-empty array" });
  }

  const domainDoc = await Domain.findOne({ domain });
  if (!domainDoc) {
    return res.status(404).json({ message: "Domain not found" });
  }

  const existingLabels = new Set(
    domainDoc.subDomains.map(sd => sd.label.toLowerCase())
  );

  const newSubDomains = [];

  for (const sd of subDomains) {
    if (!sd.label || !sd.logo) continue;

    const labelLower = sd.label.toLowerCase();
    if (!existingLabels.has(labelLower)) {
      newSubDomains.push(sd);
      existingLabels.add(labelLower);
    }
  }

  if (newSubDomains.length === 0) {
    return res.status(400).json({ message: "All subDomains already exist" });
  }

  domainDoc.subDomains.push(...newSubDomains);
  await domainDoc.save();

  res.status(200).json(domainDoc);
};





export const getAllDomains = async (req,res) => {
    try{
        const allDomain = await Domain.find();
        return res.status(200).json({
    success: true,
    data: allDomain,
  });
    }catch(e) {
        res.status(200).json({
    success: false,
    message: e, 
  });
    }
}