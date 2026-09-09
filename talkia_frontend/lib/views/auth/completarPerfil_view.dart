import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../home/InicioIngreso.dart'; // <-- IMPORTAR LA VISTA

class CompletarPerfilView extends StatefulWidget {
  final String usuarioId;
  const CompletarPerfilView({super.key, required this.usuarioId});

  @override
  State<CompletarPerfilView> createState() => _CompletarPerfilViewState();
}

class _CompletarPerfilViewState extends State<CompletarPerfilView> {
  final _usernameController = TextEditingController();
  String? _idiomaSeleccionado;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  void _guardarPerfil() async {
    final viewModel = context.read<AuthViewModel>();
    final exito = await viewModel.completarPerfil(
      id: widget.usuarioId,
      username: _usernameController.text.trim(),
      idiomaPredeterminado: _idiomaSeleccionado,
    );

    if (!mounted) return;

    if (exito) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Perfil guardado!'),
          backgroundColor: Color(0xFF006677),
        ),
      );
      // REDIRIGIR A INICIO
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const InicioIngresoView()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.errorMessage ?? 'Error al guardar'),
          backgroundColor: const Color(0xFFBA1A1A),
        ),
      );
    }
  }

  void _omitir() {
    // REDIRIGIR A INICIO SIN GUARDAR
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const InicioIngresoView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthViewModel>().isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Completa tu perfil',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Cuéntanos un poco más sobre ti (opcional).',
                style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 40),

              // Foto de Perfil
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.person, size: 60, color: Color(0xFF94A3B8)),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF006677),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                        onPressed: () {
                          // TODO: abrir galería y subir la foto
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Username
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Nombre de usuario',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  hintText: '@tu_usuario (opcional)',
                  hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                  prefixIcon: Icon(Icons.alternate_email, color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide(color: Color(0xFF006677), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Idioma
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Idioma predeterminado',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _idiomaSeleccionado,
                hint: const Text('Español (por defecto)'),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.language_outlined, color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide(color: Color(0xFF006677), width: 2),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'Español', child: Text('Español')),
                  DropdownMenuItem(value: 'Inglés', child: Text('Inglés')),
                  DropdownMenuItem(value: 'Francés', child: Text('Francés')),
                  DropdownMenuItem(value: 'Italiano', child: Text('Italiano')),
                  DropdownMenuItem(value: 'Mandarín', child: Text('Mandarín')),
                  DropdownMenuItem(value: 'Alemán', child: Text('Alemán')),
                  DropdownMenuItem(value: 'Portugués', child: Text('Portugués')),
                  DropdownMenuItem(value: 'Ruso', child: Text('Ruso')),
                  DropdownMenuItem(value: 'Japonés', child: Text('Japonés')),
                  DropdownMenuItem(value: 'Coreano', child: Text('Coreano')),
                ],
                onChanged: (value) {
                  setState(() => _idiomaSeleccionado = value);
                },
              ),
              const SizedBox(height: 48),

              // Botón Guardar
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _guardarPerfil,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006677),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Guardar y continuar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Botón Omitir
              TextButton(
                onPressed: isLoading ? null : _omitir,
                child: const Text(
                  'Omitir por ahora',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}