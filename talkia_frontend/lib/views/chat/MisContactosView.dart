import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../../data/services/Contacto_Service.dart';
import '../../data/models/Contacto_Model.dart';
import 'ChatView.dart';
import 'CrearGrupoView.dart';

class MisContactosView extends StatefulWidget {
  const MisContactosView({super.key});

  @override
  State<MisContactosView> createState() => _MisContactosViewState();
}

class _MisContactosViewState extends State<MisContactosView> {
  List<ContactoModel> _contactos = [];
  List<ContactoModel> _contactosFiltrados = [];
  bool _cargando = true;
  final TextEditingController _busquedaController = TextEditingController();

  // ─────────────── PALETA ───────────────
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _scaffoldBg => _isDark ? const Color(0xFF121316) : const Color(0xFFF8F9FA);
  Color get _accent => _isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4F46E5);
  Color get _onSurface => _isDark ? const Color(0xFFE6E1E9) : const Color(0xFF1A1A1C);
  Color get _onSurfaceVariant => _isDark ? const Color(0xFFA1A1AA) : const Color(0xFF52525B);
  Color get _onSurfaceTertiary => _isDark ? const Color(0xFF71717A) : const Color(0xFF9CA3AF);
  Color get _cardBg => _isDark ? const Color(0xFF1B1D24) : Colors.white;
  Color get _fieldFill => _isDark ? const Color(0xFF1B1D24) : Colors.white;
  Color get _accionBg => _isDark ? const Color(0xFF4A3A6E) : const Color.fromARGB(255, 214, 187, 250);
  Color get _danger => _isDark ? const Color(0xFFFFB4AB) : Colors.red;
  // ──────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _cargarContactos();
    _busquedaController.addListener(_filtrar);
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

  Future<void> _cargarContactos() async {
    final auth = context.read<AuthViewModel>();
    if (auth.usuario?.id == null) return;

    try {
      final contactos =
          await ContactoService.listarContactos(auth.usuario!.id!);
      if (!mounted) return;
      setState(() {
        _contactos = contactos;
        _contactosFiltrados = contactos;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al cargar contactos: $e")),
      );
    }
  }

  void _filtrar() {
    final q = _busquedaController.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _contactosFiltrados = _contactos);
      return;
    }
    setState(() {
      _contactosFiltrados = _contactos.where((c) {
        final nombre = c.nombrePersonalizado.toLowerCase();
        final username = (c.usuario?.username ?? "").toLowerCase();
        return nombre.contains(q) || username.contains(q);
      }).toList();
    });
  }

  Future<void> _abrirChatConContacto(ContactoModel contacto) async {
    if (contacto.usuario == null) return;

    final auth = context.read<AuthViewModel>();
    final chatVM = context.read<ChatViewModel>();

    final conversacion = await chatVM.obtenerOCrearConversacion(
      uid1: auth.usuario!.id!,
      uid2: contacto.usuario!.id,
    );

    if (!mounted || conversacion == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatView(
          conversacionId: conversacion.id,
          otroUsuarioId: contacto.usuario!.id,
          otroUsuarioNombre: contacto.nombrePersonalizado,
        ),
      ),
    );
    _cargarContactos();
  }

  Future<void> _eliminarContacto(ContactoModel contacto) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Eliminar contacto"),
        content: Text(
          "¿Eliminar a ${contacto.nombrePersonalizado} de tus contactos?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: _danger),
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      try {
        await ContactoService.eliminarContacto(contacto.id);
        _cargarContactos();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Contacto eliminado")),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  Future<void> _crearNuevoGrupo() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CrearGrupoView()),
    );
    _cargarContactos();
  }

  Future<void> _agregarNuevoContacto() async {
    final auth = context.read<AuthViewModel>();
    if (auth.usuario?.id == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: _scaffoldBg,
      isScrollControlled: true,
      useSafeArea: true, // 👈 AÑADIDO: evita que el tap del nombre se filtre a la lista de atrás
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => _AgregarContactoSheet(
        duenoId: auth.usuario!.id!,
        onContactoAgregado: () {
          Navigator.pop(sheetContext);
          _cargarContactos();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _scaffoldBg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contactos',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _onSurface,
              ),
            ),
            if (!_cargando)
              Text(
                '${_contactos.length} contacto${_contactos.length == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: 12,
                  color: _onSurfaceVariant,
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
        ),
        backgroundColor: _scaffoldBg,
        foregroundColor: _onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _busquedaController,
              decoration: InputDecoration(
                hintText: "Buscar por nombre o @username...",
                prefixIcon: Icon(Icons.search, color: _onSurfaceVariant),
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
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    color: _accent,
                    onRefresh: _cargarContactos,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      children: [
                        _buildAccionRapida(
                          icon: Icons.group_add,
                          color: _accionBg,
                          texto: "Nuevo grupo",
                          onTap: _crearNuevoGrupo,
                        ),
                        _buildAccionRapida(
                          icon: Icons.person_add,
                          color: _accionBg,
                          texto: "Nuevo contacto",
                          onTap: _agregarNuevoContacto,
                        ),
                        if (_contactosFiltrados.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(
                                top: 16, bottom: 8, left: 4),
                            child: Text(
                              "Contactos",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _onSurfaceVariant,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                        if (_contactosFiltrados.isEmpty && !_cargando)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 60),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.person_outline,
                                    size: 64,
                                    color: _onSurfaceVariant,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "No hay contactos aún",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: _onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Usa \"Nuevo contacto\" para agregar uno",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: _onSurfaceTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ..._contactosFiltrados.map((c) {
                            final username = c.usuario?.username ?? "";
                            final idioma =
                                c.usuario?.idiomaPredeterminado ?? "Español";
                            final fotoUrl =
                                _completarUrl(c.usuario?.fotoUrl ?? '');

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: _cardBg,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
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
                                title: Text(
                                  c.nombrePersonalizado,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: _onSurface,
                                  ),
                                ),
                                subtitle: Text(
                                  "@$username · $idioma",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _onSurfaceVariant,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: _onSurfaceVariant,
                                    size: 20,
                                  ),
                                  onPressed: () => _eliminarContacto(c),
                                ),
                                onTap: () => _abrirChatConContacto(c),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _avatarPersona() {
    return Icon(
      Icons.person,
      color: _accent,
      size: 22,
    );
  }

  Widget _buildAccionRapida({
    required IconData icon,
    required Color color,
    required String texto,
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
        leading: Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        title: Text(
          texto,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _onSurface,
          ),
        ),
        onTap: onTap,
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al buscar usuarios")),
      );
    }
  }

  Future<void> _mostrarModalNombrePersonalizado(
      UsuarioContacto usuario) async {
    debugPrint(
        "🟢 _mostrarModalNombrePersonalizado() llamado para ${usuario.username}");

    final nombreController = TextEditingController(text: usuario.nombre);

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
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
                prefixIcon:
                    Icon(Icons.search, color: _onSurfaceVariant),
                suffixIcon: _buscando
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child:
                              CircularProgressIndicator(strokeWidth: 2),
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
                            horizontal: 16, vertical: 8),
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
                                // 👈 ÚNICO onTap para todo el row
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
                                        backgroundColor: _accent
                                            .withValues(alpha: 0.1),
                                        radius: 24,
                                        child: ClipOval(
                                          child: fotoUrl.isNotEmpty
                                              ? Image.network(
                                                  fotoUrl,
                                                  fit: BoxFit.cover,
                                                  width: 48,
                                                  height: 48,
                                                  errorBuilder:
                                                      (_, __, ___) =>
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
                                              "${u.nombre} ${u.apellido}"
                                                  .trim(),
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
                                      // 👈 Ícono con onTap propio
                                      GestureDetector(
                                        onTap: () {
                                          debugPrint(
                                              "🔥 TAP EN ICONO: @${u.username}");
                                          _mostrarModalNombrePersonalizado(u);
                                        },
                                        child: Container(
                                          padding:
                                              const EdgeInsets.all(8),
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
    return Icon(
      Icons.person,
      color: _accent,
      size: 22,
    );
  }
}