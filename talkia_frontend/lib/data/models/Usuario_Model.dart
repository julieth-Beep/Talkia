class UsuarioModel {
  final String? id;
  final String correo;
  final String nombre;
  final String apellido;
  final String username;
  final String fotoUrl;
  final String idiomaPredeterminado;
  final String info; 
  final String rol;
  final String estado;

  UsuarioModel({
    this.id,
    required this.correo,
    required this.nombre,
    required this.apellido,
    this.username = "",
    this.fotoUrl = "",
    this.idiomaPredeterminado = "Español",
    this.info = 'Disponible',
    this.rol = "usuario",
    this.estado = "activo",
  });

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      id: json['id'],
      correo: json['correo'],
      nombre: json['nombre'],
      apellido: json['apellido'] ?? "",
      username: json['username'] ?? "",
      fotoUrl: json['foto_url'] ?? "",
      idiomaPredeterminado: json['idiomaPredeterminado'] ?? "Español",
      info: json['info'] ?? 'Disponible',
      rol: json['rol'] ?? "usuario",
      estado: json['estado'] ?? "activo",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'correo': correo,
      'nombre': nombre,
      'apellido': apellido,
      'idiomaPredeterminado': idiomaPredeterminado,
    };
  }
}