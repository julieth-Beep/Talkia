import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AudioRecorderButton extends StatefulWidget {
  final Function(File archivoAudio) onAudioListo;

  const AudioRecorderButton({super.key, required this.onAudioListo});

  @override
  State<AudioRecorderButton> createState() => _AudioRecorderButtonState();
}

class _AudioRecorderButtonState extends State<AudioRecorderButton> {
  final AudioRecorder _recorder = AudioRecorder();
  bool _grabando = false;
  Duration _duracion = Duration.zero;
  Timer? _timer;

  Future<void> _iniciarGrabacion() async {
    // Web no soporta grabación con el paquete record
    if (kIsWeb) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Grabar notas de voz aún no está soportado en Web'),
          ),
        );
      }
      return;
    }

    try {
      final tienePermiso = await _recorder.hasPermission();
      if (!tienePermiso) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Se necesita permiso de micrófono')),
          );
        }
        return;
      }

      final tempDir = await getTemporaryDirectory();
      // ✅ FORMATO CORRECTO: .m4a con encoder AAC
      final path = '${tempDir.path}/nota_voz_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );

      setState(() {
        _grabando = true;
        _duracion = Duration.zero;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() => _duracion += const Duration(seconds: 1));
        }
      });
    } catch (e) {
      debugPrint('❌ Error al iniciar grabación: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo acceder al micrófono: $e')),
        );
      }
    }
  }

  Future<void> _detenerYEnviar() async {
    _timer?.cancel();
    final path = await _recorder.stop();
    setState(() => _grabando = false);

    if (path != null) {
      widget.onAudioListo(File(path));
    }
  }

  Future<void> _cancelar() async {
    _timer?.cancel();
    await _recorder.stop();
    setState(() => _grabando = false);
  }

  String _formatearDuracion(Duration d) {
    final minutos = d.inMinutes.toString().padLeft(2, '0');
    final segundos = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutos:$segundos';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_grabando) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: _cancelar,
          ),
          const Icon(Icons.fiber_manual_record, color: Colors.red, size: 14),
          const SizedBox(width: 6),
          Text(
            _formatearDuracion(_duracion),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.send, color: Color(0xFF006677)),
            onPressed: _detenerYEnviar,
          ),
        ],
      );
    }

    return IconButton(
      icon: const Icon(Icons.mic, color: Color.fromARGB(255, 50, 27, 80)),
      onPressed: _iniciarGrabacion,
    );
  }
}