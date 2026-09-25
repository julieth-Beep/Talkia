import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/Mensaje_Model.dart';
import '../models/Conversacion_Model.dart';
import 'dart:io';

class ChatService {
  static String get baseUrl {
    if (kIsWeb) {
      return "http://localhost:3000/api/chat";
    } else if (Platform.isAndroid) {
      return "http://10.0.2.2:3000/api/chat";
    } else {
      return "http://localhost:3000/api/chat";
    }
  }

  static String get audioBaseUrl {
    if (kIsWeb) {
      return "http://localhost:3000";
    } else if (Platform.isAndroid) {
      return "http://10.0.2.2:3000";
    } else {
      return "http://localhost:3000";
    }
  }

  static Future<MensajeModel> enviarMensaje({
    required String conversacionId,
    required String remitenteId,
    required String texto,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/mensaje"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "conversacionId": conversacionId,
        "remitenteId": remitenteId,
        "texto": texto,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return MensajeModel.fromJson(data);
    } else {
      throw Exception(data["error"] ?? "Error al enviar mensaje");
    }
  }

  static Future<List<MensajeModel>> obtenerMensajes(
    String conversacionId, {
    int limit = 50,
  }) async {
    final response = await http.get(
      Uri.parse("$baseUrl/mensajes/$conversacionId?limit=$limit"),
    );

    var data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      // CORREGIR URLs de audio
      for (var mensaje in data) {
        if (mensaje['audioUrl'] != null) {
          String audioUrl = mensaje['audioUrl'];
          // Si la URL es relativa (empieza con /), completarla
          if (audioUrl.startsWith('/')) {
            mensaje['audioUrl'] = "$audioBaseUrl$audioUrl";
          }
        }
      }
      return List<MensajeModel>.from(data.map((m) => MensajeModel.fromJson(m)));
    } else {
      throw Exception(data["error"] ?? "Error al obtener mensajes");
    }
  }

  static Future<ConversacionModel> obtenerOCrearConversacion({
    required String uid1,
    required String uid2,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/conversacion"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"uid1": uid1, "uid2": uid2}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return ConversacionModel.fromJson(data);
    } else {
      throw Exception(data["error"] ?? "Error al crear conversación");
    }
  }

  static Future<List<ConversacionModel>> obtenerConversaciones(
    String uid,
  ) async {
    final response = await http.get(Uri.parse("$baseUrl/conversaciones/$uid"));

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return List<ConversacionModel>.from(
        data.map((c) => ConversacionModel.fromJson(c)),
      );
    } else {
      throw Exception(data["error"] ?? "Error al obtener conversaciones");
    }
  }

  static Future<void> marcarComoLeidos({
    required String conversacionId,
    required String userId,
  }) async {
    try {
      await http.patch(
        Uri.parse("$baseUrl/mensajes/$conversacionId/leer"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"userId": userId}),
      );
    } catch (_) {
      // Falla silenciosa
    }
  }

  static Future<MensajeModel> enviarMensajeAudio({
    required String conversacionId,
    required String remitenteId,
    required File archivoAudio,
  }) async {
    final request = http.MultipartRequest(
      "POST",
      Uri.parse("$baseUrl/mensaje-audio"),
    );

    request.fields["conversacionId"] = conversacionId;
    request.fields["remitenteId"] = remitenteId;
    request.files.add(
      await http.MultipartFile.fromPath("audio", archivoAudio.path),
    );

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    var data = jsonDecode(responseBody);

    if (response.statusCode == 201) {
      // CORREGIR URL del audio
      if (data['audioUrl'] != null) {
        String audioUrl = data['audioUrl'];
        if (audioUrl.startsWith('/')) {
          data['audioUrl'] = "$audioBaseUrl$audioUrl";
        }
      }
      return MensajeModel.fromJson(data);
    } else {
      throw Exception(data["error"] ?? "Error al enviar audio");
    }
  }

  static Future<ConversacionModel> crearGrupo({
    required String nombre,
    required String creadorId,
    required List<String> participantes,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/grupo"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "nombre": nombre,
        "creadorId": creadorId,
        "participantes": participantes,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 201) {
      return ConversacionModel.fromJson(data);
    }
    throw Exception(data["error"] ?? "Error al crear el grupo");
  }

  static Future<void> eliminarConversacionSiEstaVacia(
    String conversacionId,
  ) async {
    try {
      await http.delete(
        Uri.parse("$baseUrl/conversacion/$conversacionId/vacia"),
      );
    } catch (_) {
      // Falla silenciosa
    }
  }

  // ─── OBTENER PARTICIPANTES DE UN GRUPO ─────────────────
  static Future<List<Map<String, dynamic>>> obtenerParticipantes(
    String conversacionId,
  ) async {
    final response = await http.get(
      Uri.parse("$baseUrl/participantes/$conversacionId"),
      headers: {"Content-Type": "application/json"},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception(data["error"] ?? "Error al obtener participantes");
    }
  }
}
