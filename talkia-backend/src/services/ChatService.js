const MensajeRepository = require("../repositories/MensajeRepository");
const ConversacionRepository = require("../repositories/ConversacionRepository");
const UsuarioRepository = require("../repositories/UsuarioRepository");
const TraduccionService = require("./TraduccionService");
const Mensaje = require("../models/Mensaje");
const DiccionarioService = require("./DiccionarioService");

class ChatService {
  // ENVIAR MENSAJE
  static async enviarMensaje({ conversacionId, remitenteId, texto }) {
    const conversacion = await ConversacionRepository.obtenerPorId(conversacionId);
    if (!conversacion) throw new Error("Conversación no encontrada");

    const remitente = await UsuarioRepository.buscarPorId(remitenteId);
    const idiomaOriginal = remitente?.idiomaPredeterminado || "Español";

    const participantes = conversacion.participantes;
    const traducciones = {};

    for (const uid of participantes) {
      if (uid === remitenteId) continue;

      const usuario = await UsuarioRepository.buscarPorId(uid);
      if (usuario && usuario.idiomaPredeterminado) {
        // Aplica el diccionario personalizado del remitente para ESTE contacto
        const textoConDiccionario = await DiccionarioService.aplicarDiccionario(texto, remitenteId, uid);

        const traducido = await TraduccionService.traducir(
          textoConDiccionario,
          usuario.idiomaPredeterminado,
          idiomaOriginal
        );
        traducciones[usuario.idiomaPredeterminado] = traducido;
      }
    }

    const mensaje = new Mensaje({
      conversacionId,
      remitenteId,
      textoOriginal: texto,
      idiomaOriginal,
      textoTraducido: traducciones,
    });

    const mensajeGuardado = await MensajeRepository.guardar(mensaje);

    await ConversacionRepository.actualizarUltimoMensaje(conversacionId, texto, traducciones);

    return mensajeGuardado;
  }

  // OBTENER MENSAJES DE UNA CONVERSACIÓN
  static async obtenerMensajes(conversacionId, limit = 50) {
    const mensajes = await MensajeRepository.obtenerPorConversacion(conversacionId, limit);
    return mensajes.reverse();
  }

  // OBTENER O CREAR CONVERSACIÓN
  static async obtenerOCrearConversacion(uid1, uid2) {
    let conversacion = await ConversacionRepository.obtenerConversacionEntre(uid1, uid2);
    if (!conversacion) {
      conversacion = await ConversacionRepository.crear([uid1, uid2], "individual");
    }
    return conversacion;
  }

  // OBTENER CONVERSACIONES DE UN USUARIO
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

  // MARCAR MENSAJES COMO LEÍDOS
  static async marcarComoLeidos(conversacionId, userId) {
    await MensajeRepository.marcarComoLeidos(conversacionId, userId);
  }

  // ENVIAR MENSAJE DE AUDIO
  static async enviarMensajeAudio({ conversacionId, remitenteId, nombreArchivo }) {
    const conversacion = await ConversacionRepository.obtenerPorId(conversacionId);
    if (!conversacion) throw new Error("Conversación no encontrada");

    const audioUrl = `/uploads/audios/${nombreArchivo}`;

    const mensaje = new Mensaje({
      conversacionId,
      remitenteId,
      tipo: "audio",
      audioUrl,
    });

    const mensajeGuardado = await MensajeRepository.guardar(mensaje);

    await ConversacionRepository.actualizarUltimoMensaje(conversacionId, "🎤 Nota de voz", {});

    return mensajeGuardado;
  }
}

module.exports = ChatService;