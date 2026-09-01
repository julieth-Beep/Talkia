import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../data/models/Mensaje_Model.dart';

class ChatView extends StatefulWidget {
  final String conversacionId;
  final String otroUsuarioId;
  final String otroUsuarioNombre;
  final String otroUsuarioIdioma;

  const ChatView({
    super.key,
    required this.conversacionId,
    required this.otroUsuarioId,
    required this.otroUsuarioNombre,
    required this.otroUsuarioIdioma,
  });

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final TextEditingController _mensajeController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _estaEnviando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatVM = context.read<ChatViewModel>();
      
      // 🔥 Iniciar la escucha de mensajes en tiempo real
      chatVM.iniciarEscuchaMensajes(widget.conversacionId);
      
      // Marcar mensajes como leídos
      final auth = context.read<AuthViewModel>();
      if (auth.usuario != null) {
        chatVM.marcarComoLeidos(
          conversacionId: widget.conversacionId,
          userId: auth.usuario!.id!,
        );
      }
      
      // Scroll al final después de cargar