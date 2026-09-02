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
      appBar: AppBar(
        title: const Text("Contactos"),
        backgroundColor: const Color(0xFF006677),
        foregroundColor: Colors.white,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _usuarios.isEmpty
              ? const Center(child: Text("No hay otros usuarios registrados aún"))
              : ListView.builder(
                  itemCount: _usuarios.length,
                  itemBuilder: (context, index) {
                    final usuario = _usuarios[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF006677),
                        child: Text(
                          usuario.nombre.isNotEmpty ? usuario.nombre[0] : "?",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text("${usuario.nombre} ${usuario.apellido}"),
                      subtitle: Text("Idioma: ${usuario.idiomaPredeterminado}"),
                      onTap: () => _abrirChatCon(usuario),
                    );
                  },
                ),
    );
  }
}