const Contacto = require("../models/Contacto");
const ContactoRepository = require("../repositories/ContactoRepository");
const UsuarioRepository = require("../repositories/UsuarioRepository");

class ContactoService {
  // ─── AGREGAR CONTACTO ───────────────────────────────────
  static async agregarContacto({ duenoId, contactoId, nombrePersonalizado }) {
    // 1. Validar que no sea el mismo usuario
    if (duenoId === contactoId) {
      throw new Error("No puedes agregarte a ti mismo como contacto.");
    }

    // 2. Validar que el usuario a agregar exista
    const usuario = await UsuarioRepository.buscarPorId(contactoId);
    if (!usuario) {
      throw new Error("El usuario no existe.");
    }

    // 3. Validar nombre personalizado
    if (!nombrePersonalizado || nombrePersonalizado.trim() === "") {
      throw new Error("Debes asignar un nombre personalizado.");
    }

    // 4. Crear el contacto
    const nuevoContacto = new Contacto({
      duenoId,
      contactoId,
      nombrePersonalizado: nombrePersonalizado.trim(),
    });

    return await ContactoRepository.guardar(nuevoContacto);
  }

  // ─── LISTAR CONTACTOS ───────────────────────────────────
  static async listarContactos(duenoId) {
    const contactos = await ContactoRepository.obtenerContactosDeUsuario(duenoId);

    // Enriquecer con información del usuario
    const contactosEnriquecidos = await Promise.all(
      contactos.map(async (contacto) => {
        const usuario = await UsuarioRepository.buscarPorId(contacto.contactoId);
        return {
          id: contacto.id,
          nombrePersonalizado: contacto.nombrePersonalizado,
          favorito: contacto.favorito,
          fechaAgregado: contacto.fechaAgregado,
          // Info del usuario (lo que se puede ver)
          usuario: usuario ? {
            id: usuario.id,
            nombre: usuario.nombre,
            apellido: usuario.apellido || "",
            username: usuario.username,
            foto_url: usuario.foto_url || "",
            idiomaPredeterminado: usuario.idiomaPredeterminado || "Español",
          } : null,
        };
      })
    );

    // Ordenar: favoritos primero, luego alfabético por nombre personalizado
    contactosEnriquecidos.sort((a, b) => {
      if (a.favorito && !b.favorito) return -1;
      if (!a.favorito && b.favorito) return 1;
      return a.nombrePersonalizado.localeCompare(b.nombrePersonalizado);
    });

    return contactosEnriquecidos;
  }

  // ─── BUSCAR USUARIO PARA AGREGAR ────────────────────────
  // Busca en TODOS los usuarios por username
  static async buscarUsuarioParaAgregar(duenoId, query) {
    const usuarios = await UsuarioRepository.listarTodos();

    // Normalizar búsqueda
    const q = query.toLowerCase().trim();

    // Filtrar por username o nombre
    const resultados = usuarios
      .filter(u => u.id !== duenoId) // excluirse a sí mismo
      .filter(u => {
        const username = (u.username || "").toLowerCase();
        const nombre = `${u.nombre} ${u.apellido || ""}`.toLowerCase();
        return username.includes(q) || nombre.includes(q);
      })
      .slice(0, 20) // máximo 20 resultados
      .map(u => ({
        id: u.id,
        nombre: u.nombre,
        apellido: u.apellido || "",
        username: u.username,
        foto_url: u.foto_url || "",
      }));

    return resultados;
  }

  // ─── BUSCAR EN MIS CONTACTOS ────────────────────────────
  // Busca SOLO dentro de los contactos del usuario (por nombre personalizado O username)
  static async buscarEnMisContactos(duenoId, query) {
    const contactos = await ContactoService.listarContactos(duenoId);

    const q = query.toLowerCase().trim();
    if (q === "") return contactos;

    return contactos.filter(c => {
      const nombrePersonalizado = (c.nombrePersonalizado || "").toLowerCase();
      const username = (c.usuario?.username || "").toLowerCase();
      return nombrePersonalizado.includes(q) || username.includes(q);
    });
  }

