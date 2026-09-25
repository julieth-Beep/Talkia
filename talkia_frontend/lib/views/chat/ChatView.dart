import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'audio_recorder_widget.dart';
import 'audio_player_bubble.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../data/services/Contacto_Service.dart';
import 'DiccionarioView.dart';
import '../../data/services/VideoCall_Service.dart';
import '../../data/services/Chat_Service.dart';
import 'DetallesContactoView.dart';
import 'DetallesGrupoView.dart';

class ChatView extends StatefulWidget {
  final String conversacionId;
  final String? otroUsuarioId;
  final String? otroUsuarioNombre;
  final String? titulo;
  final bool esGrupo;

  const ChatView({
    super.key,
    required this.conversacionId,
    this.otroUsuarioId,
    this.otroUsuarioNombre,
    this.titulo,
    this.esGrupo = false,
  });

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final TextEditingController _mensajeController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _enviando = false;
  bool _conectandoLlamada = false;
  int _cantidadMensajesAnterior = 0;

  String? _nombreMostrar;
  String? _fotoMostrar;

  @override
  void initState() {
    super.initState();
    _mensajeController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatVM = context.read<ChatViewModel>();
      debugPrint(
        "🔄 Iniciando escucha para conversación: ${widget.conversacionId}",
      );
      chatVM.iniciarEscuchaMensajes(widget.conversacionId);

      // 👈 Si es chat 1 a 1, consultar el nombre y foto
      if (!widget.esGrupo && widget.otroUsuarioId != null) {
        _cargarDatosAMostrar();
      }
    });
  }

  // 👈 Helper para completar la URL de la foto
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

  // 👈 Consulta el nombre y la foto al backend
  Future<void> _cargarDatosAMostrar() async {
    final auth = context.read<AuthViewModel>();
    if (auth.usuario?.id == null || widget.otroUsuarioId == null) return;

    try {
      final resultado = await ContactoService.obtenerDatosAMostrar(
        duenoId: auth.usuario!.id!,
        contactoId: widget.otroUsuarioId!,
      );
      if (!mounted) return;
      setState(() {
        _nombreMostrar = (resultado['nombre'] ?? '').isNotEmpty
            ? resultado['nombre']
            : widget.otroUsuarioNombre;
        _fotoMostrar = resultado['foto'] ?? '';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _nombreMostrar = widget.otroUsuarioNombre;
      });
    }
  }

  @override
  void dispose() {
    final chatVM = context.read<ChatViewModel>();

    // Si no hay mensajes, eliminar la conversación
    if (chatVM.mensajes.isEmpty && !widget.esGrupo) {
      ChatService.eliminarConversacionSiEstaVacia(widget.conversacionId);
    }

    chatVM.detenerEscuchaMensajes();
    _mensajeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollAlFinal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _enviar() async {
    final texto = _mensajeController.text.trim();
    if (texto.isEmpty || _enviando) return;

    final auth = context.read<AuthViewModel>();
    final chatVM = context.read<ChatViewModel>();

    setState(() => _enviando = true);
    _mensajeController.clear();

    try {
      await chatVM.enviarMensaje(
        conversacionId: widget.conversacionId,
        remitenteId: auth.usuario!.id!,
        texto: texto,
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error al enviar: $e")));
    }

    setState(() => _enviando = false);
    _scrollAlFinal();
  }

  void _enviarAudio(File archivo) async {
    final auth = context.read<AuthViewModel>();
    final chatVM = context.read<ChatViewModel>();

    await chatVM.enviarMensajeAudio(
      conversacionId: widget.conversacionId,
      remitenteId: auth.usuario!.id!,
      archivoAudio: archivo,
    );

    _scrollAlFinal();
  }

  Future<void> _videollamada() async {
    if (_conectandoLlamada) return;
    final user = context.read<AuthViewModel>().usuario;
    if (user == null) return;
    setState(() => _conectandoLlamada = true);
    try {
      await VideoCallService.iniciarLlamada(
        conversacionId: widget.conversacionId,
        nombreUsuario: user.nombre,
        correoUsuario: user.correo,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No se pudo iniciar la videollamada: $e")),
      );
    } finally {
      if (mounted) setState(() => _conectandoLlamada = false);
    }
  }

  // ═══════════════════════════════════════════════════════
  //  AVATAR DEL CHAT (GRUPO O USUARIO)
  // ═══════════════════════════════════════════════════════
  Widget _buildAvatarChat() {
    // Si es grupo → ícono de grupo
    if (widget.esGrupo) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.group, color: Color(0xFF4F46E5), size: 22),
      );
    }

    // Si es chat 1 a 1 → foto o inicial
    final fotoUrl = _completarUrl(_fotoMostrar ?? '');

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: fotoUrl.isNotEmpty
            ? Image.network(
                fotoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _avatarInicial(),
              )
            : _avatarInicial(),
      ),
    );
  }

  Widget _avatarInicial() {
    final nombre = _nombreMostrar ?? widget.otroUsuarioNombre ?? 'U';
    return Container(
      color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
      child: Center(
        child: Text(
          nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Color(0xFF4F46E5),
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatVM = context.watch<ChatViewModel>();
    final auth = context.watch<AuthViewModel>();
    final usuario = auth.usuario;

    if (chatVM.mensajes.length != _cantidadMensajesAnterior) {
      _cantidadMensajesAnterior = chatVM.mensajes.length;
      _scrollAlFinal();
    }

    // Título según tipo + nombre personalizado
    final tituloChat = widget.esGrupo
        ? (widget.titulo ?? "Grupo")
        : (_nombreMostrar ?? widget.otroUsuarioNombre ?? "Chat");

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA).withValues(alpha: 0.8),
        elevation: 0,
        foregroundColor: const Color(0xFF1A1A1C),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1C)),
          onPressed: () => Navigator.pop(context),
        ),
        // 👈 TÍTULO CLICKEABLE: AVATAR + NOMBRE
        title: InkWell(
          onTap: _abrirDetalles,
          child: Row(
            children: [
              _buildAvatarChat(),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  tituloChat,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1C),
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: _conectandoLlamada ? null : _videollamada,
            tooltip: widget.esGrupo ? "Videollamada grupal" : "Videollamada",
            icon: _conectandoLlamada
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.videocam_outlined, color: Color(0xFF006677)),
          ),
          if (!widget.esGrupo)
            Container(
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.menu_book_outlined,
                  size: 20,
                  color: Color(0xFF4F46E5),
                ),
                tooltip: 'Diccionario personalizado',
                onPressed: () {
                  if (widget.otroUsuarioId == null) return;
                  final auth = context.read<AuthViewModel>();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DiccionarioView(
                        usuarioId: auth.usuario!.id!,
                        contactoId: widget.otroUsuarioId!,
                        contactoNombre: tituloChat,
                      ),
                    ),
                  );
                },
              ),
            )
          else
            const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: chatVM.mensajes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: const Color(0xFF52525B).withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "No hay mensajes aún",
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF52525B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Envía un mensaje para empezar",
                          style: TextStyle(
                            fontSize: 14,
                            color: const Color(
                              0xFF52525B,
                            ).withValues(alpha: 0.6),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: chatVM.mensajes.length,
                    itemBuilder: (context, index) {
                      final mensaje = chatVM.mensajes[index];
                      final esPropio =
                          usuario != null &&
                          chatVM.esMensajePropio(mensaje, usuario.id!);

                      final texto = usuario != null
                          ? chatVM.obtenerTextoTraducido(
                              mensaje,
                              usuario.idiomaPredeterminado,
                            )
                          : (mensaje.textoOriginal ?? "");

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Align(
                          alignment: esPropio
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.75,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: esPropio
                                  ? const Color.fromARGB(255, 101, 99, 151)
                                  : const Color(0xFFFFFFFF),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: mensaje.tipo == "audio"
                                ? AudioPlayerBubble(
                                    audioUrl: mensaje.audioUrl!,
                                    esPropio: esPropio,
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (widget.esGrupo &&
                                          !esPropio &&
                                          mensaje.remitenteNombre != null)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 2,
                                          ),
                                          child: Text(
                                            mensaje.remitenteNombre!,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF4F46E5),
                                            ),
                                          ),
                                        ),
                                      Text(
                                        texto,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          height: 1.4,
                                          color: esPropio
                                              ? Colors.white
                                              : const Color(0xFF1A1A1C),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mensajeController,
                    decoration: InputDecoration(
                      hintText: "Escribe un mensaje...",
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                    ),
                    onSubmitted: (_) => _enviar(),
                  ),
                ),
                const SizedBox(width: 8),
                if (_mensajeController.text.trim().isEmpty)
                  Expanded(
                    child: AudioRecorderButton(onAudioListo: _enviarAudio),
                  )
                else
                  IconButton(
                    icon: const Icon(
                      Icons.send,
                      color: Color.fromARGB(255, 46, 0, 119),
                    ),
                    onPressed: _enviando ? null : _enviar,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  ABRIR DETALLES DEL CONTACTO/GRUPO
  // ═══════════════════════════════════════════════════════
  void _abrirDetalles() {
    // 👈 DECIDIR QUÉ VISTA ABRIR SEGÚN EL TIPO
    if (widget.esGrupo) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetallesGrupoView(
            nombre: widget.titulo ?? "Grupo",
            fotoUrl: null,
            conversacionId: widget.conversacionId,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetallesContactoView(
            nombre:
                _nombreMostrar ??
                widget.otroUsuarioNombre ??
                widget.titulo ??
                'Usuario',
            username: null,
            telefono: null,
            fotoUrl: _fotoMostrar,
            esGrupo: false,
            cantidadMiembros: null,
            conversacionId: widget.conversacionId,
            otroUsuarioId: widget.otroUsuarioId,
          ),
        ),
      );
    }
  }
}
