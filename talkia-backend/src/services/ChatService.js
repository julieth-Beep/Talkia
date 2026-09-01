const MensajeRepository = require("../repositories/MensajeRepository");
const ConversacionRepository = require("../repositories/ConversacionRepository");
const UsuarioRepository = require("../repositories/UsuarioRepository");
const TraduccionService = require("./TraduccionService");
const Mensaje = require("../models/Mensaje");

class ChatService {
  // 📤 ENVIAR MENSAJE
  static async enviarMensaje({ conversacionId, remitenteId, texto }) {
    // 1. Validar que la conversación existe
    const conversacion = await ConversacionRepository.obtenerPorId(conversacionId);
    if (!conversacion) throw new Error("Conversación no encontrada");

    console.log("👥 Participantes de la conversación:", conversacion.participantes);

    // 2. Obtener el idioma del remitente (desde su perfil, no adivinado)
    const remitente = await UsuarioRepository.buscarPorId(remitenteId);
    const idiomaOriginal = remitente?.idiomaPredeterminado || "Español";

    console.log(`📌 Remitente: ${remitenteId} → idioma: ${idiomaOriginal}`);

    // 3. Obtener los idiomas de los participantes
    const participantes = conversacion.participantes;
    const traducciones = {};

    // 4. Traducir para cada participante (excepto el remitente)
    for (const uid of participantes) {
      if (uid === remitenteId) continue; // No traducir para el remitente

      const usuario = await UsuarioRepository.buscarPorId(uid);
      console.log(`📌 Revisando uid=${uid} → usuario encontrado:`, usuario);

      if (usuario && usuario.idiomaPredeterminado) {
        const traducido = await TraduccionService.traducir(
          texto,
          usuario.idiomaPredeterminado,
          idiomaOriginal
        );
        traducciones[usuario.idiomaPredeterminado] = traducido;
      } else {
        console.log(`⚠️ El usuario ${uid} no existe o no tiene idiomaPredeterminado`);
      }
    }

    // 5. Crear el mensaje
    const mensaje = new Mensaje({
      conversacionId,
      remitenteId,
      textoOriginal: texto,
      idiomaOriginal,
      textoTraducido: traducciones,
    });

    // 6. Guardar en Firestore
    const mensajeGuardado = await MensajeRepository.guardar(mensaje);

    // 7. Actualizar el último mensaje de la conversación
    await ConversacionRepository.actualizarUltimoMensaje(
      conversacionId,
      texto,
      traducciones
    );

    return mensajeGuardado;
  }

  // 📥 OBTENER MENSAJES DE UNA CONVERSACIÓN
  static async obtenerMensajes(conversacionId, limit = 50) {
    const mensajes = await MensajeRepository.obtenerPorConversacion(conversacionId, limit);
    return mensajes.reverse(); // Orden cronológico (del más antiguo al más nuevo)
  }

  // 🔄 OBTENER O CREAR CONVERSACIÓN ENTRE DOS USUARIOS
  static async obtenerOCrearConversacion(uid1, uid2) {
    let conversacion = await ConversacionRepository.obtenerConversacionEntre(uid1, uid2);

    if (!conversacion) {
      conversacion = await ConversacionRepository.crear([uid1, uid2], "individual");
    }

    return conversacion;
  }

  // 📋 OBTENER CONVERSACIONES DE UN USUARIO
  static async obtenerConversaciones(uid) {
    const conversaciones = await ConversacionRepository.obtenerConversacionesDeUsuario(uid);

    const conversacionesEnriquecidas = await Promise.all(
      conversaciones.map(async (conv) => {
        const otroParticipante = conv.participantes.find(p => p !== uid);
        if (otroParticipante) {
          const usuario = await UsuarioRepository.buscarPorId(otroParticipante);
          return {
            ...conv,
            contacto: usuario ? {
              id: usuario.id,
              nombre: usuario.nombre,
              apellido: usuario.apellido || "",
              foto_url: usuario.foto_url || "",
              idioma: usuario.idiomaPredeterminado || "Español"
            } : null
          };
        }
        return conv;
      })
    );

    return conversacionesEnriquecidas;
  }

  // ✅ MARCAR MENSAJES COMO LEÍDOS
  static async marcarComoLeidos(conversacionId, userId) {
    await MensajeRepository.marcarComoLeidos(conversacionId, userId);
  }
}

module.exports = ChatService;