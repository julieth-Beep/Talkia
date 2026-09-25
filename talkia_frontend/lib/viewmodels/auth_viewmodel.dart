import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import '../data/models/Usuario_Model.dart';
import '../data/services/Usuario_Service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  UsuarioModel? _usuario;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UsuarioModel? get usuario => _usuario;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> registrar({
    required String correo,
    required String password,
    required String nombre,
    required String apellido,
  }) async {
    _setLoading(true);
    try {
      _usuario = await UsuarioService.registrar(
        correo: correo,
        password: password,
        nombre: nombre,
        apellido: apellido,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  String? _token;
  String? get token => _token;

  Future<bool> iniciarSesion({
    required String correo,
    required String password,
  }) async {
    _setLoading(true);
    try {
      final resultado = await UsuarioService.iniciarSesion(
        correo: correo,
        password: password,
      );
      _usuario = resultado["usuario"];
      _token = resultado["token"];
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  Future<bool> completarPerfil({
    required String id,
    String? username,
    String? idiomaPredeterminado,
    String? fotoUrl,
  }) async {
    _setLoading(true);
    try {
      _usuario = await UsuarioService.completarPerfil(
        id: id,
        username: username,
        idiomaPredeterminado: idiomaPredeterminado,
        fotoUrl: fotoUrl,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  // ─── CERRAR SESIÓN ──────────────────────────────────────
  Future<void> cerrarSesion() async {
    // Cerrar sesión de Google (por si inició con Google)
    try {
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.signOut();
    } catch (_) {
      // Si no había sesión de Google, ignorar
    }

    // Limpiar todo el estado local
    _usuario = null;
    _token = null;
    _errorMessage = null;
    _isLoading = false;

    // Notificar a la UI
    notifyListeners();
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

  bool _googleInicializado = false;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _googleSub;

  // Se llama SIEMPRE al iniciar la pantalla de login (Web y móvil)
  // Configura el SDK y activa el listener que detecta cuando el usuario
  // completa el login desde el botón renderizado por Google (Web)
  Future<void> inicializarGoogleSignIn() async {
    if (_googleInicializado) return;

    final googleSignIn = GoogleSignIn.instance;

    if (kIsWeb) {
      await googleSignIn.initialize(
        clientId:
            "61499064639-ploo04oufa9dtqh2a5eibpovg7nlpr2o.apps.googleusercontent.com",
      );
    } else {
      await googleSignIn.initialize(
        serverClientId:
            "61499064639-ploo04oufa9dtqh2a5eibpovg7nlpr2o.apps.googleusercontent.com",
      );
    }

    // 👇 LISTENER SOLO EN WEB
    if (kIsWeb) {
      _googleSub = googleSignIn.authenticationEvents.listen(
        (event) async {
          if (event is GoogleSignInAuthenticationEventSignIn) {
            await _procesarLoginGoogle(event.user);
          }
        },
        onError: (error) {
          _setError("Error con Google: $error");
        },
      );
    }

    _googleInicializado = true;
    notifyListeners();
  }

  // Se usa SOLO en Android/iOS, disparado por tu propio botón
  Future<bool> iniciarSesionConGoogle() async {
    _setLoading(true);
    try {
      final googleSignIn = GoogleSignIn.instance;
      final cuentaGoogle = await googleSignIn.authenticate();
      await _procesarLoginGoogle(cuentaGoogle);
      return _usuario != null;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        _isLoading = false;
        notifyListeners();
        return false;
      }
      _setError(
        "Error al iniciar sesión con Google: ${e.description ?? e.code}",
      );
      return false;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  Future<void> _procesarLoginGoogle(GoogleSignInAccount cuentaGoogle) async {
    _setLoading(true);
    try {
      final autenticacion = cuentaGoogle.authentication;
      final idToken = autenticacion.idToken;

      if (idToken == null) {
        throw Exception("No se pudo obtener el token de Google.");
      }

      final resultado = await UsuarioService.loginConGoogle(idToken: idToken);
      _usuario = resultado["usuario"];
      _token = resultado["token"];
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  void dispose() {
    _googleSub?.cancel();
    super.dispose();
  }

  Future<bool> solicitarRecuperacion({required String correo}) async {
    _setLoading(true);
    try {
      await UsuarioService.solicitarRecuperacion(correo: correo);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  Future<bool> restablecerContrasena({
    required String correo,
    required String token,
    required String nuevaPassword,
  }) async {
    _setLoading(true);
    try {
      await UsuarioService.restablecerContrasena(
        correo: correo,
        token: token,
        nuevaPassword: nuevaPassword,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  Future<bool> actualizarFotoPerfil({required File foto}) async {
    _setLoading(true);
    try {
      _usuario = await UsuarioService.actualizarFotoPerfil(
        usuarioId: _usuario!.id!,
        foto: foto,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  Future<bool> actualizarDatosPersonales({
    String? nombre,
    String? apellido,
    String? correo,
  }) async {
    if (_usuario?.id == null) return false;

    _setLoading(true);
    try {
      _usuario = await UsuarioService.actualizarDatosPersonales(
        usuarioId: _usuario!.id!,
        nombre: nombre,
        apellido: apellido,
        correo: correo,
      );
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  Future<bool> actualizarInfo({required String info}) async {
    if (_usuario?.id == null) return false;

    _setLoading(true);
    try {
      _usuario = await UsuarioService.actualizarInfo(
        usuarioId: _usuario!.id!,
        info: info,
      );
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }
}
