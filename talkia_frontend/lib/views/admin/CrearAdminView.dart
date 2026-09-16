import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/admin_viewmodel.dart';

class CrearAdminView extends StatefulWidget {
  const CrearAdminView({super.key});

  @override
  State<CrearAdminView> createState() => _CrearAdminViewState();
}

class _CrearAdminViewState extends State<CrearAdminView> {
  final _formKey = GlobalKey<FormState>();
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  bool _ocultarPassword = true;

  @override
  void dispose() {
    _correoController.dispose();
    _passwordController.dispose();
    _nombreController.dispose();
    _apellidoController.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;

    final adminVM = context.read<AdminViewModel>();
    final ok = await adminVM.crearAdmin(
      correo: _correoController.text.trim(),
      password: _passwordController.text.trim(),
      nombre: _nombreController.text.trim(),
      apellido: _apellidoController.text.trim(),
    );

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Administrador creado con éxito ✅")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(adminVM.errorMessage ?? "Error al crear el admin")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminVM = context.watch<AdminViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "Crear administrador",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1C),
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: const Color(0xFFF8F9FA).withValues(alpha: 0.8),
        elevation: 0,
        foregroundColor: const Color(0xFF1A1A1C),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: _decoracion("Nombre", Icons.person_outline),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? "El nombre es obligatorio" : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _apellidoController,
                decoration: _decoracion("Apellido", Icons.person_outline),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? "El apellido es obligatorio" : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _correoController,
                keyboardType: TextInputType.emailAddress,
                decoration: _decoracion("Correo", Icons.email_outlined),
                validator: (v) =>
                    (v == null || !v.contains("@")) ? "Ingresa un correo válido" : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _passwordController,
                obscureText: _ocultarPassword,
                decoration: _decoracion("Contraseña (mín. 8 caracteres)", Icons.lock_outline)
                    .copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _ocultarPassword ? Icons.visibility_off : Icons.visibility,
                      color: const Color(0xFF52525B),
                    ),
                    onPressed: () => setState(() => _ocultarPassword = !_ocultarPassword),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.length < 8) ? "Mínimo 8 caracteres" : null,
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: adminVM.cargando ? null : _enviar,
                  child: adminVM.cargando
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "Crear administrador",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _decoracion(String label, IconData icono) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF52525B)),
      prefixIcon: Icon(icono, color: const Color(0xFF52525B)),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
      ),
    );
  }
}