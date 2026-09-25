const bcrypt = require("bcrypt");
const crypto = require("crypto");
const jwt = require("jsonwebtoken");
const { OAuth2Client } = require("google-auth-library");
const Usuario = require("../models/Usuario");
const UsuarioRepository = require("../repositories/UsuarioRepository");
const EmailService = require("./EmailService");


const client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

class UsuarioService {

  // ─── GENERAR TOKEN JWT ──────────────────────────────────
  static generarToken(usuario) {
    return jwt.sign(
      { uid: usuario.id, rol: usuario.rol || "usuario" },
      process.env.JWT_SECRET,
      { expiresIn: "7d" }
    );
  }

  // ─── REGISTRO ───────────────────────────────────────────
  static async registrar({ correo, password, nombre, apellido, idiomaPredeterminado }) {
    if (!password || password.length < 8) {
      throw new Error("La contraseña debe tener mínimo 8 caracteres.");
    }
    if (!nombre || !apellido) {
      throw new Error("Nombre y apellido son obligatorios.");
    }

    const existente = await UsuarioRepository.buscarPorCorreo(correo);
    if (existente) {
      throw new Error("El correo ya está registrado.");
    }

    const contraseñaEncriptada = await bcrypt.hash(password, 10);

    const nuevoUsuario = new Usuario({
      correo,
      contraseña: contraseñaEncriptada,
      nombre,
      apellido,
      idiomaPredeterminado: idiomaPredeterminado || "Español",
    });

    return await UsuarioRepository.guardar(nuevoUsuario);
  }

  // ─── LOGIN ──────────────────────────────────────────────
  static async iniciarSesion({ correo, password }) {
    const usuario = await UsuarioRepository.buscarPorCorreo(correo);

    if (!usuario) {
      throw new Error("Credenciales incorrectas.");
    }
    if (usuario.estado === "bloqueado") {
      throw new Error("Cuenta bloqueada por múltiples intentos fallidos.");
    }

    const passwordValida = await bcrypt.compare(password, usuario.contraseña);

    if (!passwordValida) {
      const intentos = (usuario.intentosFallidos || 0) + 1;
      const nuevoEstado = intentos >= 5 ? "bloqueado" : "activo";
      await UsuarioRepository.actualizar(usuario.ref, {
        intentosFallidos: intentos,
        estado: nuevoEstado,
      });
      throw new Error("Credenciales incorrectas.");
    }

    await UsuarioRepository.actualizar(usuario.ref, { intentosFallidos: 0 });
    return {
      usuario,
      token: UsuarioService.generarToken(usuario),
    };
  }

  // ─── COMPLETAR PERFIL ───────────────────────────────────
  static async completarPerfil(id, { username, idiomaPredeterminado, foto_url }) {
    const usuario = await UsuarioRepository.buscarPorId(id);
    if (!usuario) {
      throw new Error("Usuario no encontrado.");
    }

    const cambios = {};
    if (username && username.trim() !== "") cambios.username = username.trim();
    if (idiomaPredeterminado && idiomaPredeterminado.trim() !== "") cambios.idiomaPredeterminado = idiomaPredeterminado;
    if (foto_url && foto_url.trim() !== "") cambios.foto_url = foto_url;

    if (Object.keys(cambios).length === 0) {
      return usuario;
    }

    return await UsuarioRepository.actualizarPorId(id, cambios);
  }

  static async loginConGoogle(idToken) {
    // 1. Verificar que el token es real y viene de Google
    let payload;
    try {
      const ticket = await client.verifyIdToken({
        idToken,
        audience: process.env.GOOGLE_CLIENT_ID,
      });
      payload = ticket.getPayload();
    } catch (error) {
      throw new Error("Token de Google inválido.");
    }

    const { email, given_name, family_name, picture } = payload;

    // 2. Buscar si ya existe el usuario
    let usuario = await UsuarioRepository.buscarPorCorreo(email);

    if (usuario) {
      // Si el correo ya existía como registro local, no lo pisamos, solo dejamos entrar
      if (usuario.estado === "bloqueado") {
        throw new Error("Cuenta bloqueada por múltiples intentos fallidos.");
      }
      return {
        usuario,
        token: UsuarioService.generarToken(usuario)
      };
    }

    // 3. Si no existe, lo creamos automáticamente con los datos de Google
    const nuevoUsuario = new Usuario({
      correo: email,
      contraseña: null,
      nombre: given_name || "",
      apellido: family_name || "",
      foto_url: picture || "",
      proveedor: "google",
    });

    const nuevoUsuarioGuardado = await UsuarioRepository.guardar(nuevoUsuario);
    return {
      usuario: nuevoUsuarioGuardado,
      token: UsuarioService.generarToken(nuevoUsuarioGuardado),
    };
  }

