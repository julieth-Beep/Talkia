import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'registro_view.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import '../home/InicioIngreso.dart';
import 'recuperarContraseña_view.dart';
import 'google_web_button.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _yaNavego = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthViewModel>().inicializarGoogleSignIn();
    });
  }

  @override
  void dispose() {
    _correoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _navegarAInicio() {
    if (_yaNavego || !mounted) return;
    _yaNavego = true;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const InicioIngresoView()),
    );
  }

  void _mostrarError(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: const Color(0xFFBA1A1A),
      ),
    );
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final viewModel = context.read<AuthViewModel>();
      viewModel.clearError();

      final exito = await viewModel.iniciarSesion(
        correo: _correoController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      if (exito) {
        _navegarAInicio();
      } else {
        _mostrarError(viewModel.errorMessage ?? 'Error desconocido');
      }
    }
  }

  Future<void> _iniciarSesionGoogle() async {
    final viewModel = context.read<AuthViewModel>();
    final exito = await viewModel.iniciarSesionConGoogle();
    if (!mounted) return;
    if (exito) {
      _navegarAInicio();
    } else if (viewModel.errorMessage != null) {
      _mostrarError(viewModel.errorMessage!);
    }
  }

  InputDecoration _buildInputDecoration(String hintText, IconData icon, {bool isPassword = false}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
      prefixIcon: Icon(icon, color: const Color(0xFF94A3B8)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF006677), width: 2),
      ),
      suffixIcon: isPassword
          ? const Icon(Icons.visibility_off_outlined, color: Color(0xFF94A3B8))
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthViewModel>().isLoading;
    final usuario = context.watch<AuthViewModel>().usuario;

    // Redirección automática cuando el login por Google (Web) se completa
    if (kIsWeb && usuario != null && !_yaNavego) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navegarAInicio();
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 80),

                // Logo
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.public, size: 40, color: Color(0xFF006677)),
                ),

                const SizedBox(height: 32),

                const Text(
                  'Bienvenido de nuevo',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ingresa a tu cuenta de\nTalkia.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Color(0xFF64748B), height: 1.5),
                ),

                const SizedBox(height: 48),

                // Campo Correo
                TextFormField(
                  controller: _correoController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _buildInputDecoration('tu@correo.com', Icons.email_outlined),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Ingresa tu correo';
                    if (!value.contains('@')) return 'Correo no válido';
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Fila de Contraseña y "Olvidaste tu contraseña"
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Contraseña',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                        );
                      }, 
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        '¿Olvidaste tu contraseña?',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF006677),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Campo Contraseña
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: _buildInputDecoration('........', Icons.lock_outline, isPassword: true),
                  validator: (value) => value != null && value.isEmpty ? 'Ingresa tu contraseña' : null,
                ),

                const SizedBox(height: 40),

                // Botón Iniciar Sesión
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006677),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF006677).withOpacity(0.6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Iniciar sesión', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),

                const SizedBox(height: 24),

                // Separador "o"
                Row(
                  children: [
                    const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('o', style: TextStyle(color: const Color(0xFF64748B).withOpacity(0.7))),
                    ),
                    const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                  ],
                ),

                const SizedBox(height: 24),

                // Botón de Google (rectangular, sin Facebook)
                kIsWeb
                    ? const _BotonGoogleWeb()
                    : SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: isLoading ? null : _iniciarSesionGoogle,
                          icon: const Icon(Icons.g_mobiledata, size: 24),
                          label: const Text(
                            'Continuar con Google',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),

                const SizedBox(height: 32),

                // "¿No tienes cuenta? Regístrate"
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '¿No tienes cuenta? ',
                      style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegistroView()),
                        );
                      },
                      child: const Text(
                        'Regístrate',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF006677)),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BotonGoogleWeb extends StatelessWidget {
  const _BotonGoogleWeb();

  @override
  Widget build(BuildContext context) {
    return buildGoogleWebButton();
  }
}