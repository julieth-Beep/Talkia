import 'package:flutter/material.dart';
import 'CrearAdminView.dart';
import 'GestionUsuariosView.dart';

class AdminHomeView extends StatelessWidget {
  const AdminHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "Panel de Administración",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1C),
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: const Color(0xFFF8F9FA).withValues(alpha: 0.8),
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "¿Qué quieres gestionar hoy?",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1C),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24),

              _OpcionMenu(
                icono: Icons.manage_accounts_outlined,
                titulo: "Gestionar usuarios",
                descripcion: "Lista completa, bloquear cuentas y asignar roles",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GestionUsuariosView()),
                ),
              ),
              const SizedBox(height: 16),

              _OpcionMenu(
                icono: Icons.admin_panel_settings_outlined,
                titulo: "Crear administrador",
                descripcion: "Registra una nueva cuenta con permisos de admin",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CrearAdminView()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpcionMenu extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String descripcion;
  final VoidCallback onTap;

  const _OpcionMenu({
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icono, size: 28, color: const Color(0xFF4F46E5)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1C),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      descripcion,
                      style: TextStyle(
                        fontSize: 13,
                        color: const Color(0xFF52525B).withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF52525B)),
            ],
          ),
        ),
      ),
    );
  }
}