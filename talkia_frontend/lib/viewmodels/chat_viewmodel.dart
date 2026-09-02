import 'dart:async';
import 'package:flutter/material.dart';
import '../data/models/Mensaje_Model.dart';
import '../data/models/Conversacion_Model.dart';
import '../data/services/Chat_Service.dart';

class ChatViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  List<MensajeModel> _mensajes = [];
  List<ConversacionModel> _conversaciones = [];
  Timer? _pollingTimer;
  String? _conversacionEscuchada;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<MensajeModel> get mensajes => _mensajes;
  List<ConversacionModel> get conversaciones => _conversaciones;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> enviarMensaje({
    required String conversacionId,
    required String remitenteId,
    required String texto,
  }) async {
    if (texto.trim().isEmpty) return false;

    try {
      await ChatService.enviarMensaje(
        conversacionId: conversacionId,
        remitenteId: remitenteId,
        texto: texto.trim(),
      );
      // Refrescamos inmediatamente después de enviar
      await _cargarMensajes(conversacionId);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void iniciarEscuchaMensajes(String conversacionId) {
    _conversacionEscuchada = conversacionId;
    _cargarMensajes(conversacionId);

    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _cargarMensajes(conversacionId);
    });
  }

  Future<void> _cargarMensajes(String conversacionId) async {
    try {
      final nuevos = await ChatService.obtenerMensajes(conversacionId);
      _mensajes = nuevos;
      notifyListeners();
    } catch (e) {
      debugPrint("Error en polling de mensajes: $e");
    }
  }

  void detenerEscuchaMensajes() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _conversacionEscuchada = null;
  }

  Future<ConversacionModel?> obtenerOCrearConversacion({
    required String uid1,
    required String uid2,
  }) async {
    _setLoading(true);
    try {
      final conversacion = await ChatService.obtenerOCrearConversacion(uid1: uid1, uid2: uid2);
      _setLoading(false);
      return conversacion;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return null;
    }
  }

  Future<void> cargarConversaciones(String uid) async {
    _setLoading(true);
    try {
      _conversaciones = await ChatService.obtenerConversaciones(uid);
      _setLoading(false);
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> marcarComoLeidos({
    required String conversacionId,
    required String userId,
  }) async {
    await ChatService.marcarComoLeidos(conversacionId: conversacionId, userId: userId);
  }

  String obtenerTextoTraducido(MensajeModel mensaje, String idiomaUsuario) {
    return mensaje.textoTraducido[idiomaUsuario] ?? mensaje.textoOriginal;
  }

  bool esMensajePropio(MensajeModel mensaje, String userId) {
    return mensaje.remitenteId == userId;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _isLoading = false;
    _errorMessage = message;
    notifyListeners();
  }

  @override
  void dispose() {
    detenerEscuchaMensajes();
    super.dispose();
  }
}