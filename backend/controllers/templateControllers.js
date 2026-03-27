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
    coinPrice: 10,
  });
  res.status(200).json({
    success: true,
    data: newTemPlate,
  });
};

export const getAllUserTemplate = async (req,res) => {
try{
  const userId = String(req.params.userId ?? "").trim();
  if (!userId) {
    return res.status(400).json({
      success: false,
      data: [],
      message: "userId is required",
    });
  }

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

export const createTemplateController = async (req, res) => {
  try {
    const {
      title,
      domain,
      icon,
      topics = [],
      evaluationMetrics = [],
      coinPrice = 0,
    } = req.body;

    if (!title || !domain || !icon) {
      return res.status(400).json({
        success: false,
        message: "title, domain and icon are required",
      });
    }

    const parsedCoinPrice = Number(coinPrice);
    if (!Number.isFinite(parsedCoinPrice) || parsedCoinPrice < 0) {
      return res.status(400).json({
        success: false,
        message: "coinPrice must be a non-negative number",
      });
    }

    const template = await Template.create({
      title: String(title).trim(),
      domain: String(domain).trim(),
      icon: String(icon).trim(),
      topics: Array.isArray(topics)
        ? topics.map((t) => String(t).trim()).filter(Boolean)
        : [],
      evaluationMetrics: Array.isArray(evaluationMetrics)
        ? evaluationMetrics
            .map((m) => ({
              topic: String(m?.topic ?? "").trim(),
              description: String(m?.description ?? "").trim(),
            }))
            .filter((m) => m.topic && m.description)
        : [],
      coinPrice: parsedCoinPrice,
    });

    return res.status(201).json({
      success: true,
      data: template,
    });
  } catch (e) {
    console.error("template create error", e);
    return res.status(500).json({
      success: false,
      message: "Failed to create template",
    });
  }
};

export const deleteTemplateController = async (req, res) => {
  try {
    const { templateId } = req.params;
    if (!templateId) {
      return res.status(400).json({
        success: false,
        message: "templateId is required",
      });
    }

    const deleted = await Template.findByIdAndDelete(templateId);
    if (!deleted) {
      return res.status(404).json({
        success: false,
        message: "Template not found",
      });
    }

    return res.status(200).json({
      success: true,
      message: "Template deleted successfully",
    });
  } catch (e) {
    console.error("template delete error", e);
    return res.status(500).json({
      success: false,
      message: "Failed to delete template",
    });
  }
};

export const updateTemplateController = async (req, res) => {
  try {
    const { templateId } = req.params;

    if (!templateId) {
      return res.status(400).json({
        success: false,
        message: "templateId is required",
      });
    }

    const updates = {};
    const {
      title,
      domain,
      icon,
      topics,
      evaluationMetrics,
      coinPrice,
    } = req.body;

    if (typeof title === "string") updates.title = title.trim();
    if (typeof domain === "string") updates.domain = domain.trim();
    if (typeof icon === "string") updates.icon = icon.trim();

    if (Array.isArray(topics)) {
      updates.topics = topics.map((t) => String(t).trim()).filter(Boolean);
    }

    if (Array.isArray(evaluationMetrics)) {
      updates.evaluationMetrics = evaluationMetrics
        .map((m) => ({
          topic: String(m?.topic ?? "").trim(),
          description: String(m?.description ?? "").trim(),
        }))
        .filter((m) => m.topic && m.description);
    }

    if (coinPrice !== undefined) {
      const parsedCoinPrice = Number(coinPrice);
      if (!Number.isFinite(parsedCoinPrice) || parsedCoinPrice < 0) {
        return res.status(400).json({
          success: false,
          message: "coinPrice must be a non-negative number",
        });
      }
      updates.coinPrice = parsedCoinPrice;
    }

    if (Object.keys(updates).length === 0) {
      return res.status(400).json({
        success: false,
        message: "No valid fields provided for update",
      });
    }

    const template = await Template.findByIdAndUpdate(templateId, updates, {
      new: true,
      runValidators: true,
    });

    if (!template) {
      return res.status(404).json({
        success: false,
        message: "Template not found",
      });
    }

    return res.status(200).json({
      success: true,
      data: template,
    });
  } catch (e) {
    console.error("template update error", e);
    return res.status(500).json({
      success: false,
      message: "Failed to update template",
    });
  }
};
