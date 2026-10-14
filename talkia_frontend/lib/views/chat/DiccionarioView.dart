import 'package:flutter/material.dart';
import '../../data/services/Diccionario_Service.dart';
import '../../data/models/DiccionarioEntry_Model.dart';

class DiccionarioView extends StatefulWidget {
  final String usuarioId;
  final String contactoId;
  final String contactoNombre;

  const DiccionarioView({
    super.key,
    required this.usuarioId,
    required this.contactoId,
    required this.contactoNombre,
  });

  @override
  State<DiccionarioView> createState() => _DiccionarioViewState();
}

class _DiccionarioViewState extends State<DiccionarioView> {
  final _palabraController = TextEditingController();
  final _traduccionController = TextEditingController();

  List<DiccionarioEntryModel> _entradas = [];
  bool _cargando = true;
  bool _guardando = false;

  // ─────────────── PALETA (claro = valores originales, oscuro = equivalentes) ───────────────
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _scaffoldBg => _isDark ? const Color(0xFF121316) : const Color(0xFFF8F9FA);
  Color get _appBarBg => _isDark ? const Color(0xFF1B1D24) : const Color.fromARGB(255, 246, 244, 255);
  Color get _appBarFg => _isDark ? const Color(0xFFE6E1E9) : const Color.fromARGB(255, 0, 0, 0);
  Color get _onSurface => _isDark ? const Color(0xFFE6E1E9) : const Color(0xFF1A1A1C);
  Color get _fieldFill => _isDark ? const Color(0xFF1B1D24) : Colors.grey.shade100;
  Color get _divider => _isDark ? const Color(0xFF2A2D3A) : const Color(0xFFE5E7EB);
  Color get _botonBg => _isDark ? const Color(0xFF4338CA) : const Color.fromARGB(255, 128, 105, 172);
  Color get _arrow => _isDark ? const Color(0xFFA1A1AA) : Colors.grey;
  Color get _delete => _isDark ? const Color(0xFFFFB4AB) : Colors.red;
  // ───────────────────────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _cargarDiccionario();
  }

  @override
  void dispose() {
    _palabraController.dispose();
    _traduccionController.dispose();
    super.dispose();
  }

  Future<void> _cargarDiccionario() async {
    setState(() => _cargando = true);
    try {
      final entradas = await DiccionarioService.obtenerDiccionario(
        usuarioId: widget.usuarioId,
        contactoId: widget.contactoId,
      );
      setState(() {
        _entradas = entradas;
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar: $e')),
        );
      }
    }
  }

  Future<void> _agregarPalabra() async {
    final palabra = _palabraController.text.trim();
    final traduccion = _traduccionController.text.trim();

    if (palabra.isEmpty || traduccion.isEmpty) return;

    setState(() => _guardando = true);

    try {
      await DiccionarioService.agregarPalabra(
        usuarioId: widget.usuarioId,
        contactoId: widget.contactoId,
        palabraOriginal: palabra,
        traduccionFija: traduccion,
      );

      _palabraController.clear();
      _traduccionController.clear();
      await _cargarDiccionario();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    } finally {
      setState(() => _guardando = false);
    }
  }

  Future<void> _eliminarPalabra(String id) async {
    try {
      await DiccionarioService.eliminarPalabra(id);
      await _cargarDiccionario();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _scaffoldBg,
      appBar: AppBar(
        title: Text('Diccionario con ${widget.contactoNombre}'),
        backgroundColor: _appBarBg,
        foregroundColor: _appBarFg,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Agrega una palabra personalizada',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: _onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _palabraController,
                        style: TextStyle(color: _onSurface),
                        cursorColor: _botonBg,
                        decoration: InputDecoration(
                          hintText: 'Palabra original',
                          hintStyle: TextStyle(color: _isDark ? const Color(0xFFA1A1AA) : Colors.grey.shade600),
                          filled: true,
                          fillColor: _fieldFill,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 18, color: _arrow),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _traduccionController,
                        style: TextStyle(color: _onSurface),
                        cursorColor: _botonBg,
                        decoration: InputDecoration(
                          hintText: 'Traducción fija',
                          hintStyle: TextStyle(color: _isDark ? const Color(0xFFA1A1AA) : Colors.grey.shade600),
                          filled: true,
                          fillColor: _fieldFill,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _guardando ? null : _agregarPalabra,
                    icon: _guardando
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.add, size: 18),
                    label: const Text('Agregar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _botonBg,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: _divider),
          Expanded(
            child: _cargando
                ? Center(child: CircularProgressIndicator(color: _botonBg))
                : _entradas.isEmpty
                    ? Center(
                        child: Text(
                          'Aún no hay palabras personalizadas',
                          style: TextStyle(color: _onSurface),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _entradas.length,
                        itemBuilder: (context, index) {
                          final entrada = _entradas[index];
                          return ListTile(
                            title: Text(
                              '${entrada.palabraOriginal} → ${entrada.traduccionFija}',
                              style: TextStyle(color: _onSurface),
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.delete_outline, color: _delete),
                              onPressed: () => _eliminarPalabra(entrada.id!),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}