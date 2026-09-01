import 'package:flutter/material.dart';
import 'dart:async';
import '../data/models/Usuario_Model.dart';
import '../data/services/Usuario_Service.dart';
import 'package:google_sign_in/google_sign_in.dart';

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

  Future<bool> iniciarSesion({
    required String correo,
    required String password,
  }) async {
    _setLoading(true);
    try {
      _usuario = await UsuarioService.iniciarSesion(correo: correo, password: password);
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
    await googleSignIn.initialize(
      clientId: "689429424255-gb61ctcs54586q0q4o0ur93vo9ch0pcq.apps.googleusercontent.com",
    );

    _googleSub = googleSignIn.authenticationEvents.listen((event) async {
      if (event is GoogleSignInAuthenticationEventSignIn) {
        await _procesarLoginGoogle(event.user);
      }
    }, onError: (error) {
      _setError("Error con Google: $error");
    });

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
      _setError("Error al iniciar sesión con Google: ${e.description ?? e.code}");
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

      _usuario = await UsuarioService.loginConGoogle(idToken: idToken);
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
}