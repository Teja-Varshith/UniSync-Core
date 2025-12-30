import { Template } from "../models/template.js";
import {InterviewSession} from "../models/interviewsession.js"

export const createTemplatesController = async (req, res) => {
  // const {title,topics,evaluationMetrics,domain,icon} = req.body
  
  const newTemPlate = await Template.create({
    title: "Flutter BLoC Interview Template",
    topics: [
      "bloc basics",
      "state management",
      "streams",
      "clean architecture",
    ],
    evaluationMetrics: [ 
      {
        topic: "bloc proficiency",
        description:
          "Ability to implement Bloc pattern with proper events and states",
      },
      {
        topic: "architecture understanding",
        description:
          "Uses clean architecture and separates UI, domain, and data layers",
      },
      {
        topic: "debugging",
        description:
          "Can debug state issues and stream-related bugs efficiently",
      },
    ],
    domain: "Flutter",
    icon: "flutter",
  });
  res.status(200).json({
    success: true,
    data: newTemPlate,
  });
};

export const getAllUserTemplate = async (req,res) => {
try{
  const { userId } = req.params;
  const sessions = await InterviewSession.find({ userId })
  .select("templateId")
  .lean();

const templateIds = [...new Set(sessions.map(s => s.templateId))];

const templates = await Template.find({ _id: { $in: templateIds } });


  res.status(200).json({
    success:true,
    data:templates
  });
}catch(e){
  console.log(e);
  res.status(500).json({
    success:false,
    data: []
  });
}


};

export const getAllTemplates = async (req, res) => {
  const allTemplates = await Template.find();

  res.status(200).json({
    success: true,
    data: allTemplates,
  });
};
