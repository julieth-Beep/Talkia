import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/DiccionarioEntry_Model.dart';

class DiccionarioService {
  static String get baseUrl {
    if (kIsWeb) {
      return "http://localhost:3000/api/diccionario";
    } else if (Platform.isAndroid) {
      return "http://10.0.2.2:3000/api/diccionario"; // tu IP local actual
    } else {
      return "http://localhost:3000/api/diccionario";
    }
  }

  static Future<DiccionarioEntryModel> agregarPalabra({
    required String usuarioId,
    required String contactoId,
    required String palabraOriginal,
    required String traduccionFija,
  }) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "usuarioId": usuarioId,
        "contactoId": contactoId,
        "palabraOriginal": palabraOriginal,
        "traduccionFija": traduccionFija,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return DiccionarioEntryModel.fromJson(data);
    } else {
      throw Exception(data["error"] ?? "Error al agregar palabra");
    }
  }

  static Future<List<DiccionarioEntryModel>> obtenerDiccionario({
    required String usuarioId,
    required String contactoId,
  }) async {
    final response = await http.get(
      Uri.parse("$baseUrl/$usuarioId/$contactoId"),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return List<DiccionarioEntryModel>.from(
        data.map((e) => DiccionarioEntryModel.fromJson(e)),
      );
    } else {
      throw Exception(data["error"] ?? "Error al obtener diccionario");
    }
  }

  static Future<void> eliminarPalabra(String id) async {
    final response = await http.delete(Uri.parse("$baseUrl/$id"));

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data["error"] ?? "Error al eliminar palabra");
    }
  }
}