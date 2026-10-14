import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../data/services/Chat_Service.dart';
import '../../data/services/VideoCall_Service.dart';

class DetallesGrupoView extends StatefulWidget {
  final String nombre;
  final String? fotoUrl;
  final String? conversacionId;

  const DetallesGrupoView({
    super.key,
    required this.nombre,
    this.fotoUrl,
    this.conversacionId,
  });

  @override
  State<DetallesGrupoView> createState() => _DetallesGrupoViewState();
}

class _DetallesGrupoViewState extends State<DetallesGrupoView> {
  // ─────────────── PALETA (claro = valores originales, oscuro = equivalentes) ───────────────
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _primary => _isDark ? const Color(0xFFBFC3FF) : const Color(0xFF2A14B4);
  Color get _surfaceContainerLow => _isDark ? const Color(0xFF2A2D3A) : const Color(0xFFEFF4FF);
  Color get _onSurface => _isDark ? const Color(0xFFE6E1E9) : const Color(0xFF0B1C30);
  Color get _onSurfaceVariant => _isDark ? const Color(0xFFC6C4D0) : const Color(0xFF464554);
  Color get _error => _isDark ? const Color(0xFFFFB4AB) : const Color(0xFFBA1A1A);
  Color get _scaffoldBg => _isDark ? const Color(0xFF121316) : const Color(0xFFF8F9FA);
  Color get _appBarIcon => _isDark ? const Color(0xFFE6E1E9) : const Color(0xFF1A1A1C);
  Color get _accent => _isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4F46E5);
  Color get _onSurfaceVariantSoft => _isDark ? const Color(0xFFA1A1AA) : const Color(0xFF52525B);
  Color get _verde => _isDark ? const Color(0xFF34D399) : const Color(0xFF10B981);
  // ───────────────────────────────────────────────────────────────────────────────────────────

  bool _conectandoLlamada = false;
  List<Map<String, dynamic>> _participantes = [];
  bool _cargandoParticipantes = true;

  @override
  void initState() {
    super.initState();
    if (widget.conversacionId != null) {
      _cargarParticipantes();
    } else {
      _cargandoParticipantes = false;
    }
  }

  Future<void> _cargarParticipantes() async {
    try {
      final participantes = await ChatService.obtenerParticipantes(
        widget.conversacionId!,
      );
      if (!mounted) return;
      setState(() {
        _participantes = participantes;
        _cargandoParticipantes = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargandoParticipantes = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al cargar participantes: $e")),
      );
    }
  }

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

  Future<void> _videollamada() async {
    if (_conectandoLlamada) return;
    if (widget.conversacionId == null) return;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _scaffoldBg,
      appBar: AppBar(
        backgroundColor: _scaffoldBg,
        foregroundColor: _onSurface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: _appBarIcon),
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
              PopupMenuItem(
                value: 'agregar_contacto',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20, color: _accent),
                    const SizedBox(width: 12),
                    const Text("Editar Grupo"),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'ajustes',
                child: Row(
                  children: [
                    Icon(
                      Icons.settings_outlined,
                       size: 20,
                      color: _onSurfaceVariantSoft,
                    ),
                    const SizedBox(width: 12),
                    const Text("Ajustes"),
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

            // ─── Avatar del grupo ───
            _buildAvatar(),

            const SizedBox(height: 16),

            // ─── Nombre del grupo ───
            Text(
              widget.nombre,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: _onSurface,
                letterSpacing: -0.5,
              ),
            ),

            const SizedBox(height: 6),

            // ─── Cantidad de participantes ───
            Text(
              '${_participantes.length} participantes',
              style: TextStyle(fontSize: 16, color: _onSurfaceVariant),
            ),

            const SizedBox(height: 24),

            // ─── Botones ───
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAccionCircular(
                  icono: Icons.videocam_outlined,
                  texto: 'Video',
                  onTap: _conectandoLlamada ? null : _videollamada,
                  cargando: _conectandoLlamada,
                ),
                const SizedBox(width: 20),
                _buildAccionCircular(
                  icono: Icons.person_add_outlined,
                  texto: 'Añadir',
                  onTap: () {},
                ),
                const SizedBox(width: 20),
                _buildAccionCircular(
                  icono: Icons.search,
                  texto: 'Buscar',
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 32),

            // ─── Opciones del grupo ───
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
                  'Los mensajes y las llamadas están cifrados de extremo a extremo.',
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

            // ═══════════════════════════════════════════════════════
            //  PARTICIPANTES
            // ═══════════════════════════════════════════════════════
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Text(
                      'Participantes',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!_cargandoParticipantes)
                      Text(
                        '${_participantes.length}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _primary,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            if (_cargandoParticipantes)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: CircularProgressIndicator(color: _primary),
                ),
              )
            else
              ..._participantes.map((p) => _buildParticipanteTile(p)),

            const SizedBox(height: 16),

            // ─── Añadir participantes ───
            _buildOpcionConIconoVerde(
              icono: Icons.group_add,
              texto: 'Añadir participantes',
              onTap: () {},
            ),
            _buildOpcionConIconoVerde(
              icono: Icons.exit_to_app,
              texto: 'Salir del grupo',
              onTap: () {},
            ),

            const SizedBox(height: 16),

            _buildOpcionDestructiva(
              icono: Icons.remove_circle_outline,
              texto: 'Vaciar chat',
              onTap: () {},
            ),
            _buildOpcionDestructiva(
              icono: Icons.thumb_down_outlined,
              texto: 'Reportar grupo',
              onTap: () {},
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ─── Avatar del grupo ───
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
    return Center(child: Icon(Icons.group, size: 56, color: _primary));
  }

  // ─── Tile de participante ───
  Widget _buildParticipanteTile(Map<String, dynamic> participante) {
    final nombre = participante['nombre'] ?? '';
    final apellido = participante['apellido'] ?? '';
    final username = participante['username'] ?? '';
    final fotoUrl = _completarUrl(participante['foto_url'] ?? '');
    final esCreador = participante['esCreador'] == true;

    final nombreCompleto = '$nombre $apellido'.trim();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: fotoUrl.isNotEmpty
                  ? Image.network(
                      fotoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _avatarPersona(),
                    )
                  : _avatarPersona(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        nombreCompleto.isEmpty ? 'Usuario' : nombreCompleto,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: _onSurface,
                        ),
                      ),
                    ),
                    if (esCreador) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Admin',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (username.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    '@$username',
                    style: TextStyle(
                      fontSize: 13,
                      color: _onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarPersona() {
    return Icon(Icons.person, color: _primary, size: 22);
  }

  // ─── Botón circular ───
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
                  ? Padding(
                      padding: const EdgeInsets.all(16),
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
          style: TextStyle(
            fontSize: 12,
            color: _onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ─── Opción de lista ───
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _onSurface,
                    ),
                  ),
                  if (subtitulo != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitulo,
                      style: TextStyle(
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

  // ─── Opción con switch ───
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _onSurface,
                  ),
                ),
                if (subtitulo != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitulo,
                    style: TextStyle(
                      fontSize: 13,
                      color: _onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(value: valor, onChanged: onChanged, activeColor: _primary),
        ],
      ),
    );
  }

  // ─── Opción con ícono verde ───
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
              decoration: BoxDecoration(
                color: _verde,
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _onSurface,
                    ),
                  ),
                  if (subtitulo != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitulo,
                      style: TextStyle(
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

  // ─── Opción destructiva ───
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
                style: TextStyle(
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