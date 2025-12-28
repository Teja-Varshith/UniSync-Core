import { Template } from "../models/template.js";
import { InterviewSession } from "../models/interviewsession.js";
import mongoose from "mongoose";
import { InterviewAIService } from "../services/interviewAiService.js";
import { ai } from "../services/ai.js";
import { exchangeStore } from "../storre/exchangestore.js";

function rebuildExchangeFromSession(session, template) {
  console.log("Rebuilding exchange method called now rebuit in progress from session and template");
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

    limits: 4,

    systemPrompt: "",
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

    console.log("Template Found the title", template.title);

    let session = await InterviewSession.findOne({
      userId,
      templateId,
      status: "inProgress",
    });

    let exchange;

    if (session) {
      console.log("user session found now trying to fetch exchange from local:");

      exchange = exchangeStore.get(session._id.toString());

      if (!exchange) {
        console.log("no exchange found in local rebuilding from rebuild method");
        exchange = rebuildExchangeFromSession(session, template);
        exchangeStore.set(session._id.toString(), exchange);
      }
    } else {
      console.log("no session found creating a new one:", userId);
      session = await InterviewSession.create({
        userId: new mongoose.Types.ObjectId(userId),
        templateId: template._id,
        status: "inProgress",
        endedAt: null,
        finalReport: {},
        questions: [],
        answers: [],
      });

      console.log("new session created");

      exchange = {
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

        limits: 4,

        systemPrompt: "",
      };
    }

    exchange.systemPrompt = await ai.buildSystemPrompt(exchange.templateSnapshot);
    console.log("Sucessfully generated system prompt length:", + exchange.systemPrompt.length);

    if (exchange.questions.length === 0) {
  const qsn = await ai.generateQuestion(exchange);
  exchange.questions.push({ text: qsn });
  exchange.meta.questionsAsked++;
      console.log("Successfully generated first question:", qsn);
      console.log("1st question added to exchange.questions and count is:", exchange.meta.questionsAsked);
}




    exchangeStore.set(session._id.toString(), exchange);
    console.log("Exchange stored in exchangeStore with key:", session._id.toString());

    socket.join(session._id.toString());
    console.log("Socket joined room:", session._id.toString());

    console.log("Emitting questionAsked event to room:", session._id.toString());
    io.to(session._id.toString())
    .emit(
      "questionAsked", {
        sessionId: session._id,
        exchange: exchange,
        question: exchange.questions.at(-1).text,
      }
  );

  console.log("now storing the first asked qsn into session in db");

   await InterviewSession.findByIdAndUpdate(session._id, {
      questions: exchange.questions,
      answers: exchange.answers,
    });

    console.log("START INTERVIEW completed successfully for session: the question length and answers length is", exchange.questions.length, exchange.answers.length);


  } catch (err) {
    console.log("START INTERVIEW ERROR:", err);
    console.log("Emitting error event to socket");
    socket.emit("error", {
      message: "Failed to start interview session." + err,
    });
  }
}

export async function SubmitAnswer(socket,io,{ sessionId, answerTranscript }) {
  try {
    console.log("Submitting answer for session:", sessionId);
    console.log("Answer transcript received:", answerTranscript);

    const exchange = exchangeStore.get(sessionId);
    console.log("Exchange fetched for session via lcl:", exchange.questions.length, "questions so far.");

    if (!exchange) {
      console.log("Invalid session - no exchange found now emitting error");
      return socket.emit("error", "Invalid session");
    }

    if (!answerTranscript || answerTranscript.trim() === "") {
      // return socket.emit("error", "Empty answer received");
      console.log("Empty answer received, proceeding without error.");
    }

    // ab llm decides the next question

    console.log("pushing answer to exchange.answers:", answerTranscript);
    exchange.answers.push({
      transcript: answerTranscript,
    });

    console.log("updating current question and answer in session");

    await InterviewSession.findByIdAndUpdate(sessionId, {
      questions: exchange.questions,
      answers: exchange.answers,
    });


    const isLastTurn = exchange.answers.length >= exchange.limits;


    console.log("checking if last turn:", isLastTurn);

    if (isLastTurn) {
      console.log("Last turn reached, generating outro and final report.");
      const outro = await ai.generateOutro(exchange);
      console.log("Generated outro:", outro);

      exchange.interviewState = "COMPLETED";

      console.log("Emitting interviewOutro event to room:", sessionId);


      io.to(sessionId).emit("outroQuestion", {
        sessionId,
        outro,
      });

      const report = await ai.generateFinalReport(exchange);
      console.log("Generated final report:", report);

      console.log("Updating session as completed along eith the outro question in DB with final report"); 
        await InterviewSession.findByIdAndUpdate(sessionId, {
        status: "completed",
        endedAt: new Date(),
        finalReport: report,
        questions: exchange.questions,
        answers: exchange.answers,
      });


      console.log("Emitting interviewCompleted event to room:", sessionId);
      io.to(sessionId).emit("interviewCompleted", {
        sessionId,
        report,
      });

      console.log("Cleaning up exchangeStore for session:", sessionId);
      exchangeStore.delete(sessionId);
      return;
    }


    console.log("Generating next question via AI service.");
    let qsn = await ai.generateQuestion(exchange);
    console.log("Generated next question:", qsn);
    exchange.questions.push({
      text: qsn,
    });
    exchange.meta.questionsAsked += 1;
    exchange.meta.lastActivityAt = new Date();
    console.log("Next question added to exchange.questions and count is:", exchange.meta.questionsAsked);

    console.log("emitting questionAsked event to room:", sessionId);
    io.to(sessionId).emit("questionAsked", {
      sessionId: sessionId,
      exchange: exchange,
      question: exchange.questions.at(-1).text,
    });
  } catch (e) {
    console.error("SUBMIT ANSWER ERROR:", e);
    console.log("Emitting error event to socket");
    socket.emit("error", { message: "Failed to submit  answer." + e });
  }
}