  // ─── ACTUALIZAR CONTACTO ────────────────────────────────
  static async actualizarContacto(contactoId, cambios) {
    if (cambios.nombrePersonalizado !== undefined) {
      return await ContactoRepository.actualizarNombre(
        contactoId,
        cambios.nombrePersonalizado.trim()
      );
    }
    if (cambios.favorito !== undefined) {
      await ContactoRepository.toggleFavorito(contactoId, cambios.favorito);
      return { mensaje: "Contacto actualizado" };
    }
  }

  // ─── ELIMINAR CONTACTO ──────────────────────────────────
  static async eliminarContacto(contactoId) {
    await ContactoRepository.eliminar(contactoId);
    return { mensaje: "Contacto eliminado." };
  }

  // ─── OBTENER PERSONAS DISPONIBLES PARA CHATEAR/GRUPO ────
  // Devuelve la unión de: contactos + participantes de conversaciones
  static async obtenerPersonasDisponibles(duenoId) {
    const UsuarioRepository = require("../repositories/UsuarioRepository");
    const ConversacionRepository = require("../repositories/ConversacionRepository");

    // 1. Obtener mis contactos
    const contactos = await ContactoService.listarContactos(duenoId);
    const idsContactos = new Set(contactos.map(c => c.usuario?.id).filter(Boolean));

    // 2. Obtener conversaciones del usuario
    const conversaciones = await ConversacionRepository.obtenerConversacionesDeUsuario(duenoId);

    // 3. Recolectar todos los participantes únicos (excluyendo al dueño)
    const idsDeConversaciones = new Set();
    conversaciones.forEach(conv => {
      conv.participantes.forEach(uid => {
        if (uid !== duenoId) idsDeConversaciones.add(uid);
      });
    });

    // 4. Unir ambos conjuntos (Set elimina duplicados)
    const idsUnicos = new Set([...idsContactos, ...idsDeConversaciones]);

    // 5. Traer la info completa de cada usuario
    const usuarios = await Promise.all(
      [...idsUnicos].map(uid => UsuarioRepository.buscarPorId(uid))
    );

    // 6. Mapear a formato consistente con nombrePersonalizado si es contacto
    const contactosMap = {};
    contactos.forEach(c => {
      if (c.usuario?.id) contactosMap[c.usuario.id] = c.nombrePersonalizado;
    });

    return usuarios
      .filter(u => u != null)
      .map(u => ({
        id: u.id,
        nombre: u.nombre,
        apellido: u.apellido || "",
        username: u.username,
        foto_url: u.foto_url || "",
        idiomaPredeterminado: u.idiomaPredeterminado || "Español",
        // Si es contacto, se muestra con su nombre personalizado
        nombrePersonalizado: contactosMap[u.id] || null,
        esContacto: !!contactosMap[u.id],
      }))
      .sort((a, b) => {
        // Contactos primero, luego alfabético
        if (a.esContacto && !b.esContacto) return -1;
        if (!a.esContacto && b.esContacto) return 1;
        const nombreA = (a.nombrePersonalizado || a.nombre).toLowerCase();
        const nombreB = (b.nombrePersonalizado || b.nombre).toLowerCase();
        return nombreA.localeCompare(nombreB);
      });
  }

  // ─── OBTENER NOMBRE A MOSTRAR DE UN CONTACTO ────────────
  // Devuelve el nombre personalizado si existe el contacto,
  // si no, devuelve el username del usuario
  static async obtenerNombreAMostrar(duenoId, contactoId) {
    const contacto = await ContactoRepository.buscarPorDuenoYContacto(
      duenoId,
      contactoId
    );

    const usuario = await UsuarioRepository.buscarPorId(contactoId);
    if (!usuario) return null;

    return {
      id: usuario.id,
      nombreAMostrar: contacto
        ? contacto.nombrePersonalizado
        : `@${usuario.username}`,
      esContacto: !!contacto,
      username: usuario.username,
      nombreReal: `${usuario.nombre} ${usuario.apellido || ""}`.trim(),
      foto_url: usuario.foto_url || "",  
    };
  }
}

module.exports = ContactoService;