const db = require("../config/firebase");
const coleccion = db.collection("usuarios");

class UsuarioRepository {
  static async guardar(usuario) {
    const docRef = await coleccion.add({ ...usuario });
    return { id: docRef.id, ...usuario };
  }

  static async buscarPorCorreo(correo) {
    const snapshot = await coleccion.where("correo", "==", correo).get();
    if (snapshot.empty) return null;
    const doc = snapshot.docs[0];
    return { id: doc.id, ref: doc.ref, ...doc.data() };
  }

  static async buscarPorId(id) {
    const doc = await coleccion.doc(id).get();
    if (!doc.exists) return null;
    return { id: doc.id, ref: doc.ref, ...doc.data() };
  }

  static async actualizar(ref, cambios) {
    await ref.update(cambios);
  }

  static async actualizarPorId(id, cambios) {
    const docRef = coleccion.doc(id);
    await docRef.update(cambios);
    const actualizado = await docRef.get();
    return { id: actualizado.id, ...actualizado.data() };
  }
}

module.exports = UsuarioRepository;