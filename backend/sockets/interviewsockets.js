import {
    StartInterview,
    SubmitAnswer,
    CancelInterview,
} from "../controllers/interviewController.js";

export function interviewSockets(socket, io) {
    socket.on("startInterview", (payload) => {
        console.log("START INTERVIEW REQUESTED RECIVED");
        StartInterview(socket, io, payload);
    });

    socket.on("submitAnswer", (payload) => {
        console.log("SUBMIT ANSWER REQUEST RECIVED");
        SubmitAnswer(socket, io, payload);
    });

    socket.on("cancelInterview", (payload) => {
        console.log("CANCEL INTERVIEW REQUEST RECIVED");
        CancelInterview(socket, io, payload);
    });

    socket.on("disconnect", () => {
        console.log("Socket Disconnected: ", socket.id);
    }); 
}