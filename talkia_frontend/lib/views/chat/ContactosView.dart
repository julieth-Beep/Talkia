import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../../data/services/Usuario_Service.dart';
import '../../data/models/Usuario_Model.dart';
import 'ChatView.dart';

class ContactosView extends StatefulWidget {
  const ContactosView({super.key});

  @override
  State<ContactosView> createState() => _ContactosViewState();
}

class _ContactosViewState extends State<ContactosView> {
  List<UsuarioModel> _usuarios = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
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

  Future<void> _cargarUsuarios() async {
    final auth = context.read<AuthViewModel>();
    if (auth.usuario?.id == null) return;
    try {
      final usuarios = await UsuarioService.listarUsuarios(
        excluirId: auth.usuario!.id!,
      );
      if (!mounted) return;
      setState(() {
        _usuarios = usuarios;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  Future<void> _abrirChatCon(UsuarioModel otroUsuario) async {
    final auth = context.read<AuthViewModel>();
    final chatVM = context.read<ChatViewModel>();

    final conversacion = await chatVM.obtenerOCrearConversacion(
      uid1: auth.usuario!.id!,
      uid2: otroUsuario.id!,
    );

    if (!mounted || conversacion == null) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ChatView(
          conversacionId: conversacion.id,
          otroUsuarioId: otroUsuario.id!,
          otroUsuarioNombre:
              "${otroUsuario.nombre} ${otroUsuario.apellido}".trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Buscar contactos'),
        backgroundColor: const Color(0xFFF8F9FA).withValues(alpha: 0.8),
        foregroundColor: const Color(0xFF1A1A1C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
            )
          : _usuarios.isEmpty
          ? const Center(child: Text("No hay otros usuarios registrados aún"))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              itemCount: _usuarios.length,
              itemBuilder: (context, index) {
                final usuario = _usuarios[index];
                final fotoUrl = _completarUrl(usuario.fotoUrl ?? '');

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(
                        0xFF4F46E5,
                      ).withValues(alpha: 0.1),
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
                    title: Text("${usuario.nombre} ${usuario.apellido}"),
                    subtitle: Text("Idioma: ${usuario.idiomaPredeterminado}"),
                    onTap: () => _abrirChatCon(usuario),
                  ),
                );
              },
            ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  AVATAR PERSONA (FALLBACK)
  // ═══════════════════════════════════════════════════════
  Widget _avatarPersona() {
    return const Icon(
      Icons.person,
      color: Color(0xFF4F46E5),
      size: 22,
    );
  }
}