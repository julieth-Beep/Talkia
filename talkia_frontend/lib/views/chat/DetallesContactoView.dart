import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../data/services/VideoCall_Service.dart';
import 'DiccionarioView.dart';

class DetallesContactoView extends StatefulWidget {
  final String nombre;
  final String? username;
  final String? telefono;
  final String? fotoUrl;
  final bool esGrupo;
  final int? cantidadMiembros;
  final String? conversacionId;
  final String? otroUsuarioId;

  const DetallesContactoView({
    super.key,
    required this.nombre,
    this.username,
    this.telefono,
    this.fotoUrl,
    this.esGrupo = false,
    this.cantidadMiembros,
    this.conversacionId,
    this.otroUsuarioId,
  });

  @override
  State<DetallesContactoView> createState() => _DetallesContactoViewState();
}

class _DetallesContactoViewState extends State<DetallesContactoView> {
  // ─── Colores del design system ───
  static const Color _primary = Color(0xFF2A14B4);
  static const Color _surfaceContainerLow = Color(0xFFEFF4FF);
  static const Color _onSurface = Color(0xFF0B1C30);
  static const Color _onSurfaceVariant = Color(0xFF464554);
  static const Color _error = Color(0xFFBA1A1A);

  bool _conectandoLlamada = false;

  String _completarUrl(String url) {
    if (url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    if (url.startsWith('/')) {
      if (kIsWeb) return "http://localhost:3000$url";
      if (Platform.isAndroid) return "http://10.0.2.2:3000$url";
      return "http://localhost:3000$url";
    }
    return url;
  }

  //  VIDEOLLAMADA
  Future<void> _videollamada() async {
    if (_conectandoLlamada) return;
    if (widget.conversacionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No hay conversación activa")),
      );
      return;
    }

    final user = context.read<AuthViewModel>().usuario;
    if (user == null) return;

    setState(() => _conectandoLlamada = true);

    try {
      await VideoCallService.iniciarLlamada(
        conversacionId: widget.conversacionId!,
        nombreUsuario: user.nombre,
        correoUsuario: user.correo,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No se pudo iniciar la videollamada: $e")),
      );
    } finally {
      if (mounted) setState(() => _conectandoLlamada = false);
    }
  }

  //  ABRIR DICCIONARIO
  void _abrirDiccionario() {
    if (widget.otroUsuarioId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Este contacto no está disponible")),
      );
      return;
    }

