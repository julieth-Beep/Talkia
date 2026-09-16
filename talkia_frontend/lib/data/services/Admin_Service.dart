import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/Usuario_Model.dart';
import 'Usuario_Service.dart'; // para reutilizar obtenerToken()

class AdminService {
  
  static String get baseUrl {
    if (kIsWeb) {
      // Flutter Web (Chrome, Edge, etc.)
      return "http://localhost:3000/api/admin";
    } else if (Platform.isAndroid) {
      // Emulador de Android (10.0.2.2 apunta al localhost de tu PC)
      // Si pruebas en un celular físico, cambia esto por tu IP local (ej. 192.168.1.X)
      return "http://10.0.2.2:3000/api/admin";
    } else if (Platform.isIOS) {
      // Simulador de iOS
      return "http://localhost:3000/api/admin";
    } else {
      // Windows, macOS, Linux (desktop)
      return "http://localhost:3000/api/admin";
    }
  }

  // ─── HEADERS CON JWT ─────────────────────────────────────
  // Toda petición de admin manda el token guardado en el login
  static Future<Map<String, String>> _headers() async {
    final token = await UsuarioService.obtenerToken();
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  // Traduce 401/403 a mensajes claros (se repite en cada método)
  static Exception _errorDeRespuesta(int statusCode, dynamic data) {
    if (statusCode == 401) {
      return Exception("Tu sesión expiró. Inicia sesión de nuevo.");
    }
    if (statusCode == 403) {
      return Exception("No tienes permisos de administrador.");
    }
    return Exception(data["error"] ?? "Error inesperado ($statusCode)");
  }

  // ─── POST /crear-admin ───────────────────────────────────
  static Future<UsuarioModel> crearAdmin({
    required String correo,
    required String password,
    required String nombre,
    required String apellido,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/crear-admin"),
      headers: await _headers(),
      body: jsonEncode({
        "correo": correo,
        "password": password,
        "nombre": nombre,
        "apellido": apellido,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return UsuarioModel.fromJson(data);
    }
    throw _errorDeRespuesta(response.statusCode, data);
  }

  // ─── GET /usuarios ───────────────────────────────────────
  static Future<List<UsuarioModel>> listarUsuarios() async {
    final response = await http.get(
      Uri.parse("$baseUrl/usuarios"),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> lista = jsonDecode(response.body);
      return lista.map((json) => UsuarioModel.fromJson(json)).toList();
    }

    final data = jsonDecode(response.body);
    throw _errorDeRespuesta(response.statusCode, data);
  }

  // ─── PATCH /usuarios/:id/estado ──────────────────────────
  // estado: "activo" | "bloqueado"
  static Future<UsuarioModel> cambiarEstado({
    required String usuarioId,
    required String estado,
  }) async {
    final response = await http.patch(
      Uri.parse("$baseUrl/usuarios/$usuarioId/estado"),
      headers: await _headers(),
      body: jsonEncode({"estado": estado}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return UsuarioModel.fromJson(data);
    }
    throw _errorDeRespuesta(response.statusCode, data);
  }

  // ─── PATCH /usuarios/:id/rol ─────────────────────────────
  // rol: "usuario" | "admin"
  static Future<UsuarioModel> cambiarRol({
    required String usuarioId,
    required String rol,
  }) async {
    final response = await http.patch(
      Uri.parse("$baseUrl/usuarios/$usuarioId/rol"),
      headers: await _headers(),
      body: jsonEncode({"rol": rol}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return UsuarioModel.fromJson(data);
    }
    throw _errorDeRespuesta(response.statusCode, data);
  }
}