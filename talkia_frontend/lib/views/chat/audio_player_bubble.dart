import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AudioPlayerBubble extends StatefulWidget {
  final String audioUrl;
  final bool esPropio;

  const AudioPlayerBubble({
    super.key,
    required this.audioUrl,
    required this.esPropio,
  });

  @override
  State<AudioPlayerBubble> createState() => _AudioPlayerBubbleState();
}

class _AudioPlayerBubbleState extends State<AudioPlayerBubble> {
  final AudioPlayer _player = AudioPlayer();
  bool _reproduciendo = false;
  bool _cargando = false;
  Duration _duracion = Duration.zero;
  Duration _posicion = Duration.zero;

  /// Construye la URL completa según la plataforma
  String _getFullUrl() {
    String url = widget.audioUrl;

    // Si ya es URL completa, la devuelve tal cual
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    // Si es ruta relativa, le agrega el servidor
    if (!kIsWeb && Platform.isAndroid) {
      // Emulador Android
      return "http://10.0.2.2:3000$url";
    } else {
      // Web, iOS, Desktop
      return "http://localhost:3000$url";
    }
  }

  @override
  void initState() {
    super.initState();

    // Escucha el estado del reproductor (play/pause/buffering)
    _player.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _reproduciendo = state.playing;
          _cargando = state.processingState == ProcessingState.loading ||
              state.processingState == ProcessingState.buffering;
        });
      }
    });

    // Escucha la duración total del audio
    _player.durationStream.listen((d) {
      if (mounted && d != null) {
        setState(() => _duracion = d);
      }
    });

    // Escucha la posición actual
    _player.positionStream.listen((p) {
      if (mounted) {
        setState(() => _posicion = p);
      }
    });
  }

  Future<void> _togglePlay() async {
    if (_cargando) return;

    if (_reproduciendo) {
      await _player.pause();
      return;
    }

    try {
      final fullUrl = _getFullUrl();
      debugPrint("🎵 Reproduciendo: $fullUrl");

      await _player.setUrl(fullUrl);
      await _player.play();
    } catch (e) {
      debugPrint("❌ Error al reproducir: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al reproducir audio: $e")),
        );
      }
    }
  }

  String _formatear(Duration d) {
    final minutos = d.inMinutes.toString().padLeft(2, '0');
    final segundos = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutos:$segundos';
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Color del texto/íconos según si es mensaje propio o del otro
    final color = widget.esPropio ? Colors.white : Colors.black87;

    return Container(
      width: 220,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Botón Play/Pause
          IconButton(
            icon: _cargando
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  )
                : Icon(
                    _reproduciendo ? Icons.pause : Icons.play_arrow,
                    color: color,
                  ),
            onPressed: _cargando ? null : _togglePlay,
          ),

          // Slider de progreso
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                    activeTrackColor: color,
                    inactiveTrackColor: color.withOpacity(0.3),
                    thumbColor: color,
                    overlayShape: SliderComponentShape.noOverlay,
                  ),
                  child: Slider(
                    value: _duracion.inMilliseconds > 0
                        ? _posicion.inMilliseconds
                            .clamp(0, _duracion.inMilliseconds)
                            .toDouble()
                        : 0,
                    max: _duracion.inMilliseconds > 0
                        ? _duracion.inMilliseconds.toDouble()
                        : 1,
                    onChanged: _duracion.inMilliseconds > 0
                        ? (v) => _player.seek(Duration(milliseconds: v.toInt()))
                        : null,
                  ),
                ),

                // Tiempo actual / duración
                Text(
                  _duracion.inMilliseconds > 0
                      ? "${_formatear(_posicion)} / ${_formatear(_duracion)}"
                      : "00:00 / 00:00",
                  style: TextStyle(
                    color: color.withOpacity(0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}