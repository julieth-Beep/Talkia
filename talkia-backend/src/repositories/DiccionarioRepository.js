const db = require("../config/firebase");
const coleccion = db.collection("diccionario_personalizado");

class DiccionarioRepository {
  static async guardar(entry) {
    const docRef = await coleccion.add({ ...entry });
    return { id: docRef.id, ...entry };
  }

  // Trae todas las entradas que un usuario configuró para un contacto específico
  static async obtenerPorUsuarioYContacto(usuarioId, contactoId) {
    const snapshot = await coleccion
      .where("usuarioId", "==", usuarioId)
      .where("contactoId", "==", contactoId)
      .get();

    if (snapshot.empty) return [];
    return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
  }

  static async eliminar(id) {
    await coleccion.doc(id).delete();
  }
}

module.exports = DiccionarioRepository;