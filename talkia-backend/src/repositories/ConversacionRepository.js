const db = require("../config/firebase");

class ConversacionRepository {
  // Crear una nueva conversación
  static async crear(participantes, tipo = "individual") {
    const nuevaConv = {
      participantes: participantes,
      tipo: tipo,
      fechaCreacion: new Date().toISOString(),
      fechaActualizacion: new Date().toISOString(),
      ultimoMensaje: "",
      ultimoMensajeTraducido: {},
    };

    const docRef = await db.collection("conversaciones").add(nuevaConv);
    return { id: docRef.id, ...nuevaConv };
  }

  // Crear conversación GRUPAL
  static async crearGrupo({ nombre, creadorId, participantes }) {
    const nuevaConv = {
      participantes: participantes, // incluye al creador
      tipo: "grupal",
      nombre: nombre,
      creadorId: creadorId,
      fechaCreacion: new Date().toISOString(),
      fechaActualizacion: new Date().toISOString(),
      ultimoMensaje: "",
      ultimoMensajeTraducido: {},
    };

    const docRef = await db.collection("conversaciones").add(nuevaConv);
    return { id: docRef.id, ...nuevaConv };
  }

  // Obtener todas las conversaciones de un usuario
  static async obtenerConversacionesDeUsuario(uid) {
    const snapshot = await db
      .collection("conversaciones")
      .where("participantes", "array-contains", uid)
      .get();

    if (snapshot.empty) return [];

    const conversaciones = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

    // Ordenar en memoria (evita índice compuesto)
    conversaciones.sort((a, b) =>
      (b.fechaActualizacion || "").localeCompare(a.fechaActualizacion || "")
    );

    return conversaciones;
  }

  // Actualizar el último mensaje de una conversación
  static async actualizarUltimoMensaje(conversacionId, mensaje, textoTraducido) {
    await db.collection("conversaciones").doc(conversacionId).update({
      ultimoMensaje: mensaje,
      ultimoMensajeTraducido: textoTraducido,
      fechaActualizacion: new Date().toISOString()
    });
  }

  // Obtener conversación por ID
  static async obtenerPorId(id) {
    const doc = await db.collection("conversaciones").doc(id).get();
    if (!doc.exists) return null;
    return { id: doc.id, ...doc.data() };
  }

  // Buscar conversación 1 a 1 entre dos usuarios
  static async obtenerConversacionEntre(uid1, uid2) {
    const snapshot = await db
      .collection("conversaciones")
      .where("participantes", "array-contains", uid1)
      .where("tipo", "==", "individual")
      .get();

    for (const doc of snapshot.docs) {
      const data = doc.data();
      if (data.participantes.includes(uid2) && data.participantes.length === 2) {
        return { id: doc.id, ...data };
      }
    }
    return null;
  }

  static async eliminar(id) {
    await db.collection("conversaciones").doc(id).delete();
  }
}

module.exports = ConversacionRepository;