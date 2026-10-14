import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../../data/services/Contacto_Service.dart';
import '../../data/models/Contacto_Model.dart';
import 'ChatView.dart';

class CrearGrupoView extends StatefulWidget {
  final String? contactoPreseleccionadoId; // 👈 nuevo: contacto que viene preseleccionado

  const CrearGrupoView({
    super.key,
    this.contactoPreseleccionadoId,
  });

  @override
  State<CrearGrupoView> createState() => _CrearGrupoViewState();
}

class _CrearGrupoViewState extends State<CrearGrupoView> {
  final _nombreController = TextEditingController();
  final Set<String> _seleccionados = {};
  List<UsuarioContacto> _personas = [];
  List<UsuarioContacto> _filtradas = [];
  bool _cargando = true;
  bool _creando = false;
  final TextEditingController _busquedaController = TextEditingController();

  // ─────────────── PALETA (claro = valores originales, oscuro = equivalentes) ───────────────
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _scaffoldBg => _isDark ? const Color(0xFF121316) : const Color(0xFFF8F9FA);
  Color get _appBarFg => _isDark ? const Color(0xFFE6E1E9) : const Color(0xFF1A1A1C);
  Color get _accent => _isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4F46E5);
  Color get _onSurface => _isDark ? const Color(0xFFE6E1E9) : const Color(0xFF1A1A1C);
  Color get _onSurfaceVariant => _isDark ? const Color(0xFFA1A1AA) : const Color(0xFF52525B);
  Color get _onSurfaceTertiary => _isDark ? const Color(0xFF71717A) : const Color(0xFF9CA3AF);
  Color get _cardBg => _isDark ? const Color(0xFF1B1D24) : Colors.white;
  Color get _fieldFillGrey => _isDark ? const Color(0xFF1B1D24) : Colors.grey.shade100;
  Color get _fieldFillWhite => _isDark ? const Color(0xFF1B1D24) : Colors.white;
  Color get _selectedBg => _isDark
      ? const Color(0xFF4F46E5).withValues(alpha: 0.20)
      : const Color(0xFF4F46E5).withValues(alpha: 0.08);
  // ==========================================================================================

  @override
  void initState() {
    super.initState();
    _cargarPersonas();
    _busquedaController.addListener(_filtrar);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _busquedaController.dispose();
    super.dispose();
  }

  // ═══════════════ HELPER: COMPLETAR URL ═══════════════
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

  // Carga SOLO contactos + personas con las que ya tengo conversación
  Future<void> _cargarPersonas() async {
    final auth = context.read<AuthViewModel>();
    if (auth.usuario?.id == null) return;

    try {
      final personas =
          await ContactoService.personasDisponibles(auth.usuario!.id!);
      if (!mounted) return;
      setState(() {
        _personas = personas;
        _filtradas = personas;

        // 👈 Preseleccionar el contacto si vino desde DetallesContactoView
        if (widget.contactoPreseleccionadoId != null) {
          final existe = personas.any(
            (p) => p.id == widget.contactoPreseleccionadoId,
          );
          if (existe) {
            _seleccionados.add(widget.contactoPreseleccionadoId!);
          }
        }

        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al cargar personas: $e")),
      );
    }
  }

  void _filtrar() {
    final q = _busquedaController.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _filtradas = _personas);
      return;
    }
    setState(() {
      _filtradas = _personas.where((u) {
        return u.nombreMostrar.toLowerCase().contains(q) ||
            u.username.toLowerCase().contains(q);
      }).toList();
    });
  }

  Future<void> _crearGrupo() async {
    final nombre = _nombreController.text.trim();

    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Escribe un nombre para el grupo")),
      );
      return;
    }
    if (_seleccionados.length < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Selecciona al menos 1 miembro (tú eres el 2º)")),
      );
      return;
    }

    final auth = context.read<AuthViewModel>();
    final chatVM = context.read<ChatViewModel>();

    setState(() => _creando = true);

    final grupo = await chatVM.crearGrupo(
      creadorId: auth.usuario!.id!,
      nombre: nombre,
      participantes: [auth.usuario!.id!, ..._seleccionados],
    );

    if (!mounted) return;

    if (grupo == null) {
      setState(() => _creando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(chatVM.errorMessage ?? "Error creando el grupo")),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ChatView(
          conversacionId: grupo.id,
          titulo: grupo.nombre,
          esGrupo: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _scaffoldBg,
      appBar: AppBar(
        title: Text(
          'Nuevo grupo',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _appBarFg,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: _scaffoldBg.withValues(alpha: 0.8),
        foregroundColor: _appBarFg,
        elevation: 0,
        centerTitle: false,
      ),
      body: _cargando
          ? Center(
              child: CircularProgressIndicator(color: _accent))
          : Column(
              children: [
                // Nombre del grupo
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    controller: _nombreController,
                    style: TextStyle(color: _onSurface),
                    cursorColor: _accent,
                    decoration: InputDecoration(
                      hintText: "Nombre del grupo",
                      hintStyle: TextStyle(color: _onSurfaceVariant),
                      filled: true,
                      fillColor: _fieldFillGrey,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Icon(Icons.group, color: _accent),
                    ),
                  ),
                ),
                // Contador de miembros
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Miembros: ${_seleccionados.length + 1} (contándote)",
                      style: TextStyle(fontSize: 13, color: _onSurfaceVariant),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Buscador
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _busquedaController,
                    style: TextStyle(color: _onSurface),
                    cursorColor: _accent,
                    decoration: InputDecoration(
                      hintText: "Buscar en mis contactos...",
                      hintStyle: TextStyle(color: _onSurfaceVariant),
                      prefixIcon: Icon(Icons.search, color: _onSurfaceVariant),
                      filled: true,
                      fillColor: _fieldFillWhite,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Lista de personas
                Expanded(
                  child: _filtradas.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 64,
                                  color: _onSurfaceVariant
                                      .withValues(alpha: 0.4),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "No tienes contactos ni conversaciones aún",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: _onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Agrega contactos o inicia un chat primero",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _onSurfaceTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          itemCount: _filtradas.length,
                          itemBuilder: (context, index) {
                            final u = _filtradas[index];
                            final seleccionado =
                                _seleccionados.contains(u.id);
                            final fotoUrl = _completarUrl(u.fotoUrl ?? '');

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: seleccionado ? _selectedBg : _cardBg,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withValues(alpha: _isDark ? 0.25 : 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: CheckboxListTile(
                                value: seleccionado,
                                onChanged: (v) {
                                  setState(() {
                                    if (v == true) {
                                      _seleccionados.add(u.id);
                                    } else {
                                      _seleccionados.remove(u.id);
                                    }
                                  });
                                },
                                title: Text(
                                  u.nombreMostrar,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: _onSurface,
                                  ),
                                ),
                                subtitle: Text(
                                  "@${u.username} · ${u.idiomaPredeterminado}",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _onSurfaceVariant,
                                  ),
                                ),
                                secondary: CircleAvatar(
                                  backgroundColor: _accent
                                      .withValues(alpha: 0.1),
                                  child: ClipOval(
                                    child: fotoUrl.isNotEmpty
                                        ? Image.network(
                                            fotoUrl,
                                            fit: BoxFit.cover,
                                            width: 40,
                                            height: 40,
                                            errorBuilder: (_, __, ___) =>
                                                _avatarPersona(),
                                          )
                                        : _avatarPersona(),
                                  ),
                                ),
                                activeColor: _accent,
                                checkColor: Colors.white,
                              ),
                            );
                          },
                        ),
                ),
                // Botón crear — con el gradiente y sombra del botón "Traducir"
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _creando ? null : _crearGrupo,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        disabledBackgroundColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4F46E5)
                                  .withValues(alpha: 0.25),
                              blurRadius: 30,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          child: _creando
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.group_add,
                                        color: Colors.white, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      "Crear grupo",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
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
}