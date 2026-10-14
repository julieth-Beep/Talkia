import 'package:flutter/material.dart';
import '../../data/models/Usuario_Model.dart';
import '../../data/services/Usuario_Service.dart';

class IdiomaView extends StatefulWidget {
  final UsuarioModel usuario;
  const IdiomaView({super.key, required this.usuario});

  @override
  State<IdiomaView> createState() => _IdiomaViewState();
}

class _IdiomaViewState extends State<IdiomaView> {
  static const idiomas = [
    'Español',
    'English',
    'Português',
    'Français',
    'Italiano',
    'Deutsch',
  ];

  late String _seleccionado;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _seleccionado = widget.usuario.idiomaPredeterminado;
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      await UsuarioService.completarPerfil(
        id: widget.usuario.id!,
        idiomaPredeterminado: _seleccionado,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Idioma actualizado')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Idioma')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: idiomas.length,
              itemBuilder: (context, i) {
                final idioma = idiomas[i];
                return RadioListTile<String>(
                  title: Text(idioma),
                  subtitle: idioma == widget.usuario.idiomaPredeterminado
                      ? const Text('Idioma actual')
                      : null,
                  value: idioma,
                  groupValue: _seleccionado,
                  onChanged: (v) => setState(() => _seleccionado = v!),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _guardando ? null : _guardar,
                child: _guardando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Guardar'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}