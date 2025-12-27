import { Template } from "../models/template.js";
import { InterviewSession } from "../models/interviewsession.js";
import mongoose from "mongoose";
import { InterviewAIService } from "../services/interviewAiService.js";
import { ai } from "../services/ai.js";
import { exchangeStore } from "../storre/exchangestore.js";

function rebuildExchangeFromSession(session, template) {
  return {
    templateSnapshot: {
      templateId: template._id,
      domain: template.domain,
      evaluationMetrics: template.evaluationMetrics.map(
        (metric) => `${metric.topic}: ${metric.description}`
      ),
      targetCompany: "Not Specified",
    },

    meta: {
      questionsAsked: session.questions.length,
      startedAt: session.createdAt,
      lastActivityAt: new Date(),
    },

    interviewState: "ASKING",

    questions: session.questions || [],
    answers: session.answers || [],

    limits: 10,

    systemPrompt: "", // MUST be regenerated
  };
}


export async function StartInterview(socket, io, { templateId, userId }) {
  try {
    console.log(
      "Starting interview for user:",
      userId,
      "with template:",
      templateId
    );
    const template = await Template.findById(templateId);
    if (!template) {
      return socket.emit("error", "Invalid template");
    }
    let session = await InterviewSession.findOne({
      userId,
      templateId,
      status: "inProgress",
    });

    let exchange;

if (session) {
  exchange = exchangeStore.get(session._id.toString());

  if (!exchange) {
    exchange = rebuildExchangeFromSession(session, template);
    exchangeStore.set(session._id.toString(), exchange);
  }

}else{
      console.log("no session found creating now oneeeeeeeeeeee:", userId);
      session = await InterviewSession.create({
        userId: new mongoose.Types.ObjectId(userId),
        templateId: template._id,
        status: "inProgress",
        endedAt: null,
        finalReport: {},
        questions: [],
        answers: [],
      });
    }
    console.log(`session got is ${session}`);
    console.log(
      `the template is ${template} and length of metrics is ${template.evaluationMetrics.length}`
    );
   

    console.log("Exchange object created:", exchange);

    // here ai logic to generate system prompt based on template and user profile can be added
    // then update the exchange object with generated system prompt
    // then update the qsn to ask
    // if followup needed ask the foloowup qsn
    // and other things also

    exchange.systemPrompt = await ai.buildSystemPrompt(
      exchange.templateSnapshot
    );
    console.log("System Prompt generated:", exchange.systemPrompt);
    exchange.questions.push({
      text: await ai.generateQuestion(exchange),
    });
    exchange.meta.questionsAsked += 1;
    exchangeStore.set(session._id.toString(), exchange);

    socket.join(session._id.toString());

    console.log(exchange.questions);

    io.to(session._id.toString()).emit("questionAsked", {
      sessionId: session._id,
      exchange: exchange,
      question: exchange.questions.at(-1).text,
    });
  } catch (err) {
    console.error("START INTERVIEW ERROR:", err);
    socket.emit("error", {
      message: "Failed to start interview session." + err,
    });
  }
}

export async function SubmitAnswer(
  socket,
  io,
  { sessionId, answerTranscript }
) {
  try {
    console.log(
      "Answer received for session:",
      sessionId,
      "Answer:",
      answerTranscript
    );
    const exchange = exchangeStore.get(sessionId);
    console.log("Exchange fetched for session:", exchange);
    if (!exchange) {
      return socket.emit("error", "Invalid session");
    }

    if (!answerTranscript || answerTranscript.trim() === "") {
      // return socket.emit("error", "Empty answer received");
    }

    // ab llm decides the next question

    exchange.answers.push({
      transcript: answerTranscript,
    });

    await InterviewSession.findByIdAndUpdate(sessionId, {
      questions: exchange.questions,
      answers: exchange.answers,
    });

    const isLastTurn = exchange.questions.length >= exchange.limits;

    if (isLastTurn) {
      const outro = await ai.generateOutro(exchange);

      exchange.questions.push({ text: outro });
      exchange.meta.questionsAsked += 1;
      exchange.interviewState = "COMPLETED";

      io.to(sessionId).emit("interviewOutro", {
        sessionId,
        outro,
      });
      const report = await ai.generateFinalReport(exchange);

      await InterviewSession.findByIdAndUpdate(sessionId, {
        status: "completed",
        endedAt: new Date(),
        finalReport: report,
        questions: exchange.questions,
        answers: exchange.answers,
      });

      io.to(sessionId).emit("interviewCompleted", {
        sessionId,
        report,
      });

      exchangeStore.delete(sessionId);
      return;
    }

    exchange.questions.push({
      text: await ai.generateQuestion(exchange),
    });
    exchange.meta.questionsAsked += 1;
    exchange.meta.lastActivityAt = new Date();

    io.to(sessionId).emit("questionAsked", {
      sessionId: sessionId,
      exchange: exchange,
      question: exchange.questions.at(-1).text,
    });
  } catch (e) {
    console.error("SUBMIT ANSWER ERROR:", e);
    socket.emit("error", { message: "Failed to submit  answer." + e });
  }
}
