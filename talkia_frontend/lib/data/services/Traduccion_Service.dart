import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class TraduccionService {
  static String get baseUrl {
    if (kIsWeb) {
      return "http://localhost:3000/api/traduccion";
    } else if (Platform.isAndroid) {
      return "http://10.0.2.2:3000/api/traduccion"; // tu IP local
    } else {
      return "http://localhost:3000/api/traduccion";
    }
  }

  static Future<String> traducir({
    required String texto,
    required String idiomaDestino,
    String idiomaOrigen = "Español",
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/traducir"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "texto": texto,
        "idiomaDestino": idiomaDestino,
        "idiomaOrigen": idiomaOrigen,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data["traduccion"];
    } else {
      throw Exception(data["error"] ?? "Error al traducir");
    }
  }
}