const ChatService = require("../services/ChatService");

class ChatController {
  //  Enviar mensaje
  static async enviarMensaje(req, res) {
    try {
      const { conversacionId, remitenteId, texto } = req.body;

      if (!conversacionId || !remitenteId || !texto) {
        return res.status(400).json({ error: "Faltan datos requeridos" });
      }

      const mensaje = await ChatService.enviarMensaje({
        conversacionId,
        remitenteId,
        texto
      });

      res.status(201).json(mensaje);
    } catch (error) {
      console.error("Error enviando mensaje:", error);
      res.status(400).json({ error: error.message });
    }
  }

  //  Obtener mensajes de una conversación
  static async obtenerMensajes(req, res) {
    try {
      const { conversacionId } = req.params;
      const { limit } = req.query;

      const mensajes = await ChatService.obtenerMensajes(
        conversacionId,
        limit ? parseInt(limit) : 50
      );

      res.status(200).json(mensajes);
    } catch (error) {
      console.error("Error obteniendo mensajes:", error);
      res.status(400).json({ error: error.message });
    }
  }

  //  Obtener o crear conversación
  static async obtenerOCrearConversacion(req, res) {
    try {
      const { uid1, uid2 } = req.body;

      if (!uid1 || !uid2) {
        return res.status(400).json({ error: "Se requieren dos IDs de usuario" });
      }

      const conversacion = await ChatService.obtenerOCrearConversacion(uid1, uid2);
      res.status(200).json(conversacion);
    } catch (error) {
      console.error("Error creando conversación:", error);
      res.status(400).json({ error: error.message });
    }
  }

  //  Obtener conversaciones del usuario
  static async obtenerConversaciones(req, res) {
    try {
      const { uid } = req.params;
      const conversaciones = await ChatService.obtenerConversaciones(uid);
      res.status(200).json(conversaciones);
    } catch (error) {
      console.error("Error obteniendo conversaciones:", error);
      res.status(400).json({ error: error.message });
    }
  }

  //  Marcar mensajes como leídos
  static async marcarComoLeidos(req, res) {
    try {
      const { conversacionId } = req.params;
      const { userId } = req.body;

      if (!userId) {
        return res.status(400).json({ error: "Se requiere userId" });
      }

      await ChatService.marcarComoLeidos(conversacionId, userId);
      res.status(200).json({ message: "Mensajes marcados como leídos" });
    } catch (error) {
      console.error("Error marcando mensajes como leídos:", error);
      res.status(400).json({ error: error.message });
    }
  }

  static async enviarMensajeAudio(req, res) {
    try {
      const { conversacionId, remitenteId } = req.body;

      if (!conversacionId || !remitenteId || !req.file) {
        return res.status(400).json({ error: "Faltan datos o el archivo de audio" });
      }

      const mensaje = await ChatService.enviarMensajeAudio({
        conversacionId,
        remitenteId,
        nombreArchivo: req.file.filename,
      });

      res.status(201).json(mensaje);
    } catch (error) {
      console.error("Error enviando audio:", error);
      res.status(400).json({ error: error.message });
    }
  }
}

module.exports = ChatController;