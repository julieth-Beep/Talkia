const db = require("../config/firebase");

class MensajeRepository {
  // Guardar un mensaje en Firestore
  static async guardar(mensaje) {
    const docRef = await db.collection("mensajes").add({ ...mensaje });
    return { id: docRef.id, ...mensaje };
  }

  // Obtener mensajes de una conversación (ordenados por fecha)
  static async obtenerPorConversacion(conversacionId, limit = 50) {
    // Quitamos el .orderBy de Firestore para evitar el error de índice compuesto
    const snapshot = await db
      .collection("mensajes")
      .where("conversacionId", "==", conversacionId)
      .limit(limit * 2) // Traemos un poco más por seguridad
      .get();

    if (snapshot.empty) return [];

    // Mapeamos y ordenamos en memoria
    const mensajes = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    
    // Ordenar del más nuevo al más viejo
    mensajes.sort((a, b) => {
      const fa = new Date(a.fecha).getTime();
      const fb = new Date(b.fecha).getTime();
      return fb - fa; 
    });

    return mensajes.slice(0, limit);
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