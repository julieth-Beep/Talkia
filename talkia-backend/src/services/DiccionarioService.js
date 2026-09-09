const DiccionarioRepository = require("../repositories/DiccionarioRepository");
const DiccionarioEntry = require("../models/DiccionarioEntry");

class DiccionarioService {
  static async agregarPalabra({ usuarioId, contactoId, palabraOriginal, traduccionFija }) {
    if (!palabraOriginal || !traduccionFija) {
      throw new Error("Se requiere la palabra original y su traducción fija.");
    }

    const entry = new DiccionarioEntry({ usuarioId, contactoId, palabraOriginal, traduccionFija });
    return await DiccionarioRepository.guardar(entry);
  }

  static async obtenerDiccionario(usuarioId, contactoId) {
    return await DiccionarioRepository.obtenerPorUsuarioYContacto(usuarioId, contactoId);
  }

  static async eliminarPalabra(id) {
    await DiccionarioRepository.eliminar(id);
  }

  // Aplica las reglas del diccionario sobre un texto ANTES de traducirlo
  static async aplicarDiccionario(texto, usuarioId, contactoId) {
    const entradas = await this.obtenerDiccionario(usuarioId, contactoId);
    if (entradas.length === 0) return texto;

    let textoModificado = texto;

    for (const entrada of entradas) {
      // Reemplazo insensible a mayúsculas, respetando límites de palabra
      const regex = new RegExp(`\\b${entrada.palabraOriginal}\\b`, "gi");
      textoModificado = textoModificado.replace(regex, entrada.traduccionFija);
    }

    return textoModificado;
  }
}

module.exports = DiccionarioService;