    final auth = context.read<AuthViewModel>();
    if (auth.usuario?.id == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiccionarioView(
          usuarioId: auth.usuario!.id!,
          contactoId: widget.otroUsuarioId!,
          contactoNombre: widget.nombre,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        foregroundColor: _onSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFF1A1A1C)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) {
              if (value == 'agregar_contacto') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Ajustes — próximamente"),
                    duration: Duration(seconds: 2),
                  ),
                );
              } else if (value == 'crear_grupo') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Ajustes — próximamente"),
                    duration: Duration(seconds: 2),
                  ),
                );
              } else if (value == 'ajustes') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Ajustes — próximamente"),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'agregar_contacto',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20, color: Color(0xFF4F46E5)),
                    SizedBox(width: 12),
                    Text("Editar"),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'crear_grupo',
                child: Row(
                  children: [
                    Icon(Icons.group_add, size: 20, color: Color(0xFF4F46E5)),
                    SizedBox(width: 12),
                    Text("Crear grupo"),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'ajustes',
                child: Row(
                  children: [
                    Icon(
                      Icons.settings_outlined,
                      size: 20,
                      color: Color(0xFF52525B),
                    ),
                    SizedBox(width: 12),
                    Text("Ajustes"),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // ─── Foto de perfil ───
            _buildAvatar(),

            const SizedBox(height: 16),

            // ─── Nombre ───
            Text(
              widget.nombre,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: _onSurface,
                letterSpacing: -0.5,
              ),
            ),

            const SizedBox(height: 6),

            // ─── Teléfono o username ───
            if (widget.telefono != null && widget.telefono!.isNotEmpty)
              Text(
                widget.telefono!,
                style: const TextStyle(
                  fontSize: 16,
                  color: _onSurfaceVariant,
                ),
              )
            else if (widget.username != null && widget.username!.isNotEmpty)
              Text(
                '@${widget.username}',
                style: const TextStyle(
                  fontSize: 16,
                  color: _onSurfaceVariant,
                ),
              )
            else if (widget.esGrupo && widget.cantidadMiembros != null)
              Text(
                '${widget.cantidadMiembros} miembros',
                style: const TextStyle(
                  fontSize: 16,
                  color: _onSurfaceVariant,
                ),
              ),

            const SizedBox(height: 24),

            // ═══════════════════════════════════════════════════════
            //  BOTONES DE ACCIÓN
            // ═══════════════════════════════════════════════════════
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ─── VIDEO ───
                _buildAccionCircular(
                  icono: Icons.videocam_outlined,
                  texto: 'Video',
                  onTap: _conectandoLlamada ? null : _videollamada,
                  cargando: _conectandoLlamada,
                ),
                const SizedBox(width: 20),

                // ─── DICCIONARIO ───
                _buildAccionCircular(
                  icono: Icons.menu_book_outlined,
                  texto: 'Diccionario',
                  onTap: widget.esGrupo ? null : _abrirDiccionario,
                ),
                const SizedBox(width: 20),

                // ─── BUSCAR ───
                _buildAccionCircular(
                  icono: Icons.search,
                  texto: 'Buscar',
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 32),

            // ─── Lista de opciones ───
            _buildOpcionLista(
              icono: Icons.notifications_none,
              texto: 'Notificaciones',
              onTap: () {},
            ),
            _buildOpcionLista(
              icono: Icons.image_outlined,
              texto: 'Visibilidad de archivos multimedia',
              onTap: () {},
            ),
            _buildOpcionLista(
              icono: Icons.lock_outline,
              texto: 'Cifrado',
              subtitulo:
                  'Los mensajes y las llamadas están cifrados de extremo a extremo. Toca para verificarlo.',
              onTap: () {},
            ),
            _buildOpcionLista(
              icono: Icons.timer_outlined,
              texto: 'Mensajes temporales',
              subtitulo: 'Desactivados',
              onTap: () {},
            ),

            _buildOpcionConSwitch(
              icono: Icons.lock_person_outlined,
              texto: 'Restringir chat',
              subtitulo: 'Restringe y oculta este chat en este dispositivo.',
              valor: false,
              onChanged: (v) {},
            ),

            _buildOpcionLista(
              icono: Icons.shield_outlined,
              texto: 'Privacidad avanzada del chat',
              subtitulo: 'Desactivada',
              onTap: () {},
            ),

            const SizedBox(height: 16),

            // ─── Sección "No hay grupos en común" ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.esGrupo ? 'Participantes' : 'No hay grupos en común',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _onSurfaceVariant,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            _buildOpcionConIconoVerde(
              icono: Icons.group_add,
              texto: widget.esGrupo
                  ? 'Añadir participantes'
                  : 'Crear grupo con ${widget.nombre}',
              onTap: () {},
            ),
            _buildOpcionConIconoVerde(
              icono: Icons.group_add_outlined,
              texto: 'Añadir a grupos',
              subtitulo:
                  'Añade este contacto a los grupos a los que perteneces.',
              onTap: () {},
            ),

            const SizedBox(height: 8),

            _buildOpcionLista(
              icono: Icons.favorite_border,
              texto: 'Añadir a Favoritos',
              onTap: () {},
            ),
            _buildOpcionLista(
              icono: Icons.playlist_add,
              texto: 'Añadir a la lista',
              onTap: () {},
            ),

            const SizedBox(height: 16),

            _buildOpcionDestructiva(
              icono: Icons.remove_circle_outline,
              texto: 'Vaciar chat',
              onTap: () {},
            ),
            _buildOpcionDestructiva(
              icono: Icons.block,
              texto: 'Bloquear a ${widget.nombre}',
              onTap: () {},
            ),
            _buildOpcionDestructiva(
              icono: Icons.thumb_down_outlined,
              texto: 'Reportar a ${widget.nombre}',
              onTap: () {},
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  AVATAR
  // ═══════════════════════════════════════════════════════
  Widget _buildAvatar() {
    final fotoUrl = _completarUrl(widget.fotoUrl ?? '');

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _primary.withValues(alpha: 0.15),
      ),
      child: ClipOval(
        child: fotoUrl.isNotEmpty
            ? Image.network(
                fotoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _avatarFallback(),
              )
            : _avatarFallback(),
      ),
    );
  }

  Widget _avatarFallback() {
    return Center(
      child: widget.esGrupo
          ? const Icon(Icons.group, size: 70, color: _primary)
          : Text(
              widget.nombre.isNotEmpty ? widget.nombre[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.w700,
                color: _primary,
              ),
            ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  BOTONES DE ACCIÓN CIRCULARES
  // ═══════════════════════════════════════════════════════
  Widget _buildAccionCircular({
    required IconData icono,
    required String texto,
    VoidCallback? onTap,
    bool cargando = false,
  }) {
    final deshabilitado = onTap == null;

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Opacity(
            opacity: deshabilitado ? 0.5 : 1.0,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _surfaceContainerLow,
                shape: BoxShape.circle,
              ),
              child: cargando
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _primary,
                      ),
                    )
                  : Icon(icono, color: _primary, size: 24),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          texto,
          style: const TextStyle(
            fontSize: 12,
            color: _onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  //  OPCIÓN DE LISTA
  // ═══════════════════════════════════════════════════════
  Widget _buildOpcionLista({
    required IconData icono,
    required String texto,
    String? subtitulo,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            Icon(icono, color: _onSurfaceVariant, size: 26),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    texto,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _onSurface,
                    ),
                  ),
                  if (subtitulo != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitulo,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  OPCIÓN CON SWITCH
  // ═══════════════════════════════════════════════════════
  Widget _buildOpcionConSwitch({
    required IconData icono,
    required String texto,
    String? subtitulo,
    required bool valor,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        children: [
          Icon(icono, color: _onSurfaceVariant, size: 26),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  texto,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _onSurface,
                  ),
                ),
                if (subtitulo != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitulo,
                    style: const TextStyle(
                      fontSize: 13,
                      color: _onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: valor,
            onChanged: onChanged,
            activeColor: _primary,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  OPCIÓN CON ÍCONO VERDE
  // ═══════════════════════════════════════════════════════
  Widget _buildOpcionConIconoVerde({
    required IconData icono,
    required String texto,
    String? subtitulo,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
              child: Icon(icono, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    texto,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _onSurface,
                    ),
                  ),
                  if (subtitulo != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitulo,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  OPCIÓN DESTRUCTIVA (ROJA)
  // ═══════════════════════════════════════════════════════
  Widget _buildOpcionDestructiva({
    required IconData icono,
    required String texto,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            Icon(icono, color: _error, size: 26),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                texto,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}