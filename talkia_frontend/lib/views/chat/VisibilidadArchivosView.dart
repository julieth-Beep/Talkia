import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/chat_viewmodel.dart';

class VisibilidadArchivosView extends StatefulWidget {
  final String conversacionId;

  const VisibilidadArchivosView({
    super.key,
    required this.conversacionId,
  });

  @override
  State<VisibilidadArchivosView> createState() =>
      _VisibilidadArchivosViewState();
}

class _VisibilidadArchivosViewState extends State<VisibilidadArchivosView> {
  // ─────────────── PALETA ───────────────
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _scaffoldBg => _isDark ? const Color(0xFF121316) : const Color(0xFFF8F9FA);
  Color get _appBarFg => _isDark ? const Color(0xFFE6E1E9) : const Color(0xFF1A1A1C);
  Color get _onSurface => _isDark ? const Color(0xFFE6E1E9) : const Color(0xFF1A1A1C);
  Color get _onSurfaceVariant => _isDark ? const Color(0xFFA1A1AA) : const Color(0xFF52525B);
  Color get _accent => _isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4F46E5);
  Color get _divider => _isDark ? const Color(0xFF2A2D3A) : const Color(0xFFE5E7EB);
  Color get _tileBg => _isDark ? const Color(0xFF1B1D24) : const Color(0xFFE8EBF2);
  Color get _tileIcon => _isDark ? Colors.white70 : const Color(0xFF4F46E5);
  Color get _tileText => _isDark ? Colors.white : const Color(0xFF1A1A1C);
  Color get _error => _isDark ? const Color(0xFFFFB4AB) : const Color(0xFFBA1A1A);
  // ──────────────────────────────────────

  bool _seleccionando = false;
  final Set<String> _seleccionados = {};

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
  Widget build(BuildContext context) {
    final chatVM = context.watch<ChatViewModel>();
    final audios = chatVM.mensajes
        .where((m) => m.tipo == "audio" && m.audioUrl != null)
        .toList();

    return Scaffold(
      backgroundColor: _scaffoldBg,
      appBar: AppBar(
        backgroundColor: _scaffoldBg,
        foregroundColor: _appBarFg,
        elevation: 0,
        leading: _seleccionando
            ? IconButton(
                icon: Icon(Icons.close, color: _appBarFg),
                onPressed: () {
                  setState(() {
                    _seleccionando = false;
                    _seleccionados.clear();
                  });
                },
              )
            : IconButton(
                icon: Icon(Icons.arrow_back, color: _appBarFg),
                onPressed: () => Navigator.pop(context),
              ),
        title: _seleccionando
            ? Text(
                '${_seleccionados.length} seleccionados',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _appBarFg,
                ),
              )
            : null,
        actions: [
          if (!_seleccionando && audios.isNotEmpty)
            TextButton(
              onPressed: () {
                setState(() {
                  _seleccionando = true;
                  _seleccionados.addAll(
                    audios.map((m) => m.audioUrl!).toList(),
                  );
                });
              },
              child: Text(
                "Seleccionar todos",
                style: TextStyle(
                  color: _onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          // 👈 Botón de eliminar cuando hay seleccionados
          if (_seleccionando && _seleccionados.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_outline, color: _error),
              tooltip: 'Eliminar seleccionados',
              onPressed: _confirmarEliminar,
            ),
        ],
      ),
      body: Column(
        children: [
          // ─── Cabecera "TAMAÑO" ───
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "TAMAÑO",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _onSurface,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: _divider),
          Expanded(
            child: audios.isEmpty
                ? Center(
                    child: Text(
                      "No hay archivos multimedia",
                      style: TextStyle(color: _onSurfaceVariant),
                    ),
                  )
                : GridView.builder(
                    padding: EdgeInsets.zero,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 1,
                      mainAxisSpacing: 1,
                      childAspectRatio: 0.95,
                    ),
                    itemCount: audios.length,
                    itemBuilder: (context, index) {
                      final m = audios[index];
                      final url = _completarUrl(m.audioUrl!);
                      final key = m.audioUrl!;
                      final seleccionado = _seleccionados.contains(key);

                      return GestureDetector(
                        onTap: () {
                          // 👈 Si NO estamos en modo selección, activarlo y marcar este
                          if (!_seleccionando) {
                            setState(() {
                              _seleccionando = true;
                              _seleccionados.add(key);
                            });
                          } else {
                            // Ya en modo selección → alternar
                            setState(() {
                              if (seleccionado) {
                                _seleccionados.remove(key);
                              } else {
                                _seleccionados.add(key);
                              }
                            });
                          }
                        },
                        onLongPress: () {
                          setState(() {
                            _seleccionando = true;
                            _seleccionados.add(key);
                          });
                        },
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Container(
                              color: _tileBg,
                              child: Center(
                                child: Icon(
                                  Icons.headphones,
                                  size: 40,
                                  color: _tileIcon,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Text(
                                "—",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _tileText,
                                ),
                              ),
                            ),
                            // 👈 Casillita arriba a la derecha (solo en modo selección)
                            if (_seleccionando)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (seleccionado) {
                                        _seleccionados.remove(key);
                                      } else {
                                        _seleccionados.add(key);
                                      }
                                    });
                                  },
                                  child: Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: seleccionado
                                          ? _accent
                                          : Colors.black.withValues(alpha: 0.35),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: seleccionado
                                        ? const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 14,
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                            // Overlay verde/azul cuando está seleccionado
                            if (seleccionado)
                              IgnorePointer(
                                child: Container(
                                  color: _accent.withValues(alpha: 0.3),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _reproducirAudio(String url) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Reproducir: $url")),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  CONFIRMAR Y ELIMINAR
  // ═══════════════════════════════════════════════════════
  Future<void> _confirmarEliminar() async {
    final cantidad = _seleccionados.length;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Eliminar archivos"),
        content: Text(
          "¿Eliminar $cantidad audio${cantidad == 1 ? '' : 's'} seleccionado${cantidad == 1 ? '' : 's'}?",
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
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    final chatVM = context.read<ChatViewModel>();
    final urlsAEliminar = _seleccionados.toList();

    int eliminados = 0;
    int errores = 0;

    for (final url in urlsAEliminar) {
      // Buscar el mensaje por audioUrl
      final mensaje = chatVM.mensajes.firstWhere(
        (m) => m.audioUrl == url,
        orElse: () => throw Exception("no encontrado"),
      );
      if (mensaje.id == null) {
        errores++;
        continue;
      }
      final ok = await chatVM.eliminarMensaje(mensaje.id!);
      if (ok) {
        eliminados++;
      } else {
        errores++;
      }
    }

    if (!mounted) return;

    setState(() {
      _seleccionando = false;
      _seleccionados.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          errores == 0
              ? "$eliminados archivo${eliminados == 1 ? '' : 's'} eliminado${eliminados == 1 ? '' : 's'}"
              : "$eliminados eliminados, $errores con error",
        ),
      ),
    );
  }
}