  // ─── SOLICITAR RECUPERACIÓN ─────────────────────────────
  static async solicitarRecuperacion(correo) {
    const usuario = await UsuarioRepository.buscarPorCorreo(correo);

    // Por seguridad: mismo mensaje exista o no el correo
    if (!usuario) {
      return { mensaje: "Si el correo está registrado, recibirás un código." };
    }

    const codigo = crypto.randomInt(100000, 999999).toString();
    const expira = Date.now() + 15 * 60 * 1000; // 15 minutos

    await UsuarioRepository.actualizar(usuario.ref, {
      resetToken: codigo,
      resetTokenExpira: expira,
    });

    await EmailService.enviarCorreoRecuperacion(correo, codigo);

    return { mensaje: "Si el correo está registrado, recibirás un código." };
  }

  // ─── RESTABLECER CONTRASEÑA ─────────────────────────────
  static async restablecerContraseña({ correo, token, nuevaPassword }) {
    if (!nuevaPassword || nuevaPassword.length < 8) {
      throw new Error("La contraseña debe tener mínimo 8 caracteres.");
    }

    const usuario = await UsuarioRepository.buscarPorCorreo(correo);
    if (!usuario || !usuario.resetToken) {
      throw new Error("Código inválido o expirado.");
    }

    if (usuario.resetToken !== token) {
      throw new Error("Código inválido o expirado.");
    }

    if (Date.now() > usuario.resetTokenExpira) {
      throw new Error("El código ha expirado. Solicita uno nuevo.");
    }

    const nuevaEncriptada = await bcrypt.hash(nuevaPassword, 10);

    await UsuarioRepository.actualizar(usuario.ref, {
      contraseña: nuevaEncriptada,
      resetToken: null,
      resetTokenExpira: null,
      intentosFallidos: 0,
      estado: "activo",
    });

    return { mensaje: "Contraseña actualizada correctamente." };
  }

  static async listarUsuarios(excluirId) {
    const usuarios = await UsuarioRepository.listarTodos();
    return usuarios
      .filter(u => u.id !== excluirId)
      .map(({ contraseña, ...resto }) => resto); // nunca devolver la contraseña
  }

  static async actualizarFotoPerfil(usuarioId, nombreArchivo) {
    const usuario = await UsuarioRepository.buscarPorId(usuarioId);
    if (!usuario) throw new Error("Usuario no encontrado.");

    const fotoUrl = `/uploads/fotos_perfil/${nombreArchivo}`;
    await UsuarioRepository.actualizarPorId(usuarioId, { foto_url: fotoUrl });

    return { ...usuario, foto_url: fotoUrl };
  }

  // ─── ACTUALIZAR DATOS PERSONALES ────────────────────────
  static async actualizarDatosPersonales(id, { nombre, apellido, correo }) {
    const usuario = await UsuarioRepository.buscarPorId(id);
    if (!usuario) {
      throw new Error("Usuario no encontrado.");
    }

    const cambios = {};

    // Validar y actualizar nombre
    if (nombre !== undefined) {
      if (nombre.trim() === "") throw new Error("El nombre no puede estar vacío.");
      cambios.nombre = nombre.trim();
    }

    // Validar y actualizar apellido
    if (apellido !== undefined) {
      if (apellido.trim() === "") throw new Error("El apellido no puede estar vacío.");
      cambios.apellido = apellido.trim();
    }

    // Validar y actualizar correo
    if (correo !== undefined) {
      if (!correo.includes("@")) throw new Error("Correo no válido.");

      // Verificar que el nuevo correo no esté en uso por otro usuario
      const existente = await UsuarioRepository.buscarPorCorreo(correo);
      if (existente && existente.id !== id) {
        throw new Error("Ese correo ya está registrado por otro usuario.");
      }
      cambios.correo = correo.trim();
    }

    if (Object.keys(cambios).length === 0) {
      throw new Error("No hay cambios para actualizar.");
    }

    return await UsuarioRepository.actualizarPorId(id, cambios);
  }

  // ─── ACTUALIZAR INFO (ESTADO) ───────────────────────────
  static async actualizarInfo(id, info) {
    const usuario = await UsuarioRepository.buscarPorId(id);
    if (!usuario) throw new Error("Usuario no encontrado.");

    if (!info || info.trim() === "") {
      throw new Error("El estado no puede estar vacío.");
    }

    await UsuarioRepository.actualizarPorId(id, { info: info.trim() });

    const actualizado = await UsuarioRepository.buscarPorId(id);
    return actualizado;
  }
}

module.exports = UsuarioService;