import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/Usuario_Model.dart'; 
import '../../viewmodels/admin_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';

class GestionUsuariosView extends StatefulWidget {
  const GestionUsuariosView({super.key});

  @override
  State<GestionUsuariosView> createState() => _GestionUsuariosViewState();
}

class _GestionUsuariosViewState extends State<GestionUsuariosView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminViewModel>().cargarUsuarios();
    });
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  // ─── BLOQUEAR / DESBLOQUEAR ─────────────────────────────
  Future<void> _toggleBloqueo(UsuarioModel usuario) async {
    final nuevoEstado = usuario.estado == "bloqueado" ? "activo" : "bloqueado";

    // Confirmación para bloquear (acción "destructiva")
    if (nuevoEstado == "bloqueado") {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Bloquear usuario"),
          content: Text("¿Bloquear a ${usuario.nombre}? No podrá iniciar sesión."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancelar"),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Bloquear"),
            ),
          ],
        ),
      );
      if (confirmar != true || !mounted) return;
    }

    final adminVM = context.read<AdminViewModel>();
    final ok = await adminVM.cambiarEstado(
      usuarioId: usuario.id!,
      estado: nuevoEstado,
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nuevoEstado == "bloqueado"
                ? "${usuario.nombre} bloqueado"
                : "${usuario.nombre} desbloqueado",
          ),
        ),
      );
    } else {
      _mostrarError(adminVM.errorMessage ?? "No se pudo cambiar el estado");
    }
  }

  // ─── HACER / QUITAR ADMIN ───────────────────────────────
  Future<void> _toggleAdmin(UsuarioModel usuario) async {
    final nuevoRol = usuario.rol == "admin" ? "usuario" : "admin";

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(nuevoRol == "admin" ? "Hacer admin" : "Quitar admin"),
        content: Text(
          nuevoRol == "admin"
              ? "¿Dar permisos de administrador a ${usuario.nombre}?"
              : "¿Quitar los permisos de administrador a ${usuario.nombre}?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancelar"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Confirmar"),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    final adminVM = context.read<AdminViewModel>();
    final ok = await adminVM.cambiarRol(
      usuarioId: usuario.id!,
      rol: nuevoRol,
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nuevoRol == "admin"
                ? "${usuario.nombre} ahora es admin"
                : "${usuario.nombre} ya no es admin",
          ),
        ),
      );
    } else {
      _mostrarError(adminVM.errorMessage ?? "No se pudo cambiar el rol");
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminVM = context.watch<AdminViewModel>();
    final miId = context.read<AuthViewModel>().usuario?.id;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "Gestión de usuarios",
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
      body: adminVM.cargando
          ? const Center(child: CircularProgressIndicator())
          : adminVM.usuarios.isEmpty
              ? Center(
                  child: Text(
                    adminVM.errorMessage ?? "No hay usuarios registrados",
                    style: const TextStyle(color: Color(0xFF52525B)),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => context.read<AdminViewModel>().cargarUsuarios(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: adminVM.usuarios.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final usuario = adminVM.usuarios[index];
                      final esYo = usuario.id == miId;
                      final esAdmin = usuario.rol == "admin";
                      final estaBloqueado = usuario.estado == "bloqueado";

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Avatar con inicial
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: const Color(0xFF4F46E5)
                                  .withValues(alpha: 0.12),
                              child: Text(
                                usuario.nombre.isNotEmpty
                                    ? usuario.nombre[0].toUpperCase()
                                    : "?",
                                style: const TextStyle(
                                  color: Color(0xFF4F46E5),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Datos + badges
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          esYo
                                              ? "${usuario.nombre} (tú)"
                                              : usuario.username.isNotEmpty
                                                  ? usuario.username
                                                  : usuario.nombre,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF1A1A1C),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      if (esAdmin)
                                        const Icon(
                                          Icons.shield,
                                          size: 16,
                                          color: Color(0xFF4F46E5),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    usuario.correo,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: const Color(0xFF52525B)
                                          .withValues(alpha: 0.8),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      _Badge(
                                        texto: esAdmin ? "Admin" : "Usuario",
                                        color: esAdmin
                                            ? const Color(0xFF4F46E5)
                                            : const Color(0xFF52525B),
                                      ),
                                      const SizedBox(width: 6),
                                      _Badge(
                                        texto: estaBloqueado
                                            ? "Bloqueado"
                                            : "Activo",
                                        color: estaBloqueado
                                            ? Colors.red
                                            : Colors.green,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Botones de acción (ocultos para ti mismo
                            // para no bloquearte ni quitarte tu propio rol)
                            if (!esYo) ...[
                              IconButton(
                                tooltip: estaBloqueado
                                    ? "Desbloquear"
                                    : "Bloquear",
                                icon: Icon(
                                  estaBloqueado
                                      ? Icons.lock_open
                                      : Icons.block,
                                  color: estaBloqueado
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                onPressed: () => _toggleBloqueo(usuario),
                              ),
                              IconButton(
                                tooltip: esAdmin ? "Quitar admin" : "Hacer admin",
                                icon: Icon(
                                  esAdmin
                                      ? Icons.shield_outlined
                                      : Icons.shield,
                                  color: const Color(0xFF4F46E5),
                                ),
                                onPressed: () => _toggleAdmin(usuario),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String texto;
  final Color color;

  const _Badge({required this.texto, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}