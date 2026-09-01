import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'login_view.dart';
import 'completarPerfil_view.dart'; // ajusta el nombre del archivo si es distinto

class RegistroView extends StatefulWidget {
  const RegistroView({Key? key}) : super(key: key);

  @override
  State<RegistroView> createState() => _RegistroViewState();
}

class _RegistroViewState extends State<RegistroView> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _password2Controller = TextEditingController();

  bool _mostrarConfirmar = false;

  @override
  void initState() {
    super.initState();
    // Muestra el campo "confirmar contraseña" en cuanto empieza a escribir la contraseña
    _passwordController.addListener(() {
      final debeMostrar = _passwordController.text.isNotEmpty;
      if (debeMostrar != _mostrarConfirmar) {
        setState(() => _mostrarConfirmar = debeMostrar);
      }
    });
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _correoController.dispose();
    _passwordController.dispose();
    _password2Controller.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final viewModel = context.read<AuthViewModel>();
      viewModel.clearError();

      final exito = await viewModel.registrar(
        correo: _correoController.text.trim(),
        password: _passwordController.text.trim(),
        nombre: _nombreController.text.trim(),
        apellido: _apellidoController.text.trim(),
      );

      if (!mounted) return;

      if (exito) {
        final usuarioId = viewModel.usuario?.id;
        // Va directo a completar perfil, llevando el id del usuario recién creado
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CompletarPerfilView(usuarioId: usuarioId!),
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

  InputDecoration _buildInputDecoration(String hintText, IconData icon) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFF76777D)),
      prefixIcon: Icon(icon, color: const Color(0xFF76777D)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFC6C6CD)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF00687A), width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthViewModel>().isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: Center(
        child: SingleChildScrollView(
          child: Stack(
            children: [
              Container(
                constraints: const BoxConstraints(maxWidth: 480),
                margin: const EdgeInsets.all(24.0),
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withOpacity(0.1),
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFC6C6CD).withOpacity(0.3)),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF4FF),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFC6C6CD).withOpacity(0.3)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.public, color: Color(0xFF00687A), size: 32),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Crea tu cuenta',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Color(0xFF000000)),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Únete a Talkia para conectar con el mundo.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Color(0xFF45464D)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),

                      // Nombre
                      const Text('Nombre', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF0B1C30))),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nombreController,
                        decoration: _buildInputDecoration('Ingresa tu nombre', Icons.person),
                        validator: (value) => value == null || value.isEmpty ? 'Ingresa tu nombre' : null,
                      ),
                      const SizedBox(height: 24),

                      // Apellido
                      const Text('Apellido', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF0B1C30))),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _apellidoController,
                        decoration: _buildInputDecoration('Ingresa tu apellido', Icons.person_outline),
                        validator: (value) => value == null || value.isEmpty ? 'Ingresa tu apellido' : null,
                      ),
                      const SizedBox(height: 24),

                      // Correo
                      const Text('Correo electrónico', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF0B1C30))),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _correoController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _buildInputDecoration('tu@correo.com', Icons.mail_outlined),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Ingresa tu correo';
                          if (!value.contains('@')) return 'Correo no válido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Contraseña
                      const Text('Contraseña', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF0B1C30))),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: _buildInputDecoration('••••••••', Icons.lock_outlined),
                        validator: (value) => value != null && value.length < 8 ? 'Mínimo 8 caracteres' : null,
                      ),

                      // Confirmar contraseña — aparece solo cuando ya se escribió algo en contraseña
                      AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        child: _mostrarConfirmar
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const SizedBox(height: 24),
                                  const Text('Confirmar contraseña',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF0B1C30))),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _password2Controller,
                                    obscureText: true,
                                    decoration: _buildInputDecoration('••••••••', Icons.lock_outlined),
                                    validator: (value) {
                                      if (!_mostrarConfirmar) return null;
                                      if (value == null || value.isEmpty) return 'Confirma tu contraseña';
                                      if (value != _passwordController.text) return 'Las contraseñas no coinciden';
                                      return null;
                                    },
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),

                      const SizedBox(height: 32),

                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00687A),
                            foregroundColor: Colors.white,
                            elevation: 1,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Registrarse', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          const Expanded(child: Divider(color: Color(0xFFC6C6CD))),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text('O',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF45464D).withOpacity(0.7),
                                    letterSpacing: 1.2)),
                          ),
                          const Expanded(child: Divider(color: Color(0xFFC6C6CD))),
                        ],
                      ),

                      const SizedBox(height: 16),

                      SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginView()));
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF000000),
                            side: BorderSide(color: const Color(0xFF76777D).withOpacity(0.3)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Iniciar sesión', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: -40,
                right: -40,
                child: Container(
                  height: 200,
                  width: 200,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF4CD7F6).withOpacity(0.2)),
                ),
              ),
              Positioned(
                bottom: -40,
                left: -40,
                child: Container(
                  height: 200,
                  width: 200,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFD3E4FE).withOpacity(0.4)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}