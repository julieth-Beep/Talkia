const UsuarioService = require("../services/UsuarioService");

class UsuarioController {
  static async registrar(req, res) {
    try {
      const usuario = await UsuarioService.registrar(req.body);
      const { contraseña, ...usuarioSinPassword } = usuario;
      res.status(201).json(usuarioSinPassword);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  }

  static async iniciarSesion(req, res) {
    try {
      const usuario = await UsuarioService.iniciarSesion(req.body);
      const { contraseña, ref, ...usuarioSinPassword } = usuario;
      res.status(200).json(usuarioSinPassword);
    } catch (error) {
      res.status(401).json({ error: error.message });
    }
  }

  static async completarPerfil(req, res) {
    try {
      const { id } = req.params;
      const usuario = await UsuarioService.completarPerfil(id, req.body);
      const { contraseña, ref, ...usuarioSinPassword } = usuario;
      res.status(200).json(usuarioSinPassword);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  }

  static async loginConGoogle(req, res) {
    try {
      const { idToken } = req.body;
      if (!idToken) throw new Error("Falta el token de Google.");

      const usuario = await UsuarioService.loginConGoogle(idToken);
      const { contraseña, ref, ...usuarioSinPassword } = usuario;
      res.status(200).json(usuarioSinPassword);
    } catch (error) {
      res.status(401).json({ error: error.message });
    }
  }

  static async solicitarRecuperacion(req, res) {
    try {
      const { correo } = req.body;
      if (!correo) throw new Error("El correo es obligatorio.");
      const resultado = await UsuarioService.solicitarRecuperacion(correo);
      res.status(200).json(resultado);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  }

  static async restablecerContraseña(req, res) {
    try {
      const resultado = await UsuarioService.restablecerContraseña(req.body);
      res.status(200).json(resultado);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  }
}

module.exports = UsuarioController;