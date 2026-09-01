class ConversacionModel {
  final String id;
  final List<String> participantes;
  final String tipo;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;
  final String? ultimoMensaje;
  final Map<String, String>? ultimoMensajeTraducido;
  final Map<String, dynamic>? contacto;

  ConversacionModel({
    required this.id,
    required this.participantes,
    required this.tipo,
    required this.fechaCreacion,
    required this.fechaActualizacion,
    this.ultimoMensaje,
    this.ultimoMensajeTraducido,
    this.contacto,
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
    );
  }
}