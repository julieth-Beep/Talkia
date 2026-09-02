import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/Mensaje_Model.dart';
import '../models/Conversacion_Model.dart';

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

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
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

  static Future<List<ConversacionModel>> obtenerConversaciones(String uid) async {
    final response = await http.get(Uri.parse("$baseUrl/conversaciones/$uid"));

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return List<ConversacionModel>.from(data.map((c) => ConversacionModel.fromJson(c)));
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
      // Falla silenciosa: no es crítico para la experiencia del chat
    }
  }
}