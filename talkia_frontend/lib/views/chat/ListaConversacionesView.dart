import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'ChatView.dart';

class ListaConversacionesView extends StatefulWidget {
  const ListaConversacionesView({super.key});

  @override
  State<ListaConversacionesView> createState() => _ListaConversacionesViewState();
}

class _ListaConversacionesViewState extends State<ListaConversacionesView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthViewModel>();
      if (auth.usuario != null) {
        context.read<ChatViewModel>().cargarConversaciones(auth.usuario!.id!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatVM = context.watch<ChatViewModel>();
    final auth = context.watch<AuthViewModel>();
    final usuario = auth.usuario;

    if (usuario == null) {
      return const Scaffold(
        body: Center(child: Text("Inicia sesión para ver tus conversaciones")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mensajes"),
        backgroundColor: const Color(0xFF006677),
        foregroundColor: Colors.white,
      ),
      body: chatVM.isLoading
          ? const Center(child: CircularProgressIndicator())
          : chatVM.conversaciones.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        "No tienes conversaciones",
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Busca contactos para empezar a chatear",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: chatVM.conversaciones.length,
                  itemBuilder: (context, index) {
                    final conversacion = chatVM.conversaciones[index];
                    final contacto = conversacion.contacto;
                    final idiomaUsuario = usuario.idiomaPredeterminado;
                    
                    // Obtener el último mensaje traducido
                    String ultimoMensaje = "Sin mensajes";
                    if (conversacion.ultimoMensajeTraducido != null &&
                        conversacion.ultimoMensajeTraducido!.containsKey(idiomaUsuario)) {
                      ultimoMensaje = conversacion.ultimoMensajeTraducido![idiomaUsuario]!;
                    } else if (conversacion.ultimoMensaje != null) {
                      ultimoMensaje = conversacion.ultimoMensaje!;
                    }

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF006677),
                        child: Text(
                          contacto != null
                              ? "${contacto['nombre'][0]}${contacto['apellido']?.isNotEmpty == true ? contacto['apellido'][0] : ''}"
                              : "?",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        contacto != null
                            ? "${contacto['nombre']} ${contacto['apellido'] ?? ''}"
                            : "Usuario desconocido",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        ultimoMensaje,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      onTap: () {
                        if (contacto != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatView(
                                conversacionId: conversacion.id,
                                otroUsuarioId: contacto['id'] ?? '',
                                otroUsuarioNombre: "${contacto['nombre']} ${contacto['apellido'] ?? ''}",
                                otroUsuarioIdioma: contacto['idioma'] ?? "Español",
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
    );
  }
}