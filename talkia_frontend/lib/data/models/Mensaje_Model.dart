class MensajeModel {
  final String? id;
  final String conversacionId;
  final String remitenteId;
  final String textoOriginal;
  final String idiomaOriginal;
  final Map<String, String> textoTraducido;
  final DateTime fecha;
  final bool leido;

  MensajeModel({
    this.id,
    required this.conversacionId,
    required this.remitenteId,
    required this.textoOriginal,
    required this.idiomaOriginal,
    this.textoTraducido = const {},
    required this.fecha,
    this.leido = false,
  });

  factory MensajeModel.fromJson(Map<String, dynamic> json) {
    return MensajeModel(
      id: json['id'],
      conversacionId: json['conversacionId'],
      remitenteId: json['remitenteId'],
      textoOriginal: json['textoOriginal'],
      idiomaOriginal: json['idiomaOriginal'] ?? 'Español',
      textoTraducido: json['textoTraducido'] != null
          ? Map<String, String>.from(json['textoTraducido'])
          : {},
      fecha: DateTime.parse(json['fecha']),
      leido: json['leido'] ?? false,
    );
  }
}