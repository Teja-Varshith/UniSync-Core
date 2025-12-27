import {
    StartInterview,
    SubmitAnswer,
} from "../controllers/interviewController.js";

export function interviewSockets(socket, io) {
    socket.on("startInterview", (payload) => {
        StartInterview(socket, io, payload);
    });

    socket.on("submitAnswer", (payload) => {
        SubmitAnswer(socket, io, payload);
    });

    socket.on("disconnect", () => {
        console.log("Socket Disconnected: ", socket.id);
    }); 
}