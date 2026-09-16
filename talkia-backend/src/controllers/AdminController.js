const AdminService = require("../services/AdminService");

class AdminController {
  static async crearAdmin(req, res) {
    try {
      const admin = await AdminService.crearAdmin(req.body);
      const { contraseña, ...adminSinPassword } = admin;
      res.status(201).json(adminSinPassword);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  }

  static async listarUsuarios(req, res) {
    try {
      const usuarios = await AdminService.listarUsuarios();
      res.status(200).json(usuarios);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  }

  static async cambiarEstado(req, res) {
    try {
      const { id } = req.params;
      const { estado } = req.body;
      const usuario = await AdminService.cambiarEstado(id, estado);
      const { contraseña, ...usuarioSinPassword } = usuario;
      res.status(200).json(usuarioSinPassword);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  }

  static async cambiarRol(req, res) {
    try {
      const { id } = req.params;
      const { rol } = req.body;
      const usuario = await AdminService.cambiarRol(id, rol);
      const { contraseña, ...usuarioSinPassword } = usuario;
      res.status(200).json(usuarioSinPassword);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  }
}

module.exports = AdminController;