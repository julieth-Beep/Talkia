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
      appBar: AppBar(
        title: Text('Diccionario con ${widget.contactoNombre}'),
        backgroundColor: const Color.fromARGB(255, 246, 244, 255),
        foregroundColor: const Color.fromARGB(255, 0, 0, 0),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Agrega una palabra personalizada',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _palabraController,
                        decoration: InputDecoration(
                          hintText: 'Palabra original',
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _traduccionController,
                        decoration: InputDecoration(
                          hintText: 'Traducción fija',
                          filled: true,
                          fillColor: Colors.grey.shade100,
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
                      backgroundColor: const Color.fromARGB(255, 128, 105, 172),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _entradas.isEmpty
                    ? const Center(child: Text('Aún no hay palabras personalizadas'))
                    : ListView.builder(
                        itemCount: _entradas.length,
                        itemBuilder: (context, index) {
                          final entrada = _entradas[index];
                          return ListTile(
                            title: Text('${entrada.palabraOriginal} → ${entrada.traduccionFija}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
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