import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/Usuario_Model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UsuarioService {
  // Detecta automáticamente la URL correcta según dónde se está ejecutando la app
  static String get baseUrl {
    if (kIsWeb) {
      // Flutter Web (Chrome, Edge, etc.)
      return "http://localhost:3000/api/usuarios";
    } else if (Platform.isAndroid) {
      // Emulador de Android (10.0.2.2 apunta al localhost de tu PC)
      // Si pruebas en un celular físico, cambia esto por tu IP local (ej. 192.168.1.X)
      return "http://10.0.2.2:3000/api/usuarios";
    } else if (Platform.isIOS) {
      // Simulador de iOS
      return "http://localhost:3000/api/usuarios";
    } else {
      // Windows, macOS, Linux (desktop)
      return "http://localhost:3000/api/usuarios";
    }
  }

  // Lo usan los demás servicios (Chat, Traducción, Admin) para mandar el header
  static Future<String?> obtenerToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  static Future<UsuarioModel> registrar({
    required String correo,
    required String password,
    required String nombre,
    required String apellido,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/registro"),
      headers: {"Content-Type": "application/json"},
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
    } else {
      throw Exception(data["error"] ?? "Error al registrar usuario");
    }
  }

  static Future<Map<String, dynamic>> iniciarSesion({
    required String correo,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"correo": correo, "password": password}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      // Guarda el token en el dispositivo para futuras peticiones
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("token", data["token"]);

      return {"usuario": UsuarioModel.fromJson(data), "token": data["token"]};
    } else {
      throw Exception(data["error"] ?? "Credenciales incorrectas");
    }
  }

  static Future<UsuarioModel> completarPerfil({
    required String id,
    String? username,
    String? idiomaPredeterminado,
    String? fotoUrl,
  }) async {
    final body = <String, dynamic>{};
    if (username != null && username.trim().isNotEmpty)
      body["username"] = username.trim();
    if (idiomaPredeterminado != null &&
        idiomaPredeterminado.trim().isNotEmpty) {
      body["idiomaPredeterminado"] = idiomaPredeterminado;
    }
    if (fotoUrl != null && fotoUrl.trim().isNotEmpty)
      body["foto_url"] = fotoUrl;

    final response = await http.patch(
      Uri.parse("$baseUrl/$id/perfil"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return UsuarioModel.fromJson(data);
    } else {
      throw Exception(data["error"] ?? "Error al actualizar perfil");
    }
  }

  static Future<Map<String, dynamic>> loginConGoogle({
    required String idToken,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/google"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"idToken": idToken}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      // Guarda el token igual que en iniciarSesion
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("token", data["token"]);

      return {"usuario": UsuarioModel.fromJson(data), "token": data["token"]};
    } else {
      throw Exception(data["error"] ?? "Error al iniciar sesión con Google");
    }
  }

  static Future<String> solicitarRecuperacion({required String correo}) async {
    final response = await http.post(
      Uri.parse("$baseUrl/recuperar"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"correo": correo}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data["mensaje"];
    } else {
      throw Exception(data["error"] ?? "Error al solicitar recuperación");
    }
  }

  static Future<String> restablecerContrasena({
    required String correo,
    required String token,
    required String nuevaPassword,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/restablecer"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "correo": correo,
        "token": token,
        "nuevaPassword": nuevaPassword,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data["mensaje"];
    } else {
      throw Exception(data["error"] ?? "Error al restablecer contraseña");
    }
  }

  static Future<List<UsuarioModel>> listarUsuarios({
    required String excluirId,
  }) async {
    final response = await http.get(Uri.parse("$baseUrl?excluir=$excluirId"));

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return List<UsuarioModel>.from(data.map((u) => UsuarioModel.fromJson(u)));
    } else {
      throw Exception(data["error"] ?? "Error al listar usuarios");
    }
  }
}
