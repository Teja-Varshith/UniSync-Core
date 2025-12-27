import { interviewSockets } from "./interviewsockets.js";

export function initSockets(io) {
    io.on("connection", (socket) => {
        console.log("Socket Connnected: ", socket.id);
        interviewSockets(socket, io);
    })
}