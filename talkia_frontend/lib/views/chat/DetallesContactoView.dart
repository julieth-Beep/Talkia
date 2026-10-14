import 'dart:io';
import 'dart:ui'; // 👈 para ImageFilter (glassmorphism)
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../../data/services/VideoCall_Service.dart';
import '../../data/services/Contacto_Service.dart';
import '../../data/services/Chat_Service.dart';
import '../../data/models/Contacto_Model.dart';
import 'DiccionarioView.dart';
import 'CrearGrupoView.dart';
import 'VisibilidadArchivosView.dart';
import 'ChatView.dart';

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
  // ─────────────── PALETA ───────────────
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _primary =>
      _isDark ? const Color(0xFFBFC3FF) : const Color(0xFF2A14B4);
  Color get _surfaceContainerLow =>
      _isDark ? const Color(0xFF2A2D3A) : const Color(0xFFEFF4FF);
  Color get _onSurface =>
      _isDark ? const Color(0xFFE6E1E9) : const Color(0xFF0B1C30);
  Color get _onSurfaceVariant =>
      _isDark ? const Color(0xFFC6C4D0) : const Color(0xFF464554);
  Color get _error =>
      _isDark ? const Color(0xFFFFB4AB) : const Color(0xFFBA1A1A);
  Color get _scaffoldBg =>
      _isDark ? const Color(0xFF121316) : const Color(0xFFF8F9FA);
  Color get _appBarIcon =>
      _isDark ? const Color(0xFFE6E1E9) : const Color(0xFF1A1A1C);
  Color get _accent =>
      _isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4F46E5);
  Color get _verde => _isDark
      ? const Color(0xFF2A14B4)
      : const Color.fromARGB(255, 87, 75, 163);
  Color get _botonPrimario =>
      _isDark ? const Color(0xFF4338CA) : const Color(0xFF4F46E5);
  // ──────────────────────────────────────

  bool _conectandoLlamada = false;
  bool _esContactoAgregado = false;
  bool _cargandoEstadoContacto = true;
  ContactoModel? _contactoActual;

  bool _cargandoGrupos = true;
  List<Map<String, dynamic>> _gruposEnComun = [];

  @override
  void initState() {
    super.initState();
    _verificarSiEsContacto();
    _cargarGruposEnComun();
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

  // ═══════════════════════════════════════════════════════
  //  TOAST GLASSMORPHISM
  // ═══════════════════════════════════════════════════════
  void _mostrarGlassToast({
    required BuildContext context,
    required String mensaje,
    required IconData icono,
    Color? colorIcono,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 40,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: _GlassToast(
            mensaje: mensaje,
            icono: icono,
            colorIcono: colorIcono ?? _accent,
            onDismiss: () => entry.remove(),
          ),
        ),
      ),
    );

    overlay.insert(entry);
  }

  // ═══════════════════════════════════════════════════════
  //  GRUPOS EN COMÚN
  // ═══════════════════════════════════════════════════════
  Future<void> _cargarGruposEnComun() async {
    if (widget.esGrupo || widget.otroUsuarioId == null) {
      setState(() => _cargandoGrupos = false);
      return;
    }

    final auth = context.read<AuthViewModel>();
    if (auth.usuario?.id == null) {
      setState(() => _cargandoGrupos = false);
      return;
    }

    try {
      final todas = await ChatService.obtenerConversaciones(auth.usuario!.id!);
      final grupos = todas.where((c) => c.esGrupo).toList();

      final List<Map<String, dynamic>> resultado = [];

      for (final grupo in grupos) {
        try {
          final participantes =
              await ChatService.obtenerParticipantes(grupo.id);
          final estaElContacto = participantes.any(
            (p) => p['id'] == widget.otroUsuarioId,
          );
          if (estaElContacto) {
            resultado.add({
              'id': grupo.id,
              'nombre': grupo.nombre ?? 'Grupo',
              'foto_url': null,
              'cantidadMiembros': participantes.length,
            });
          }
        } catch (_) {}
      }

      if (!mounted) return;
      setState(() {
        _gruposEnComun = resultado;
        _cargandoGrupos = false;
      });
    } catch (e) {
      debugPrint("Error cargando grupos en común: $e");
      if (!mounted) return;
      setState(() {
        _gruposEnComun = [];
        _cargandoGrupos = false;
      });
    }
  }

  // ═══════════════════════════════════════════════════════
  //  VERIFICAR SI EL USUARIO YA ES CONTACTO
  // ═══════════════════════════════════════════════════════
  Future<void> _verificarSiEsContacto() async {
    if (widget.esGrupo || widget.otroUsuarioId == null) {
      setState(() {
        _cargandoEstadoContacto = false;
        _esContactoAgregado = true;
      });
      return;
    }

    final auth = context.read<AuthViewModel>();
    if (auth.usuario?.id == null) {
      setState(() => _cargandoEstadoContacto = false);
      return;
    }

    try {
      final contactos = await ContactoService.listarContactos(
        auth.usuario!.id!,
      );
      ContactoModel? encontrado;
      for (final c in contactos) {
        if (c.usuario?.id == widget.otroUsuarioId) {
          encontrado = c;
          break;
        }
      }
      if (!mounted) return;
      setState(() {
        _contactoActual = encontrado;
        _esContactoAgregado = encontrado != null;
        _cargandoEstadoContacto = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _esContactoAgregado = false;
        _cargandoEstadoContacto = false;
      });
    }
  }

  // ═══════════════════════════════════════════════════════
  //  VIDEOLLAMADA
  // ═══════════════════════════════════════════════════════
  Future<void> _videollamada() async {
    if (_conectandoLlamada) return;
    if (widget.conversacionId == null) {
      _mostrarGlassToast(
        context: context,
        mensaje: "No hay conversación activa",
        icono: Icons.error_rounded,
        colorIcono: _error,
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
      _mostrarGlassToast(
        context: context,
        mensaje: "No se pudo iniciar la videollamada",
        icono: Icons.error_rounded,
        colorIcono: _error,
      );
    } finally {
      if (mounted) setState(() => _conectandoLlamada = false);
    }
  }

  // ═══════════════════════════════════════════════════════
  //  DICCIONARIO
  // ═══════════════════════════════════════════════════════
  void _abrirDiccionario() {
    if (widget.otroUsuarioId == null) {
      _mostrarGlassToast(
        context: context,
        mensaje: "Este contacto no está disponible",
        icono: Icons.error_rounded,
        colorIcono: _error,
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

  // ═══════════════════════════════════════════════════════
  //  EDITAR NOMBRE
  // ═══════════════════════════════════════════════════════
  Future<void> _editarNombre() async {
    if (_contactoActual?.id == null) {
      _mostrarGlassToast(
        context: context,
        mensaje: "Este contacto no está disponible",
        icono: Icons.error_rounded,
        colorIcono: _error,
      );
      return;
    }

    final controller = TextEditingController(text: widget.nombre);
    final nuevo = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Renombrar contacto"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "Ej: Mi amor, Mamá, Jefe...",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _botonPrimario,
              foregroundColor: Colors.white,
            ),
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text("Guardar"),
          ),
        ],
      ),
    );

    if (nuevo == null || nuevo.isEmpty || nuevo == widget.nombre) return;

    try {
      await ContactoService.actualizarNombre(
        contactoId: _contactoActual!.id!,
        nuevoNombre: nuevo,
      );
      if (!mounted) return;
      _mostrarGlassToast(
        context: context,
        mensaje: "Nombre actualizado a \"$nuevo\"",
        icono: Icons.check_circle_rounded,
        colorIcono: _accent,
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _mostrarGlassToast(
        context: context,
        mensaje: "Error al actualizar",
        icono: Icons.error_rounded,
        colorIcono: _error,
      );
    }
  }

  // ═══════════════════════════════════════════════════════
  //  AGREGAR CONTACTO
  // ═══════════════════════════════════════════════════════
  Future<void> _agregarContacto() async {
    if (widget.otroUsuarioId == null) return;

    final auth = context.read<AuthViewModel>();
    if (auth.usuario?.id == null) return;

    final controller = TextEditingController(text: widget.nombre);
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("¿Cómo quieres llamarlo?"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.nombre,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (widget.username != null) ...[
              const SizedBox(height: 2),
              Text(
                "@${widget.username}",
                style: TextStyle(color: _onSurfaceVariant, fontSize: 13),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: "Ej: Mi amor, Mamá, Jefe...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Este nombre solo lo verás tú.",
              style: TextStyle(color: _onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _botonPrimario,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(dialogContext, true);
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    try {
      final nuevo = await ContactoService.agregarContacto(
        duenoId: auth.usuario!.id!,
        contactoId: widget.otroUsuarioId!,
        nombrePersonalizado: controller.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _contactoActual = nuevo;
        _esContactoAgregado = true;
      });
      _mostrarGlassToast(
        context: context,
        mensaje: "${controller.text.trim()} agregado a tus contactos",
        icono: Icons.person_add_rounded,
        colorIcono: _verde,
      );
    } catch (e) {
      if (!mounted) return;
      _mostrarGlassToast(
        context: context,
        mensaje: "Error al agregar contacto",
        icono: Icons.error_rounded,
        colorIcono: _error,
      );
    }
  }

  // ═══════════════════════════════════════════════════════
  //  CREAR GRUPO
  // ═══════════════════════════════════════════════════════
  Future<void> _crearGrupo() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CrearGrupoView(contactoPreseleccionadoId: widget.otroUsuarioId),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  VACIAR CHAT
  // ═══════════════════════════════════════════════════════
  Future<void> _vaciarChat() async {
    if (widget.conversacionId == null) return;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Vaciar chat"),
        content: const Text("¿Borrar todos los mensajes de esta conversación?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Vaciar"),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    final chatVM = context.read<ChatViewModel>();
    final ok = await chatVM.vaciarConversacion(widget.conversacionId!);

    if (!mounted) return;
    _mostrarGlassToast(
      context: context,
      mensaje: ok ? "Chat vaciado" : "No se pudo vaciar el chat",
      icono: ok ? Icons.check_circle_rounded : Icons.error_rounded,
      colorIcono: ok ? _accent : _error,
    );
  }

  // ═══════════════════════════════════════════════════════
  //  BLOQUEAR / REPORTAR
  // ═══════════════════════════════════════════════════════
  Future<void> _bloquearContacto() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Bloquear a ${widget.nombre}"),
        content: const Text(
          "No podrás recibir mensajes ni llamadas de este contacto.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Bloquear"),
          ),
        ],
      ),
    );
    if (confirmado != true) return;
    if (!mounted) return;
    _mostrarGlassToast(
      context: context,
      mensaje: "Contacto bloqueado (próximamente)",
      icono: Icons.block_rounded,
      colorIcono: _error,
    );
  }

  Future<void> _reportarContacto() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Reportar a ${widget.nombre}"),
        content: const Text("Tu reporte es anónimo. ¿Quieres continuar?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Reportar"),
          ),
        ],
      ),
    );
    if (confirmado != true) return;
    if (!mounted) return;
    _mostrarGlassToast(
      context: context,
      mensaje: "Reporte enviado (próximamente)",
      icono: Icons.thumb_down_rounded,
      colorIcono: _error,
    );
  }

  // ═══════════════════════════════════════════════════════
  //  BUSCAR
  // ═══════════════════════════════════════════════════════
  Future<void> _buscarEnChat() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Buscar en el chat"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "Escribe una palabra...",
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cerrar"),
          ),
        ],
      ),
    );
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
              if (value == 'editar') {
                _editarNombre();
              } else if (value == 'crear_grupo') {
                _crearGrupo();
              } else if (value == 'agregar_contacto') {
                _agregarContacto();
              }
            },
            itemBuilder: (context) => [
              if (_esContactoAgregado && !widget.esGrupo)
                PopupMenuItem(
                  value: 'editar',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20, color: _accent),
                      const SizedBox(width: 12),
                      const Text("Editar nombre"),
                    ],
                  ),
                ),
              if (!widget.esGrupo)
                PopupMenuItem(
                  value: 'crear_grupo',
                  child: Row(
                    children: [
                      Icon(Icons.group_add, size: 20, color: _accent),
                      const SizedBox(width: 12),
                      const Text("Crear grupo"),
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
            _buildAvatar(),
            const SizedBox(height: 16),
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
            if (widget.telefono != null && widget.telefono!.isNotEmpty)
              Text(
                widget.telefono!,
                style: TextStyle(fontSize: 16, color: _onSurfaceVariant),
              )
            else if (widget.username != null && widget.username!.isNotEmpty)
              Text(
                '@${widget.username}',
                style: TextStyle(fontSize: 16, color: _onSurfaceVariant),
              )
            else if (widget.esGrupo && widget.cantidadMiembros != null)
              Text(
                '${widget.cantidadMiembros} miembros',
                style: TextStyle(fontSize: 16, color: _onSurfaceVariant),
              ),

            const SizedBox(height: 24),

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
                  icono: Icons.menu_book_outlined,
                  texto: 'Diccionario',
                  onTap: widget.esGrupo ? null : _abrirDiccionario,
                ),
                const SizedBox(width: 20),
                _buildAccionCircular(
                  icono: Icons.search,
                  texto: 'Buscar',
                  onTap: _buscarEnChat,
                ),
              ],
            ),

            const SizedBox(height: 32),

            _buildOpcionLista(
              icono: Icons.notifications_none,
              texto: 'Notificaciones',
              onTap: () {},
            ),
            _buildOpcionLista(
              icono: Icons.image_outlined,
              texto: 'Visibilidad de archivos multimedia',
              onTap: () {
                if (widget.conversacionId == null) {
                  _mostrarGlassToast(
                    context: context,
                    mensaje: "No hay conversación activa",
                    icono: Icons.error_rounded,
                    colorIcono: _error,
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VisibilidadArchivosView(
                      conversacionId: widget.conversacionId!,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // ═══════════════════════════════════════════════════════
            //  GRUPOS EN COMÚN
            // ═══════════════════════════════════════════════════════
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _gruposEnComun.isEmpty
                      ? 'No hay grupos en común'
                      : 'GRUPOS EN COMÚN',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _onSurfaceVariant,
                    letterSpacing: _gruposEnComun.isEmpty ? 0 : 0.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            if (_cargandoGrupos)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else
              ..._gruposEnComun.map((g) => _buildGrupoEnComunTile(g)),

            const SizedBox(height: 8),

            if (!widget.esGrupo &&
                !_cargandoEstadoContacto &&
                !_esContactoAgregado)
              _buildOpcionConIconoVerde(
                icono: Icons.person_add,
                texto: 'Agregar contacto',
                subtitulo:
                    'Guárdalo en tus contactos con un nombre personalizado',
                onTap: _agregarContacto,
              ),

            _buildOpcionConIconoVerde(
              icono: Icons.group_add,
              texto: widget.esGrupo
                  ? 'Añadir participantes'
                  : 'Crear grupo con ${widget.nombre}',
              onTap: _crearGrupo,
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

            const SizedBox(height: 16),

            _buildOpcionDestructiva(
              icono: Icons.remove_circle_outline,
              texto: 'Vaciar chat',
              onTap: _vaciarChat,
            ),
            _buildOpcionDestructiva(
              icono: Icons.block,
              texto: 'Bloquear a ${widget.nombre}',
              onTap: _bloquearContacto,
            ),
            _buildOpcionDestructiva(
              icono: Icons.thumb_down_outlined,
              texto: 'Reportar a ${widget.nombre}',
              onTap: _reportarContacto,
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  TILE DE GRUPO EN COMÚN
  // ═══════════════════════════════════════════════════════
  Widget _buildGrupoEnComunTile(Map<String, dynamic> grupo) {
    final nombre = grupo['nombre'] ?? 'Grupo';
    final cantidad = grupo['cantidadMiembros'] ?? 0;
    final fotoUrl = _completarUrl(grupo['foto_url'] ?? '');

    return InkWell(
      onTap: () {
        if (grupo['id'] == null) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatView(
              conversacionId: grupo['id'],
              titulo: nombre,
              esGrupo: true,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: fotoUrl.isNotEmpty
                    ? Image.network(
                        fotoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Icon(Icons.group, color: _accent, size: 22),
                      )
                    : Icon(Icons.group, color: _accent, size: 22),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "$cantidad miembro${cantidad == 1 ? '' : 's'}",
                    style: TextStyle(fontSize: 12, color: _onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: _onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }

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
          ? Icon(Icons.group, size: 70, color: _primary)
          : Text(
              widget.nombre.isNotEmpty ? widget.nombre[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.w700,
                color: _primary,
              ),
            ),
    );
  }

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
              decoration: BoxDecoration(color: _verde, shape: BoxShape.circle),
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

// ═══════════════════════════════════════════════════════════
//  TOAST GLASSMORPHISM
// ═══════════════════════════════════════════════════════════
class _GlassToast extends StatefulWidget {
  final String mensaje;
  final IconData icono;
  final Color colorIcono;
  final VoidCallback onDismiss;

  const _GlassToast({
    required this.mensaje,
    required this.icono,
    required this.colorIcono,
    required this.onDismiss,
  });

  @override
  State<_GlassToast> createState() => _GlassToastState();
}

class _GlassToastState extends State<_GlassToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      _controller.reverse().then((_) {
        if (mounted) widget.onDismiss();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor = isDark
        ? Colors.black.withValues(alpha: 0.55)
        : Colors.white.withValues(alpha: 0.65);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.white.withValues(alpha: 0.55);
    final textColor = isDark ? Colors.white : const Color(0xFF0B1C30);

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.10),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: widget.colorIcono.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.icono,
                      color: widget.colorIcono,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.mensaje,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}