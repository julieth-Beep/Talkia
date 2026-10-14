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

  // Eliminar todos los mensajes de una conversación
  static async eliminarPorConversacion(conversacionId) {
    const snapshot = await db
      .collection("mensajes")
      .where("conversacionId", "==", conversacionId)
      .get();

    if (snapshot.empty) return 0;

    // Firestore permite máximo 500 operaciones por batch
    const docs = snapshot.docs;
    let eliminados = 0;

    for (let i = 0; i < docs.length; i += 500) {
      const batch = db.batch();
      docs.slice(i, i + 500).forEach(doc => batch.delete(doc.ref));
      await batch.commit();
      eliminados += Math.min(500, docs.length - i);
    }

    return eliminados;
  }

  // Eliminar un mensaje por ID
  static async eliminarPorId(mensajeId) {
    const docRef = db.collection("mensajes").doc(mensajeId);
    const doc = await docRef.get();
    if (!doc.exists) throw new Error("Mensaje no encontrado");
    await docRef.delete();
  }
}

module.exports = MensajeRepository;