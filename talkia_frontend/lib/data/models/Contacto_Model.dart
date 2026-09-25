class ContactoModel {
  final String id;
  final String nombrePersonalizado;
  final bool favorito;
  final DateTime fechaAgregado;
  final UsuarioContacto? usuario;

  ContactoModel({
    required this.id,
    required this.nombrePersonalizado,
    this.favorito = false,
    required this.fechaAgregado,
    this.usuario,
  });

  factory ContactoModel.fromJson(Map<String, dynamic> json) {
    return ContactoModel(
      id: json['id'],
      nombrePersonalizado: json['nombrePersonalizado'],
      favorito: json['favorito'] ?? false,
      fechaAgregado: DateTime.parse(json['fechaAgregado']),
      usuario: json['usuario'] != null
          ? UsuarioContacto.fromJson(json['usuario'])
          : null,
    );
  }
}

class UsuarioContacto {
  final String id;
  final String nombre;
  final String apellido;
  final String username;
  final String fotoUrl;
  final String idiomaPredeterminado;
  final String? nombrePersonalizado;   
  final bool esContacto;   

  UsuarioContacto({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.username,
    required this.fotoUrl,
    required this.idiomaPredeterminado,
    this.nombrePersonalizado,
    this.esContacto = false,
  });

  String get nombreMostrar =>
      (nombrePersonalizado != null && nombrePersonalizado!.isNotEmpty)
          ? nombrePersonalizado!
          : "$nombre $apellido".trim();

  factory UsuarioContacto.fromJson(Map<String, dynamic> json) {
    return UsuarioContacto(
      id: json['id'],
      nombre: json['nombre'] ?? '',
      apellido: json['apellido'] ?? '',
      username: json['username'] ?? '',
      fotoUrl: json['foto_url'] ?? '',
      idiomaPredeterminado: json['idiomaPredeterminado'] ?? 'Español',
      nombrePersonalizado: json['nombrePersonalizado'],
      esContacto: json['esContacto'] ?? false,
    );
  }
}