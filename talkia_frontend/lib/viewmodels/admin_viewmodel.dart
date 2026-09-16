import 'package:flutter/foundation.dart';
import '../data/models/Usuario_Model.dart';
import '../data/services/Admin_Service.dart';

class AdminViewModel extends ChangeNotifier {
  List<UsuarioModel> _usuarios = [];
  bool _cargando = false;
  String? _errorMessage;

  List<UsuarioModel> get usuarios => _usuarios;
  bool get cargando => _cargando;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _cargando = value;
    notifyListeners();
  }

  String _limpiarError(dynamic e) => e.toString().replaceFirst('Exception: ', '');

  // ─── LISTAR ─────────────────────────────────────────────
  Future<bool> cargarUsuarios() async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _usuarios = await AdminService.listarUsuarios();
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = _limpiarError(e);
      _setLoading(false);
      return false;
    }
  }

  // ─── CREAR ADMIN ────────────────────────────────────────
  Future<bool> crearAdmin({
    required String correo,
    required String password,
    required String nombre,
    required String apellido,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await AdminService.crearAdmin(
        correo: correo,
        password: password,
        nombre: nombre,
        apellido: apellido,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = _limpiarError(e);
      _setLoading(false);
      return false;
    }
  }

  // ─── BLOQUEAR / DESBLOQUEAR ─────────────────────────────
  // Actualiza el usuario en la lista local con lo que devuelve el backend
  Future<bool> cambiarEstado({
    required String usuarioId,
    required String estado,
  }) async {
    _errorMessage = null;
    try {
      final actualizado = await AdminService.cambiarEstado(
        usuarioId: usuarioId,
        estado: estado,
      );
      _reemplazarEnLista(actualizado);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _limpiarError(e);
      notifyListeners();
      return false;
    }
  }

  // ─── HACER / QUITAR ADMIN ───────────────────────────────
  Future<bool> cambiarRol({
    required String usuarioId,
    required String rol,
  }) async {
    _errorMessage = null;
    try {
      final actualizado = await AdminService.cambiarRol(
        usuarioId: usuarioId,
        rol: rol,
      );
      _reemplazarEnLista(actualizado);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _limpiarError(e);
      notifyListeners();
      return false;
    }
  }

  void _reemplazarEnLista(UsuarioModel actualizado) {
    final index = _usuarios.indexWhere((u) => u.id == actualizado.id);
    if (index != -1) {
      _usuarios[index] = actualizado;
    }
  }
}