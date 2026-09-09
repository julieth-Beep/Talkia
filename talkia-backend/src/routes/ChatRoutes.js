const express = require("express");
const router = express.Router();
const ChatController = require("../controllers/ChatController");
const upload = require("../config/multer");

router.post("/mensaje", ChatController.enviarMensaje);
router.get("/mensajes/:conversacionId", ChatController.obtenerMensajes);
router.post("/conversacion", ChatController.obtenerOCrearConversacion);
router.get("/conversaciones/:uid", ChatController.obtenerConversaciones);
router.patch("/mensajes/:conversacionId/leer", ChatController.marcarComoLeidos);
router.post("/mensaje-audio", upload.single("audio"), ChatController.enviarMensajeAudio);

module.exports = router;