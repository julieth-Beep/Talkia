const ContactoService = require("../services/ContactoService");

class ContactoController {
  // POST /api/contactos
  static async agregar(req, res) {
    try {
      const { duenoId, contactoId, nombrePersonalizado } = req.body;
      const contacto = await ContactoService.agregarContacto({
        duenoId, contactoId, nombrePersonalizado
      });
      res.status(201).json(contacto);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  }

  // GET /api/contactos/:duenoId
  static async listar(req, res) {
    try {
      const { duenoId } = req.params;
      const contactos = await ContactoService.listarContactos(duenoId);
      res.status(200).json(contactos);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  }

  // GET /api/contactos/buscar-usuario/:duenoId?q=xxx
  static async buscarUsuario(req, res) {
    try {
      const { duenoId } = req.params;
      const { q } = req.query;
      const usuarios = await ContactoService.buscarUsuarioParaAgregar(duenoId, q || "");
      res.status(200).json(usuarios);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  }

  // GET /api/contactos/mis-contactos/:duenoId?q=xxx
  static async buscarEnMisContactos(req, res) {
    try {
      const { duenoId } = req.params;
      const { q } = req.query;
      const contactos = await ContactoService.buscarEnMisContactos(duenoId, q || "");
      res.status(200).json(contactos);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  }

  // PATCH /api/contactos/:contactoId
  static async actualizar(req, res) {
    try {
      const { contactoId } = req.params;
      const resultado = await ContactoService.actualizarContacto(contactoId, req.body);
      res.status(200).json(resultado);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  }

  // DELETE /api/contactos/:contactoId
  static async eliminar(req, res) {
    try {
      const { contactoId } = req.params;
      const resultado = await ContactoService.eliminarContacto(contactoId);
      res.status(200).json(resultado);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  }

  static async personasDisponibles(req, res) {
    try {
      const { duenoId } = req.params;
      const personas = await ContactoService.obtenerPersonasDisponibles(duenoId);
      res.status(200).json(personas);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  }

  static async obtenerNombreAMostrar(req, res) {
    try {
      const { duenoId, contactoId } = req.params;
      const resultado = await ContactoService.obtenerNombreAMostrar(
        duenoId,
        contactoId
      );
      if (!resultado) {
        return res.status(404).json({ error: "Usuario no encontrado" });
      }
      res.status(200).json(resultado);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  }
}

module.exports = ContactoController;