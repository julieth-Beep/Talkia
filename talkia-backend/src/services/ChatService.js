const MensajeRepository = require("../repositories/MensajeRepository");
const ConversacionRepository = require("../repositories/ConversacionRepository");
const UsuarioRepository = require("../repositories/UsuarioRepository");
const TraduccionService = require("./TraduccionService");
const Mensaje = require("../models/Mensaje");
const DiccionarioService = require("./DiccionarioService");

class ChatService {
  // ─── ENVIAR MENSAJE (texto) — sirve para 1 a 1 Y grupos ───
  static async enviarMensaje({ conversacionId, remitenteId, texto }) {
    const conversacion = await ConversacionRepository.obtenerPorId(conversacionId);
    if (!conversacion) throw new Error("Conversación no encontrada");

    const remitente = await UsuarioRepository.buscarPorId(remitenteId);
    const idiomaOriginal = remitente?.idiomaPredeterminado || "Español";

    const traducciones = await ChatService.calcularTraducciones({
      texto,
      idiomaOriginal,
      participantes: conversacion.participantes,
      remitenteId,
    });

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

  // ─── TRADUCCIONES PARA LOS DESTINATARIOS ────────────────
  // Agrupa los demás participantes por idioma (deduplicación):
  // si 3 miembros hablan Inglés, se hace UNA sola traducción, no tres.
  static async calcularTraducciones({ texto, idiomaOriginal, participantes, remitenteId }) {
    const otrosUids = participantes.filter(uid => uid !== remitenteId);

    const otros = await Promise.all(
      otrosUids.map(uid => UsuarioRepository.buscarPorId(uid))
    );

    // Por cada idioma único, guardamos un uid "representante"
    // (el representante se usa para buscar el diccionario personalizado)
    const representantePorIdioma = {}; // ej: { "Inglés": "uidB", "Francés": "uidC" }
    otros.forEach(usuario => {
      if (!usuario) return; // participante eliminado
      const idioma = usuario.idiomaPredeterminado || "Español";
      if (!representantePorIdioma[idioma]) {
        representantePorIdioma[idioma] = usuario.id;
      }
    });

    const traducciones = {};
    for (const [idioma, uidRepresentante] of Object.entries(representantePorIdioma)) {
      // Si el destinatario habla el idioma del remitente, no hay nada que traducir
      if (idioma === idiomaOriginal) continue;

      // Diccionario personalizado del remitente hacia el miembro representante
      const textoConDiccionario = await DiccionarioService.aplicarDiccionario(
        texto, remitenteId, uidRepresentante
      );

      // FIRMA REAL: traducir(texto, idiomaDestino, idiomaOrigen)
      traducciones[idioma] = await TraduccionService.traducir(
        textoConDiccionario, idioma, idiomaOriginal
      );
    }

    return traducciones;
  }

  // ─── OBTENER MENSAJES DE UNA CONVERSACIÓN ───────────────
  static async obtenerMensajes(conversacionId, limit = 50) {
    const mensajes = await MensajeRepository.obtenerPorConversacion(conversacionId, limit);
    const invertidos = mensajes.reverse();

    // Nombres de los remitentes (para grupos)
    const uids = [...new Set(invertidos.map(m => m.remitenteId))];
    const usuarios = await Promise.all(
      uids.map(uid => UsuarioRepository.buscarPorId(uid))
    );
    const nombrePorUid = {};
    usuarios.forEach(u => { if (u) nombrePorUid[u.id] = u.nombre; });

    return invertidos.map(m => ({
      ...m,
      remitenteNombre: nombrePorUid[m.remitenteId] || "Usuario",
    }));
  }

  // ─── OBTENER O CREAR CONVERSACIÓN (1 a 1) ───────────────
  static async obtenerOCrearConversacion(uid1, uid2) {
    let conversacion = await ConversacionRepository.obtenerConversacionEntre(uid1, uid2);
    if (!conversacion) {
      conversacion = await ConversacionRepository.crear([uid1, uid2], "individual");
    }
    return conversacion;
  }

  // ─── OBTENER CONVERSACIONES DE UN USUARIO ───────────────
  static async obtenerConversaciones(uid) {
    const conversaciones = await ConversacionRepository.obtenerConversacionesDeUsuario(uid);

    // Filtrar
    const conversacionesConContenido = conversaciones.filter((conv) => {
      if (conv.tipo === "grupal") return true;
      return conv.ultimoMensaje != null && conv.ultimoMensaje !== "";
    });

    const ContactoRepository = require("../repositories/ContactoRepository");

    const conversacionesEnriquecidas = await Promise.all(
      conversacionesConContenido.map(async (conv) => {
        // GRUPO
        if (conv.tipo === "grupal") {
          return {
            ...conv,
            esGrupo: true,
            cantidadMiembros: conv.participantes.length,
          };
        }

        // INDIVIDUAL
        const otroParticipante = conv.participantes.find(p => p !== uid);
        if (otroParticipante) {
          const usuario = await UsuarioRepository.buscarPorId(otroParticipante);

          let contacto = null;
          try {
            contacto = await ContactoRepository.buscarPorDuenoYContacto(
              uid,
              otroParticipante
            );
          } catch (e) {
            console.log("⚠️ No se pudo verificar contacto:", e.message);
          }

          let nombreMostrar;
          if (contacto) {
            // 1. Si es contacto, usar nombre personalizado
            nombreMostrar = contacto.nombrePersonalizado;
          } else if (usuario) {
            // 2. Si NO es contacto:
            const username = usuario.username;
            const esUsernameValido = username &&
              username.trim() !== "" &&
              username.toLowerCase() !== "undefined";

            if (esUsernameValido) {
              // 2a. Tiene username válido → mostrar @username
              nombreMostrar = `@${username}`;
            } else {
              // 2b. No tiene username → mostrar nombre + apellido
              const nombreCompleto = `@${usuario.nombre || ""} ${usuario.apellido || ""}`.trim();
              nombreMostrar = nombreCompleto || "Usuario";
            }
          } else {
            nombreMostrar = "Usuario";
          }

          return {
            ...conv,
            nombreMostrar,
            esContacto: !!contacto,
            contacto: usuario ? {
              id: usuario.id,
              nombre: usuario.nombre,
              apellido: usuario.apellido || "",
              username: usuario.username,
              foto_url: usuario.foto_url || "",
              idioma: usuario.idiomaPredeterminado || "Español",
            } : null,
          };
        }
        return conv;
      })
    );

    return conversacionesEnriquecidas;
  }

  // ─── MARCAR MENSAJES COMO LEÍDOS ────────────────────────
  static async marcarComoLeidos(conversacionId, userId) {
    await MensajeRepository.marcarComoLeidos(conversacionId, userId);
  }

  // ─── ENVIAR MENSAJE DE AUDIO ────────────────────────────
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

  // ─── CREAR GRUPO ────────────────────────────────────────
  static async crearGrupo({ nombre, creadorId, participantes }) {
    if (!nombre || nombre.trim() === "") {
      throw new Error("El nombre del grupo es obligatorio.");
    }
    if (!Array.isArray(participantes) || participantes.length < 3) {
      throw new Error("Un grupo necesita mínimo 3 participantes.");
    }

    // Verificar que todos los participantes existan
    const verificaciones = await Promise.all(
      participantes.map(uid => UsuarioRepository.buscarPorId(uid))
    );
    const inexistentes = participantes.filter((uid, i) => !verificaciones[i]);
    if (inexistentes.length > 0) {
      throw new Error(`Usuarios no encontrados: ${inexistentes.join(", ")}`);
    }

    // El creador siempre queda dentro del grupo
    if (!participantes.includes(creadorId)) {
      participantes.push(creadorId);
    }

    return await ConversacionRepository.crearGrupo({
      nombre: nombre.trim(),
      creadorId,
      participantes,
    });
  }

  // Nuevo método: eliminar conversación si está vacía
  static async eliminarSiEstaVacia(conversacionId) {
    const conversacion = await ConversacionRepository.obtenerPorId(conversacionId);
    if (!conversacion) return;

    // Solo eliminar si es individual y no tiene mensajes
    if (
      conversacion.tipo === "individual" &&
      (!conversacion.ultimoMensaje || conversacion.ultimoMensaje === "")
    ) {
      await ConversacionRepository.eliminar(conversacionId);
    }
  }

  static async obtenerParticipantes(conversacionId) {
    const conversacion = await ConversacionRepository.obtenerPorId(conversacionId);
    if (!conversacion) throw new Error("Conversación no encontrada");

    if (conversacion.tipo !== "grupal") {
      throw new Error("Esta conversación no es un grupo");
    }

    // Obtener la info de cada participante
    const participantes = await Promise.all(
      conversacion.participantes.map(async (uid) => {
        const usuario = await UsuarioRepository.buscarPorId(uid);
        if (!usuario) return null;
        return {
          id: usuario.id,
          nombre: usuario.nombre,
          apellido: usuario.apellido || "",
          username: usuario.username,
          foto_url: usuario.foto_url || "",
          idiomaPredeterminado: usuario.idiomaPredeterminado || "Español",
          esCreador: usuario.id === conversacion.creadorId,
        };
      })
    );

    return participantes.filter(p => p !== null);
  }
}

module.exports = ChatService;