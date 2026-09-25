class MensajeModel {
  final String? id;
  final String conversacionId;
  final String remitenteId;
  final String tipo; // "texto" o "audio"
  final String? textoOriginal;
  final String? idiomaOriginal;
  final Map<String, String> textoTraducido;
  final String? audioUrl;
  final DateTime fecha;
  final bool leido;
  final String? remitenteNombre; // ← campo nuevo

  MensajeModel({
    this.id,
    required this.conversacionId,
    required this.remitenteId,
    this.tipo = "texto",
    this.textoOriginal,
    this.idiomaOriginal,
    this.textoTraducido = const {},
    this.audioUrl,
    required this.fecha,
    this.leido = false,
    this.remitenteNombre,
  });

  factory MensajeModel.fromJson(Map<String, dynamic> json) {
    return MensajeModel(
      id: json['id'],
      conversacionId: json['conversacionId'],
      remitenteId: json['remitenteId'],
      tipo: json['tipo'] ?? 'texto',
      textoOriginal: json['textoOriginal'],
      idiomaOriginal: json['idiomaOriginal'],
      textoTraducido: json['textoTraducido'] != null
          ? Map<String, String>.from(json['textoTraducido'])
          : {},
      audioUrl: json['audioUrl'],
      fecha: DateTime.parse(json['fecha']),
      leido: json['leido'] ?? false,
      remitenteNombre: json['remitenteNombre'],
    );
  }
}
