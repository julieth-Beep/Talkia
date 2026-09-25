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
  const CrearGrupoView({super.key});

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
    if (_seleccionados.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Selecciona al menos 2 miembros (tú eres el 3º)")),
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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Nuevo grupo',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1C),
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: const Color(0xFFF8F9FA).withValues(alpha: 0.8),
        foregroundColor: const Color(0xFF1A1A1C),
        elevation: 0,
        centerTitle: false,
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
          : Column(
              children: [
                // Nombre del grupo
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    controller: _nombreController,
                    decoration: InputDecoration(
                      hintText: "Nombre del grupo",
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.group,
                          color: Color(0xFF4F46E5)),
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
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF52525B)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Buscador
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _busquedaController,
                    decoration: InputDecoration(
                      hintText: "Buscar en mis contactos...",
                      prefixIcon: const Icon(Icons.search,
                          color: Color(0xFF52525B)),
                      filled: true,
                      fillColor: Colors.white,
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
                                  color: const Color(0xFF52525B)
                                      .withValues(alpha: 0.4),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  "No tienes contactos ni conversaciones aún",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF52525B),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  "Agrega contactos o inicia un chat primero",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF9CA3AF),
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
                                color: seleccionado
                                    ? const Color(0xFF4F46E5)
                                        .withValues(alpha: 0.08)
                                    : Colors.white,
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
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1A1A1C),
                                  ),
                                ),
                                subtitle: Text(
                                  "@${u.username} · ${u.idiomaPredeterminado}",
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF52525B),
                                  ),
                                ),
                                secondary: CircleAvatar(
                                  backgroundColor: const Color(0xFF4F46E5)
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
                                activeColor: const Color(0xFF4F46E5),
                              ),
                            );
                          },
                        ),
                ),
                // Botón crear
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _creando ? null : _crearGrupo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: _creando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.group_add),
                      label: const Text(
                        "Crear grupo",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _avatarPersona() {
    return const Icon(
      Icons.person,
      color: Color(0xFF4F46E5),
      size: 22,
    );
  }
}