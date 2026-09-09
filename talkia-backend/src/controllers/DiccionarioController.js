const DiccionarioService = require("../services/DiccionarioService");

class DiccionarioController {
  static async agregarPalabra(req, res) {
    try {
      const { usuarioId, contactoId, palabraOriginal, traduccionFija } = req.body;
      const entrada = await DiccionarioService.agregarPalabra({
        usuarioId,
        contactoId,
        palabraOriginal,
        traduccionFija,
      });
      res.status(201).json(entrada);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  }

  static async obtenerDiccionario(req, res) {
    try {
      const { usuarioId, contactoId } = req.params;
      const entradas = await DiccionarioService.obtenerDiccionario(usuarioId, contactoId);
      res.status(200).json(entradas);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  }

  static async eliminarPalabra(req, res) {
    try {
      const { id } = req.params;
      await DiccionarioService.eliminarPalabra(id);
      res.status(200).json({ mensaje: "Palabra eliminada" });
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  }
}

module.exports = DiccionarioController;