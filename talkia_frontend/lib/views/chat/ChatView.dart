import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';

class ChatView extends StatefulWidget {
  final String conversacionId;
  final String otroUsuarioNombre;

  const ChatView({
    super.key,
    required this.conversacionId,
    required this.otroUsuarioNombre,
  });

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final TextEditingController _mensajeController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _enviando = false;
  int _cantidadMensajesAnterior = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatVM = context.read<ChatViewModel>();
      debugPrint("🔄 Iniciando escucha para conversación: ${widget.conversacionId}");
      chatVM.iniciarEscuchaMensajes(widget.conversacionId);
    });
  }

  @override
  void dispose() {
    context.read<ChatViewModel>().detenerEscuchaMensajes();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al enviar: $e")),
      );
    }

    setState(() => _enviando = false);
    _scrollAlFinal();
  }

  @override
  Widget build(BuildContext context) {
    final chatVM = context.watch<ChatViewModel>();
    final auth = context.watch<AuthViewModel>();
    final usuario = auth.usuario;

    // Si llegaron mensajes nuevos, baja el scroll automáticamente
    if (chatVM.mensajes.length != _cantidadMensajesAnterior) {
      _cantidadMensajesAnterior = chatVM.mensajes.length;
      _scrollAlFinal();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otroUsuarioNombre),
        backgroundColor: const Color(0xFF006677),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: chatVM.mensajes.isEmpty
                ? Center(
                    // Mostrará el error si la petición falló, o el mensaje por defecto
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: chatVM.mensajes.length,
                    itemBuilder: (context, index) {
                      final mensaje = chatVM.mensajes[index];
                      final esPropio = usuario != null && chatVM.esMensajePropio(mensaje, usuario.id!);
                      
                      final texto = usuario != null
                          ? chatVM.obtenerTextoTraducido(mensaje, usuario.idiomaPredeterminado)
                          : mensaje.textoOriginal;

                      return Align(
                        alignment: esPropio ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: esPropio ? const Color(0xFF006677) : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            texto,
                            style: TextStyle(color: esPropio ? Colors.white : Colors.black87),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mensajeController,
                    decoration: InputDecoration(
                      hintText: "Escribe un mensaje...",
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onSubmitted: (_) => _enviar(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF006677)),
                  onPressed: _enviando ? null : _enviar,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}