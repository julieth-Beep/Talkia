import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/Contacto_Model.dart';

class ContactoService {
  static String get baseUrl {
    if (kIsWeb) return "http://localhost:3000/api/contactos";
    if (Platform.isAndroid) return "http://10.0.2.2:3000/api/contactos";
    return "http://localhost:3000/api/contactos";
  }

  // Agregar contacto
  static Future<ContactoModel> agregarContacto({
    required String duenoId,
    required String contactoId,
    required String nombrePersonalizado,
  }) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "duenoId": duenoId,
        "contactoId": contactoId,
        "nombrePersonalizado": nombrePersonalizado,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 201) {
      return ContactoModel.fromJson(data);
    }
    throw Exception(data["error"] ?? "Error al agregar contacto");
  }

  // Listar mis contactos
  static Future<List<ContactoModel>> listarContactos(String duenoId) async {
    final response = await http.get(Uri.parse("$baseUrl/$duenoId"));
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return (data as List).map((c) => ContactoModel.fromJson(c)).toList();
    }
    throw Exception(data["error"] ?? "Error al listar contactos");
  }

  // Buscar usuarios para agregar
  static Future<List<UsuarioContacto>> buscarUsuario({
    required String duenoId,
    required String query,
  }) async {
    final response = await http.get(
      Uri.parse("$baseUrl/buscar-usuario/$duenoId?q=$query"),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return (data as List).map((u) => UsuarioContacto.fromJson(u)).toList();
    }
    throw Exception(data["error"] ?? "Error al buscar usuario");
  }

  // Buscar en mis contactos (por nombre personalizado o username)
  static Future<List<ContactoModel>> buscarEnMisContactos({
    required String duenoId,
    required String query,
  }) async {
    final response = await http.get(
      Uri.parse("$baseUrl/mis-contactos/$duenoId?q=$query"),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return (data as List).map((c) => ContactoModel.fromJson(c)).toList();
    }
    throw Exception(data["error"] ?? "Error al buscar en contactos");
  }

  // Actualizar nombre personalizado
  static Future<void> actualizarNombre({
    required String contactoId,
    required String nuevoNombre,
  }) async {
    final response = await http.patch(
      Uri.parse("$baseUrl/$contactoId"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"nombrePersonalizado": nuevoNombre}),
    );
    if (response.statusCode != 200) {
      throw Exception("Error al actualizar contacto");
    }
  }

  // Eliminar contacto
  static Future<void> eliminarContacto(String contactoId) async {
    final response = await http.delete(Uri.parse("$baseUrl/$contactoId"));
    if (response.statusCode != 200) {
      throw Exception("Error al eliminar contacto");
    }
  }

  static Future<List<UsuarioContacto>> personasDisponibles(
    String duenoId,
  ) async {
    final response = await http.get(
      Uri.parse("$baseUrl/personas-disponibles/$duenoId"),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return (data as List).map((u) => UsuarioContacto.fromJson(u)).toList();
    }
    throw Exception(data["error"] ?? "Error al obtener personas");
  }

  // Obtener el nombre a mostrar (personalizado si es contacto, si no username)
  static Future<Map<String, String>> obtenerDatosAMostrar({
    required String duenoId,
    required String contactoId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/nombre-amostrar/$duenoId/$contactoId"),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'nombre': data['nombreAMostrar'] ?? '',
          'foto': data['foto_url'] ?? '',
        };
      }
    } catch (_) {}
    return {'nombre': '', 'foto': ''};
  }

  // Mantén el método viejo para compatibilidad (devuelve solo el nombre)
  static Future<String> obtenerNombreAMostrar({
    required String duenoId,
    required String contactoId,
  }) async {
    final datos = await obtenerDatosAMostrar(
      duenoId: duenoId,
      contactoId: contactoId,
    );
    return datos['nombre'] ?? '';
  }
}
