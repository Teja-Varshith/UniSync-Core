import { Template } from "../models/template.js";

export const createTemplatesController = async (req, res) => {
  const {}
  const newTemPlate = await Template.create({
    title: "Flutter BLoC Interview Template",
    topics: [
      "bloc basics",
      "state management",
      "streams",
      "clean architecture",
    ],
    evalutionMetrics: [ 
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

export const getAllTemplates = async (req, res) => {
  const allTemplates = await Template.find();

  res.status(200).json({
    success: true,
    data: allTemplates,
  });
};
