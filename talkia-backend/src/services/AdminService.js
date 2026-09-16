const bcrypt = require("bcrypt");
const Usuario = require("../models/Usuario");
const UsuarioRepository = require("../repositories/UsuarioRepository");

class AdminService {
  // ─── CREAR OTRO ADMIN (solo un admin puede llegar aquí) ──
  static async crearAdmin({ correo, password, nombre, apellido, username }) {
    if (!password || password.length < 8) {
      throw new Error("La contraseña debe tener mínimo 8 caracteres.");
    }
    if (!nombre || !apellido) {
      throw new Error("Nombre y apellido son obligatorios.");
    }

    if (username && username.length > 20) {
      throw new Error("El username no puede superar 20 caracteres.");
    }

    const existente = await UsuarioRepository.buscarPorCorreo(correo);
    if (existente) {
      throw new Error("El correo ya está registrado.");
    }

    const contraseñaEncriptada = await bcrypt.hash(password, 10);

    const nuevoAdmin = new Usuario({
      correo,
      contraseña: contraseñaEncriptada,
      nombre,
      apellido,
      username: username || "",   
      rol: "admin",   // ← la única diferencia con el registro normal
    });

    return await UsuarioRepository.guardar(nuevoAdmin);
  }

  // ─── LISTAR USUARIOS ────────────────────────────────────
  static async listarUsuarios() {
    const usuarios = await UsuarioRepository.listarTodos();
    return usuarios.map(({ contraseña, ...resto }) => resto);
  }

  // ─── BLOQUEAR / DESBLOQUEAR ─────────────────────────────
  static async cambiarEstado(usuarioId, estado) {
    if (!["activo", "bloqueado"].includes(estado)) {
      throw new Error("Estado inválido. Use 'activo' o 'bloqueado'.");
    }

    const usuario = await UsuarioRepository.buscarPorId(usuarioId);
    if (!usuario) {
      throw new Error("Usuario no encontrado.");
    }

    const cambios = { estado };
    if (estado === "activo") cambios.intentosFallidos = 0;

    return await UsuarioRepository.actualizarPorId(usuarioId, cambios);
  }

  // ─── CAMBIAR ROL (usuario ↔ admin) ──────────────────────
  static async cambiarRol(usuarioId, rol) {
    if (!["usuario", "admin"].includes(rol)) {
      throw new Error("Rol inválido. Use 'usuario' o 'admin'.");
    }

    const usuario = await UsuarioRepository.buscarPorId(usuarioId);
    if (!usuario) {
      throw new Error("Usuario no encontrado.");
    }

    return await UsuarioRepository.actualizarPorId(usuarioId, { rol });
  }
}

module.exports = AdminService;