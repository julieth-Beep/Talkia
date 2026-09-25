const db = require("../config/firebase");

class ContactoRepository {
  // Guardar un nuevo contacto
  static async guardar(contacto) {
    // Verificar que no exista ya
    const existente = await this.buscarPorDuenoYContacto(
      contacto.duenoId,
      contacto.contactoId
    );
    if (existente) {
      throw new Error("Este usuario ya está en tus contactos.");
    }

    const docRef = await db.collection("contactos").add({ ...contacto });
    return { id: docRef.id, ...contacto };
  }

  // Buscar todos los contactos de un usuario
  static async obtenerContactosDeUsuario(duenoId) {
    const snapshot = await db
      .collection("contactos")
      .where("duenoId", "==", duenoId)
      .get();

    if (snapshot.empty) return [];
    return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
  }

  // Buscar contacto específico entre dos usuarios
  static async buscarPorDuenoYContacto(duenoId, contactoId) {
    const snapshot = await db
      .collection("contactos")
      .where("duenoId", "==", duenoId)
      .where("contactoId", "==", contactoId)
      .get();

    if (snapshot.empty) return null;
    const doc = snapshot.docs[0];
    return { id: doc.id, ref: doc.ref, ...doc.data() };
  }

  // Actualizar nombre personalizado
  static async actualizarNombre(contactoId, nuevoNombre) {
    const docRef = db.collection("contactos").doc(contactoId);
    await docRef.update({ nombrePersonalizado: nuevoNombre });
    const actualizado = await docRef.get();
    return { id: actualizado.id, ...actualizado.data() };
  }

  // Eliminar contacto
  static async eliminar(contactoId) {
    await db.collection("contactos").doc(contactoId).delete();
  }

  // Marcar/desmarcar como favorito
  static async toggleFavorito(contactoId, favorito) {
    await db.collection("contactos").doc(contactoId).update({ favorito });
  }

  static async buscarPorDuenoYContacto(duenoId, contactoId) {
    const snapshot = await db
      .collection("contactos")
      .where("duenoId", "==", duenoId)
      .where("contactoId", "==", contactoId)
      .get();

    if (snapshot.empty) return null;
    const doc = snapshot.docs[0];
    return { id: doc.id, ref: doc.ref, ...doc.data() };
  }
}

module.exports = ContactoRepository;