class DiccionarioEntryModel {
  final String? id;
  final String usuarioId;
  final String contactoId;
  final String palabraOriginal;
  final String traduccionFija;
  final DateTime? fechaCreacion;

  DiccionarioEntryModel({
    this.id,
    required this.usuarioId,
    required this.contactoId,
    required this.palabraOriginal,
    required this.traduccionFija,
    this.fechaCreacion,
  });

  factory DiccionarioEntryModel.fromJson(Map<String, dynamic> json) {
    return DiccionarioEntryModel(
      id: json['id'],
      usuarioId: json['usuarioId'],
      contactoId: json['contactoId'],
      palabraOriginal: json['palabraOriginal'],
      traduccionFija: json['traduccionFija'],
      fechaCreacion: json['fechaCreacion'] != null
          ? DateTime.tryParse(json['fechaCreacion'])
          : null,
    );
  }
}