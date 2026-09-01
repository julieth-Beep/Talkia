class Usuario {
  constructor({
    correo,
    contraseña = null, 
    nombre,
    apellido = "",
    username = "",
    idiomaPredeterminado = "Español",
    foto_url = "",
    rol = "usuario",
    estado = "activo",
    intentosFallidos = 0,
    proveedor = "local", 
    fechaRegistro = new Date().toISOString(),
  }) {
    this.correo = correo;
    this.contraseña = contraseña;
    this.nombre = nombre;
    this.apellido = apellido;
    this.username = username && username.trim() !== "" ? username : `${nombre} ${apellido}`.trim();
    this.foto_url = foto_url;
    this.idiomaPredeterminado = idiomaPredeterminado;
    this.rol = rol;
    this.estado = estado;
    this.intentosFallidos = intentosFallidos;
    this.proveedor = proveedor;
    this.fechaRegistro = fechaRegistro;
  }
}

module.exports = Usuario;