import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../../data/services/Chat_Service.dart';
import '../../data/services/Contacto_Service.dart';
import '../../data/models/Conversacion_Model.dart';
import '../../data/models/Contacto_Model.dart';
import 'ChatView.dart';
import 'CrearGrupoView.dart';
import 'MisContactosView.dart';
import '../perfil/Configuracion.dart';

class ListaConversacionesView extends StatefulWidget {
  const ListaConversacionesView({super.key});

  @override
  State<ListaConversacionesView> createState() =>
      _ListaConversacionesViewState();
}

class _ListaConversacionesViewState extends State<ListaConversacionesView> {
  List<ConversacionModel> _conversaciones = [];
  bool _cargando = true;
  final TextEditingController _busquedaController = TextEditingController();

  // ─────────────── PALETA ───────────────
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _scaffoldBg => _isDark ? const Color(0xFF121316) : const Color(0xFFF8F9FA);
  Color get _accent => _isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4F46E5);
  Color get _onSurface => _isDark ? const Color(0xFFE6E1E9) : const Color(0xFF1A1A1C);
  Color get _onSurfaceVariant => _isDark ? const Color(0xFFA1A1AA) : const Color(0xFF52525B);
  Color get _cardBg => _isDark ? const Color(0xFF1B1D24) : Colors.white;
  Color get _fieldFill => _isDark ? const Color(0xFF1B1D24) : Colors.white;
  Color get _fabBg => _isDark ? const Color(0xFF4B4A66) : const Color.fromARGB(255, 122, 121, 167);
  Color get _botonPrimario => _isDark ? const Color(0xFF4338CA) : const Color(0xFF4F46E5);
  // ──────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _cargarConversaciones();
    _busquedaController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
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

  Future<void> _cargarConversaciones() async {
    final auth = context.read<AuthViewModel>();
    if (auth.usuario?.id == null) return;

    try {
      final conversaciones = await ChatService.obtenerConversaciones(
        auth.usuario!.id!,
      );
      if (!mounted) return;
      setState(() {
        _conversaciones = conversaciones;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  List<ConversacionModel> get _grupos =>
      _conversaciones.where((c) => c.esGrupo).toList();

  List<ConversacionModel> get _chatsIndividuales =>
      _conversaciones.where((c) => !c.esGrupo).toList();

  List<ConversacionModel> get _gruposFiltrados {
    final q = _busquedaController.text.trim().toLowerCase();
    if (q.isEmpty) return _grupos;
    return _grupos
        .where((g) => (g.nombre ?? "").toLowerCase().contains(q))
        .toList();
  }

  List<ConversacionModel> get _chatsFiltrados {
    final q = _busquedaController.text.trim().toLowerCase();
    if (q.isEmpty) return _chatsIndividuales;
    return _chatsIndividuales
        .where((c) => _nombreContacto(c).toLowerCase().contains(q))
        .toList();
  }

  String _nombreContacto(ConversacionModel conv) {
    if (conv.nombreMostrar != null && conv.nombreMostrar!.isNotEmpty) {
      return conv.nombreMostrar!;
    }
    final nombre = conv.contacto?['nombre'] ?? '';
    final apellido = conv.contacto?['apellido'] ?? '';
    final completo = "$nombre $apellido".trim();
    return completo.isEmpty ? "Usuario" : completo;
  }

  String _subtitulo(ConversacionModel conv) {
    final auth = context.read<AuthViewModel>();
    final miIdioma = auth.usuario?.idiomaPredeterminado ?? "Español";

    final tieneMensaje =
        conv.ultimoMensaje != null && conv.ultimoMensaje!.isNotEmpty;
    if (!tieneMensaje) {
      return conv.esGrupo
          ? "${conv.cantidadMiembros ?? conv.participantes.length} miembros"
          : "Idioma: ${conv.contacto?['idioma'] ?? 'Español'}";
    }
    return conv.ultimoMensajeTraducido?[miIdioma] ?? conv.ultimoMensaje!;
  }

  Future<void> _abrirChatIndividual(ConversacionModel conv) async {
    final contactoId = conv.contacto?['id'] as String?;
    if (contactoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("El contacto ya no está disponible")),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatView(
          conversacionId: conv.id,
          otroUsuarioId: contactoId,
          otroUsuarioNombre: _nombreContacto(conv),
        ),
      ),
    );
    _cargarConversaciones();
  }

  Future<void> _abrirChatGrupo(ConversacionModel grupo) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatView(
          conversacionId: grupo.id,
          titulo: grupo.nombre ?? "Grupo",
          esGrupo: true,
        ),
      ),
    );
    _cargarConversaciones();
  }

  Future<void> _crearGrupo() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CrearGrupoView()),
    );
    _cargarConversaciones();
  }

  Future<void> _config() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ConfigView()),
    );
  }

  Future<void> _agregarContacto() async {
    final auth = context.read<AuthViewModel>();
    if (auth.usuario?.id == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: _scaffoldBg,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => _AgregarContactoSheet(
        duenoId: auth.usuario!.id!,
        onContactoAgregado: () {
          Navigator.pop(sheetContext);
          _cargarConversaciones();
        },
      ),
    );
  }

  Future<void> _abrirMisContactos() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MisContactosView()),
    );
    _cargarConversaciones();
  }

  @override
  Widget build(BuildContext context) {
    final gruposAMostrar = _gruposFiltrados;
    final chatsAMostrar = _chatsFiltrados;
    final hayResultados = gruposAMostrar.isNotEmpty || chatsAMostrar.isNotEmpty;
    final buscando = _busquedaController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: _scaffoldBg,
      appBar: AppBar(
        title: Text(
          'Chats',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _onSurface,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: _scaffoldBg,
        foregroundColor: _onSurface,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: _onSurface),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) {
              if (value == 'agregar_contacto') {
                _agregarContacto();
              } else if (value == 'crear_grupo') {
                _crearGrupo();
              } else if (value == 'config') {
                _config();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'agregar_contacto',
                child: Row(
                  children: [
                    Icon(Icons.person_add, size: 20, color: _accent),
                    const SizedBox(width: 12),
                    const Text("Agregar Contacto"),
                  ],
                ),
              ),
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
              PopupMenuItem(
                value: 'config',
                child: Row(
                  children: [
                    Icon(
                      Icons.settings_outlined,
                      size: 20,
                      color: _onSurfaceVariant,
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
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirMisContactos,
        backgroundColor: _fabBg,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.contacts),
      ),
      body: _cargando
          ? Center(
              child: CircularProgressIndicator(color: _accent),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: TextField(
                    controller: _busquedaController,
                    decoration: InputDecoration(
                      hintText: "Buscar conversaciones o grupos...",
                      prefixIcon: Icon(
                        Icons.search,
                        color: _onSurfaceVariant,
                      ),
                      suffixIcon: buscando
                          ? IconButton(
                              icon: Icon(
                                Icons.close,
                                color: _onSurfaceVariant,
                              ),
                              onPressed: () {
                                _busquedaController.clear();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: _fieldFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: _accent,
                    onRefresh: _cargarConversaciones,
                    child: (_conversaciones.isEmpty)
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.6,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.chat_bubble_outline,
                                      size: 64,
                                      color: _onSurfaceVariant.withValues(alpha: 0.3),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      "Aún no tienes conversaciones",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: _onSurfaceVariant,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Usa ⋮ para agregar un contacto\no el botón Contactos abajo",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: _onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : (buscando && !hayResultados)
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height: 200,
                                child: Center(
                                  child: Text(
                                    "Sin resultados",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: _onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                            children: [
                              if (gruposAMostrar.isNotEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 8,
                                    bottom: 8,
                                    left: 4,
                                  ),
                                  child: Text(
                                    "Grupos",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: _onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                ...gruposAMostrar.map(
                                  (grupo) => _buildConversacionTile(
                                    titulo: grupo.nombre ?? "Grupo",
                                    subtitulo: _subtitulo(grupo),
                                    esGrupo: true,
                                    fotoUrl: '',
                                    onTap: () => _abrirChatGrupo(grupo),
                                  ),
                                ),
                              ],
                              if (chatsAMostrar.isNotEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 8,
                                    bottom: 8,
                                    left: 4,
                                  ),
                                  child: Text(
                                    "Conversaciones",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: _onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                ...chatsAMostrar.map(
                                  (conv) => _buildConversacionTile(
                                    titulo: _nombreContacto(conv),
                                    subtitulo: _subtitulo(conv),
                                    esGrupo: false,
                                    fotoUrl: _completarUrl(
                                      conv.contacto?['foto_url'] ?? '',
                                    ),
                                    onTap: () => _abrirChatIndividual(conv),
                                  ),
                                ),
                              ],
                            ],
                          ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildConversacionTile({
    required String titulo,
    required String subtitulo,
    required bool esGrupo,
    required String fotoUrl,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _accent.withValues(alpha: 0.1),
          radius: 24,
          child: ClipOval(
            child: esGrupo
                ? Icon(
                    Icons.group,
                    color: _accent,
                    size: 22,
                  )
                : fotoUrl.isNotEmpty
                ? Image.network(
                    fotoUrl,
                    fit: BoxFit.cover,
                    width: 48,
                    height: 48,
                    errorBuilder: (_, __, ___) => _avatarPersona(),
                  )
                : _avatarPersona(),
          ),
        ),
        title: Text(
          titulo,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _onSurface,
          ),
        ),
        subtitle: Text(
          subtitulo,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 14, color: _onSurfaceVariant),
        ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Icon(
            Icons.chat_bubble_outline,
            size: 20,
            color: _accent,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _avatarPersona() {
    return Center(
      child: Icon(
        Icons.person,
        color: _accent,
        size: 22,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  BOTTOM SHEET: AGREGAR CONTACTO CON BÚSQUEDA
// ═══════════════════════════════════════════════════════════
class _AgregarContactoSheet extends StatefulWidget {
  final String duenoId;
  final VoidCallback onContactoAgregado;

  const _AgregarContactoSheet({
    required this.duenoId,
    required this.onContactoAgregado,
  });

  @override
  State<_AgregarContactoSheet> createState() => _AgregarContactoSheetState();
}

class _AgregarContactoSheetState extends State<_AgregarContactoSheet> {
  final TextEditingController _busquedaController = TextEditingController();
  List<UsuarioContacto> _resultados = [];
  bool _cargando = true;
  bool _buscando = false;

  // ─────────────── PALETA ───────────────
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _onSurface => _isDark ? const Color(0xFFE6E1E9) : const Color(0xFF1A1A1C);
  Color get _onSurfaceVariant => _isDark ? const Color(0xFFA1A1AA) : const Color(0xFF52525B);
  Color get _accent => _isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4F46E5);
  Color get _cardBg => _isDark ? const Color(0xFF1B1D24) : Colors.white;
  Color get _fieldFill => _isDark ? const Color(0xFF1B1D24) : Colors.white;
  Color get _handle => _isDark ? const Color(0xFF3A3D4A) : Colors.grey.shade300;
  Color get _botonPrimario => _isDark ? const Color(0xFF4338CA) : const Color(0xFF4F46E5);
  // ──────────────────────────────────────

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

  @override
  void initState() {
    super.initState();
    _buscarUsuarios("");
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _buscarUsuarios(String query) async {
    setState(() => _buscando = true);
    try {
      final resultados = await ContactoService.buscarUsuario(
        duenoId: widget.duenoId,
        query: query,
      );
      if (!mounted) return;
      setState(() {
        _resultados = resultados;
        _cargando = false;
        _buscando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _buscando = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Error al buscar usuarios")));
    }
  }

  Future<void> _mostrarModalNombrePersonalizado(UsuarioContacto usuario) async {
    debugPrint("🟢 _mostrarModalNombrePersonalizado() llamado para ${usuario.username}");

    final nombreController = TextEditingController(text: usuario.nombre);

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
              "${usuario.nombre} ${usuario.apellido}".trim(),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              "@${usuario.username}",
              style: TextStyle(color: _onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nombreController,
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
            onPressed: () async {
              final nombre = nombreController.text.trim();
              if (nombre.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text("Escribe un nombre")),
                );
                return;
              }
              Navigator.pop(dialogContext, true);
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      try {
        await ContactoService.agregarContacto(
          duenoId: widget.duenoId,
          contactoId: usuario.id,
          nombrePersonalizado: nombreController.text.trim(),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "${nombreController.text.trim()} agregado a tus contactos",
            ),
            backgroundColor: _botonPrimario,
          ),
        );
        widget.onContactoAgregado();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: _handle,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              "Agregar contacto",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _onSurface,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _busquedaController,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: (value) {
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (_busquedaController.text == value) {
                    _buscarUsuarios(value);
                  }
                });
              },
              decoration: InputDecoration(
                hintText: "Buscar por @username, nombre o correo...",
                prefixIcon: Icon(Icons.search, color: _onSurfaceVariant),
                suffixIcon: _buscando
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
                filled: true,
                fillColor: _fieldFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _resultados.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        "No se encontraron usuarios.\nPrueba con otro @username o nombre.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _onSurfaceVariant),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: _resultados.length,
                    itemBuilder: (context, i) {
                      final u = _resultados[i];
                      final fotoUrl = _completarUrl(u.fotoUrl ?? '');
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: _cardBg,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            // 👈 ÚNICO onTap: cualquier parte del row abre el modal
                            onTap: () {
                              debugPrint("🔥 TAP EN ITEM: @${u.username}");
                              _mostrarModalNombrePersonalizado(u);
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor:
                                        _accent.withValues(alpha: 0.1),
                                    radius: 24,
                                    child: ClipOval(
                                      child: fotoUrl.isNotEmpty
                                          ? Image.network(
                                              fotoUrl,
                                              fit: BoxFit.cover,
                                              width: 48,
                                              height: 48,
                                              errorBuilder: (_, __, ___) =>
                                                  _avatarPersona(),
                                            )
                                          : _avatarPersona(),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "${u.nombre} ${u.apellido}".trim(),
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: _onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "@${u.username} · ${u.idiomaPredeterminado}",
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: _onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // 👈 Tocar el ícono también abre el modal
                                  GestureDetector(
                                    onTap: () {
                                      debugPrint("🔥 TAP EN ICONO: @${u.username}");
                                      _mostrarModalNombrePersonalizado(u);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: _accent
                                            .withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: Icon(
                                        Icons.person_add_alt,
                                        size: 20,
                                        color: _accent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _avatarPersona() {
    return Center(
      child: Icon(
        Icons.person,
        color: _accent,
        size: 22,
      ),
    );
  }
}