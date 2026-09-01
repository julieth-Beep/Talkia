const db = require("../config/firebase");

class MensajeRepository {
  // Guardar un mensaje en Firestore
  static async guardar(mensaje) {
    const docRef = await db.collection("mensajes").add({ ...mensaje });
    return { id: docRef.id, ...mensaje };
  }

  // Obtener mensajes de una conversación (ordenados por fecha)
  static async obtenerPorConversacion(conversacionId, limit = 50) {
    const snapshot = await db
      .collection("mensajes")
      .where("conversacionId", "==", conversacionId)
      .orderBy("fecha", "desc")
      .limit(limit)
      .get();

    if (snapshot.empty) return [];
    return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
  }

  // Marcar mensajes como leídos (para el otro usuario)
  static async marcarComoLeidos(conversacionId, userId) {
    const snapshot = await db
      .collection("mensajes")
      .where("conversacionId", "==", conversacionId)
      .where("remitenteId", "!=", userId)
      .where("leido", "==", false)
      .get();

    const batch = db.batch();
    snapshot.docs.forEach(doc => {
      batch.update(doc.ref, { leido: true });
    });
    await batch.commit();
  }
}

module.exports = MensajeRepository;