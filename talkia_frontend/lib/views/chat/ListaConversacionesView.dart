import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../../data/services/Usuario_Service.dart';
import '../../data/models/Usuario_Model.dart';
import 'ChatView.dart';

class ListaConversacionesView extends StatefulWidget {
  const ListaConversacionesView({super.key});

  @override
  State<ListaConversacionesView> createState() => _ListaConversacionesViewState();
}

class _ListaConversacionesViewState extends State<ListaConversacionesView> {
  List<UsuarioModel> _usuarios = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  Future<void> _cargarUsuarios() async {
    final auth = context.read<AuthViewModel>();
    if (auth.usuario?.id == null) return;

    try {
      final usuarios = await UsuarioService.listarUsuarios(excluirId: auth.usuario!.id!);
      setState(() {
        _usuarios = usuarios;
        _cargando = false;
      });
    } catch (e) {
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

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatView(
          conversacionId: conversacion.id,
          otroUsuarioNombre: otroUsuario.nombre,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Contactos',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1C),
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: const Color(0xFFF8F9FA).withValues(alpha: 0.8),
        foregroundColor: const Color(0xFF1A1A1C),
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1C)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF4F46E5),
              ),
            )
          : _usuarios.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: const Color(0xFF52525B).withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "No hay otros usuarios registrados aún",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF52525B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _usuarios.length,
                  itemBuilder: (context, index) {
                    final usuario = _usuarios[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFFFF),
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
                          backgroundColor: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                          radius: 24,
                          child: Text(
                            usuario.nombre.isNotEmpty ? usuario.nombre[0].toUpperCase() : "?",
                            style: const TextStyle(
                              color: Color(0xFF4F46E5),
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        title: Text(
                          "${usuario.nombre} ${usuario.apellido}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1C),
                          ),
                        ),
                        subtitle: Row(
                          children: [
                            const Icon(
                              Icons.translate,
                              size: 14,
                              color: Color(0xFF52525B),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "Idioma: ${usuario.idiomaPredeterminado}",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF52525B),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Icon(
                            Icons.chat_bubble_outline,
                            size: 20,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                        onTap: () => _abrirChatCon(usuario),
                      ),
                    );
                  },
                ),
    );
  }
}