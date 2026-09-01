import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'login_view.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _correoController = TextEditingController();

  // true = ya se envió el correo, ahora se pide código + nueva contraseña
  bool _correoEnviado = false;

  final _tokenController = TextEditingController();
  final _nuevaPasswordController = TextEditingController();
  final _confirmarPasswordController = TextEditingController();

  @override
  void dispose() {
    _correoController.dispose();
    _tokenController.dispose();
    _nuevaPasswordController.dispose();
    _confirmarPasswordController.dispose();
    super.dispose();
  }

  void _enviarCorreo() async {
    if (_formKey.currentState!.validate()) {
      final viewModel = context.read<AuthViewModel>();
      viewModel.clearError();

      final exito = await viewModel.solicitarRecuperacion(
        correo: _correoController.text.trim(),
      );

      if (!mounted) return;

      if (exito) {
        setState(() => _correoEnviado = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Revisa tu correo, te enviamos un código.'),
            backgroundColor: Color(0xFF006677),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(viewModel.errorMessage ?? 'Error desconocido'),
            backgroundColor: const Color(0xFFBA1A1A),
          ),
        );
      }
    }
  }

  void _restablecer() async {
    if (_formKey.currentState!.validate()) {
      if (_nuevaPasswordController.text != _confirmarPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Las contraseñas no coinciden'), backgroundColor: Color(0xFFBA1A1A)),
        );
        return;
      }

      final viewModel = context.read<AuthViewModel>();
      viewModel.clearError();

      final exito = await viewModel.restablecerContrasena(
        correo: _correoController.text.trim(),
        token: _tokenController.text.trim(),
        nuevaPassword: _nuevaPasswordController.text.trim(),
      );

      if (!mounted) return;

      if (exito) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Contraseña actualizada!'), backgroundColor: Color(0xFF006677)),
        );
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginView()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(viewModel.errorMessage ?? 'Error desconocido'), backgroundColor: const Color(0xFFBA1A1A)),
        );
      }
    }
  }

  InputDecoration _decoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
      prefixIcon: Icon(icon, color: const Color(0xFF94A3B8)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF006677), width: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthViewModel>().isLoading;

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
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: const Icon(Icons.public, size: 40, color: Color(0xFF006677)),
                ),
                const SizedBox(height: 32),
                Text(
                  _correoEnviado ? 'Ingresa el código' : '¿Olvidaste tu contraseña?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 16),
                Text(
                  _correoEnviado
                      ? 'Revisa tu correo e ingresa el código de 6 dígitos junto con tu nueva contraseña.'
                      : 'Ingresa tu correo electrónico y te enviaremos un código para restablecerla.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Color(0xFF64748B), height: 1.5),
                ),
                const SizedBox(height: 48),

                // Paso 1: correo
                TextFormField(
                  controller: _correoController,
                  enabled: !_correoEnviado, // ya no se puede editar tras enviar
                  keyboardType: TextInputType.emailAddress,
                  decoration: _decoration('tu@correo.com', Icons.email_outlined),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Ingresa tu correo';
                    if (!value.contains('@')) return 'Correo no válido';
                    return null;
                  },
                ),

                // Paso 2: código + nueva contraseña (aparece tras enviar el correo)
                if (_correoEnviado) ...[
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _tokenController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: _decoration('Código de 6 dígitos', Icons.pin_outlined),
                    validator: (value) => value == null || value.length != 6 ? 'Ingresa el código de 6 dígitos' : null,
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: _nuevaPasswordController,
                    obscureText: true,
                    decoration: _decoration('Nueva contraseña', Icons.lock_outline),
                    validator: (value) => value != null && value.length < 8 ? 'Mínimo 8 caracteres' : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _confirmarPasswordController,
                    obscureText: true,
                    decoration: _decoration('Confirmar nueva contraseña', Icons.lock_outline),
                    validator: (value) => value == null || value.isEmpty ? 'Confirma tu nueva contraseña' : null,
                  ),
                ],

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : (_correoEnviado ? _restablecer : _enviarCorreo),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006677),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            _correoEnviado ? 'Restablecer contraseña' : 'Enviar código',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),

                const SizedBox(height: 32),

                TextButton.icon(
                  onPressed: () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginView()));
                  },
                  icon: const Icon(Icons.arrow_back, size: 18, color: Color(0xFF64748B)),
                  label: const Text(
                    'Volver al inicio de sesión',
                    style: TextStyle(fontSize: 15, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                  ),
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