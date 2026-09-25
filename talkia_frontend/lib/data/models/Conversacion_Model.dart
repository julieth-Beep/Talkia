class ConversacionModel {
  final String id;
  final List<String> participantes;
  final String tipo;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;
  final String? ultimoMensaje;
  final Map<String, String>? ultimoMensajeTraducido;
  final Map<String, dynamic>? contacto;
  final String? nombre;
  final bool esGrupo;
  final int? cantidadMiembros;
  final String? nombreMostrar;  
  final bool esContacto;         

  ConversacionModel({
    required this.id,
    required this.participantes,
    required this.tipo,
    required this.fechaCreacion,
    required this.fechaActualizacion,
    this.ultimoMensaje,
    this.ultimoMensajeTraducido,
    this.contacto,
    this.nombre,
    this.esGrupo = false,
    this.cantidadMiembros,
    this.nombreMostrar,        
    this.esContacto = false,   
  });

  factory ConversacionModel.fromJson(Map<String, dynamic> json) {
    return ConversacionModel(
      id: json['id'],
      participantes: List<String>.from(json['participantes'] ?? []),
      tipo: json['tipo'] ?? 'individual',
      fechaCreacion: DateTime.parse(json['fechaCreacion']),
      fechaActualizacion: DateTime.parse(json['fechaActualizacion']),
      ultimoMensaje: json['ultimoMensaje'],
      ultimoMensajeTraducido: json['ultimoMensajeTraducido'] != null
          ? Map<String, String>.from(json['ultimoMensajeTraducido'])
          : null,
      contacto: json['contacto'],
      nombre: json['nombre'],
      esGrupo: json['tipo'] == 'grupal',
      cantidadMiembros: json['cantidadMiembros'],
      nombreMostrar: json['nombreMostrar'],        
      esContacto: json['esContacto'] ?? false,      
    );
  }
}