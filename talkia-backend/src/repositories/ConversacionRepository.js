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

  // Buscar conversación entre dos usuarios
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

  // Obtener todas las conversaciones de un usuario
  static async obtenerConversacionesDeUsuario(uid) {
    const snapshot = await db
      .collection("conversaciones")
      .where("participantes", "array-contains", uid)
      .orderBy("fechaActualizacion", "desc")
      .get();

    if (snapshot.empty) return [];
    return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
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
}

module.exports = ConversacionRepository;