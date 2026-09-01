import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/Mensaje_Model.dart';
import '../data/models/Conversacion_Model.dart';
import '../data/services/Chat_Service.dart';

class ChatViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  List<MensajeModel> _mensajes = [];
  List<ConversacionModel> _conversaciones = [];
  ConversacionModel? _conversacionActual;
  StreamSubscription<QuerySnapshot>? _mensajesSubscription;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<MensajeModel> get mensajes => _mensajes;
  List<ConversacionModel> get conversaciones => _conversaciones;
  ConversacionModel? get conversacionActual => _conversacionActual;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // 📤 Enviar mensaje
  Future<bool> enviarMensaje({
    required String conversacionId,
    required String remitenteId,
    required String texto,
  }) async {
    if (texto.trim().isEmpty) return false;
    
    _setLoading(true);
    try {
      final mensaje = await ChatService.enviarMensaje(
        conversacionId: conversacionId,
        remitenteId: remitenteId,
        texto: texto.trim(),
      );
      
      // El listener de Firestore agregará el mensaje automáticamente
      // Pero por si acaso, lo agregamos localmente
      _mensajes.add(mensaje);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  // 📥 Escuchar mensajes en tiempo real DESDE FIRESTORE
  void iniciarEscuchaMensajes(String conversacionId) {
    // Cancelar suscripción anterior si existe
    _mensajesSubscription?.cancel();

    // 🔥 Escuchar cambios en Firestore
    _mensajesSubscription = FirebaseFirestore.instance
        .collection('mensajes')
        .where('conversacionId', isEqualTo: conversacionId)
        .orderBy('fecha', descending: false)
        .snapshots()
        .listen((snapshot) {
          // Esta función se ejecuta CADA VEZ que hay un cambio
          final nuevosMensajes = snapshot.docs
              .map((doc) => MensajeModel.fromJson({
                    'id': doc.id,
                    ...doc.data(),
                  }))
              .toList();
          
          _mensajes = nuevosMensajes;
          notifyListeners(); // 🔄 Actualiza la UI
        }, onError: (error) {
          _setError("Error al escuchar mensajes: $error");
        });
  }

  // 🛑 Dejar de escuchar mensajes
  void detenerEscuchaMensajes() {
    _mensajesSubscription?.cancel();
    _mensajesSubscription = null;
  }

  // 🔄 Obtener o crear conversación
  Future<ConversacionModel?> obtenerOCrearConversacion({
    required String uid1,
    required String uid2,
  }) async {
    _setLoading(true);
    try {
      final conversacion = await ChatService.obtenerOCrearConversacion(
        uid1: uid1,
        uid2: uid2,
      );
      _conversacionActual = conversacion;
      _setLoading(false);
      return conversacion;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return null;
    }
  }

  // 📋 Cargar conversaciones
  Future<void> cargarConversaciones(String uid) async {
    _setLoading(true);
    try {
      _conversaciones = await ChatService.obtenerConversaciones(uid);
      _setLoading(false);
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ✅ Marcar mensajes como leídos
  Future<void> marcarComoLeidos({
    required String conversacionId,
    required String userId,
  }) async {
    try {
      await ChatService.marcarComoLeidos(
        conversacionId: conversacionId,
        userId: userId,
      );
    } catch (e) {
      // No mostrar error al usuario
      print("Error al marcar leídos: $e");
    }
  }

  // 🌐 Obtener texto traducido para un usuario
  String obtenerTextoTraducido(MensajeModel mensaje, String idiomaUsuario) {
    return mensaje.textoTraducido[idiomaUsuario] ?? mensaje.textoOriginal;
  }

  // 👤 Verificar si el mensaje es del usuario actual
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