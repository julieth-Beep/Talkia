import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../auth/login_view.dart';

class PerfilView extends StatefulWidget {
  const PerfilView({super.key});

  @override
  State<PerfilView> createState() => _PerfilViewState();
}

class _PerfilViewState extends State<PerfilView> {
  // ─── Colores del design system ─────────────────────────
  static const Color _surface = Color(0xFFF8F9FF);
  static const Color _onSurface = Color(0xFF0B1C30);
  static const Color _onSurfaceVariant = Color(0xFF464554);
  static const Color _primary = Color(0xFF2A14B4);
  static const Color _primaryContainer = Color(0xFF4338CA);
  static const Color _onPrimary = Color(0xFFFFFFFF);
  static const Color _surfaceContainerLow = Color(0xFFEFF4FF);
  static const Color _surfaceContainerHigh = Color(0xFFDCE9FF);
  static const Color _surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color _error = Color(0xFFBA1A1A);
  static const Color _errorContainer = Color(0xFFFFDAD6);

  static const List<Map<String, dynamic>> _opcionesInfo = [
    {'texto': 'Disponible'},
    {'texto': 'En el trabajo 💻'},
    {'texto': 'Estudiando'},
    {'texto': 'Jugando 🎮'},
    {'texto': 'Comiendo 🍔'},
    {'texto': 'Durmiendo 💤'},
    {'texto': 'Ocupado'},
    {'texto': 'Escuchando música 🎶'},
    {'texto': 'En camino 🚗'},
  ];

  // ═══════════════════════════════════════════════════════
  //  UTILIDAD: COMPLETAR URL DE FOTO
  // ═══════════════════════════════════════════════════════
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
    final auth = context.watch<AuthViewModel>();
    final usuario = auth.usuario;

    // Datos del usuario
    final username = usuario?.username ?? '';
    final correo = usuario?.correo ?? '';
    final fotoUrl = _completarUrl(usuario?.fotoUrl ?? '');

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Perfil',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1C),
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: const Color(0xFFF8F9FA),
        foregroundColor: const Color(0xFF1A1A1C),
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1C)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_2, color: _primary, size: 24),
            onPressed: () {},
            splashRadius: 24,
          ),
          const SizedBox(width: 8),
        ],
      ),
      // ═══════════════ CONTENIDO ═══════════════
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(
          children: [
            // ─── Foto de perfil ───
            _buildFotoPerfil(fotoUrl),
            const SizedBox(height: 22),

            // ─── Nombre + Apellido ───
            _buildCardMulti([
              {
                'icon': Icons.person,
                'label': 'Nombre',
                'value': (usuario?.nombre ?? '').isEmpty
                    ? 'Sin nombre'
                    : usuario!.nombre,
                'trailing': Icons.edit,
                'onTap': () => _editarCampo(
                  titulo: 'Editar nombre',
                  valorActual: usuario?.nombre ?? '',
                  campo: 'nombre',
                ),
              },
              {
                'icon': Icons.person_outline,
                'label': 'Apellido',
                'value': (usuario?.apellido ?? '').isEmpty
                    ? 'Sin apellido'
                    : usuario!.apellido,
                'trailing': Icons.edit,
                'onTap': () => _editarCampo(
                  titulo: 'Editar apellido',
                  valorActual: usuario?.apellido ?? '',
                  campo: 'apellido',
                ),
              },
            ]),

            const SizedBox(height: 16),

            // ─── Info (estado) ───
            _buildCard(
              icon: Icons.info_outline,
              label: 'Info',
              value: usuario?.info ?? 'Disponible',
              onTap: _mostrarSelectorInfo,
            ),
            const SizedBox(height: 16),

            // ─── Username + Correo ───
            _buildCardMulti([
              {
                'icon': Icons.alternate_email,
                'label': 'Nombre de usuario',
                'value': username.isEmpty ? 'Sin definir' : '@$username',
                'trailing': Icons.lock,
                'onTap': null,
              },
              {
                'icon': Icons.mail_outline,
                'label': 'Correo',
                'value': correo.isEmpty ? 'Sin correo' : correo,
                'trailing': Icons.edit,
                'onTap': () => _editarCampo(
                  titulo: 'Editar correo',
                  valorActual: correo,
                  campo: 'correo',
                ),
              },
            ]),
            const SizedBox(height: 16),

            // ─── Código QR ───
            _buildQRCard(),
            const SizedBox(height: 30),

            // ─── Botón cerrar sesión ───
            _buildBotonCerrarSesion(context),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  FOTO DE PERFIL
  // ═══════════════════════════════════════════════════════
  Widget _buildFotoPerfil(String fotoUrl) {
    return Column(
      children: [
        SizedBox(
          height: 144,
          width: 144,
          child: Stack(
            children: [
              Container(
                width: 144,
                height: 144,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _surfaceContainerHigh,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: fotoUrl.isNotEmpty
                      ? Image.network(
                          fotoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _avatarFallback(),
                        )
                      : _avatarFallback(),
                ),
              ),
              Positioned(
                bottom: 4,
                right: 4,
                child: GestureDetector(
                  onTap: _cambiarFoto,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.photo_camera,
                      color: _onPrimary,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _avatarFallback() {
    return Container(
      color: _surfaceContainerHigh,
      child: const Icon(Icons.person, size: 60, color: _primary),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  CAMBIAR FOTO DE PERFIL
  // ═══════════════════════════════════════════════════════
  Future<void> _cambiarFoto() async {
    final ImageSource? fuente = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD4D4D8),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Cambiar foto de perfil',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1C),
                ),
              ),
            ),
            const Divider(height: 0, color: Color(0xFFF4F4F5)),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.photo_camera, color: _primary),
              ),
              title: const Text(
                'Tomar foto',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            const Divider(height: 0, indent: 20, endIndent: 20),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.photo_library, color: _primary),
              ),
              title: const Text(
                'Elegir de la galería',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (fuente == null) return;

    final picker = ImagePicker();
    final XFile? imagen = await picker.pickImage(
      source: fuente,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (imagen == null) return;
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator(color: _primary)),
    );

    try {
      final auth = context.read<AuthViewModel>();
      final exito = await auth.actualizarFotoPerfil(foto: File(imagen.path));

      if (!mounted) return;
      Navigator.pop(context);

      if (exito) {
        _mostrarSnackGlass(
          context,
          mensaje: 'Foto actualizada correctamente',
          icono: Icons.check_circle_outline,
        );
        setState(() {});
      } else {
        _mostrarSnackGlass(
          context,
          mensaje: auth.errorMessage ?? 'Error al subir la foto',
          icono: Icons.error_outline,
          esError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // ═══════════════════════════════════════════════════════
  //  EDITAR CAMPO (NOMBRE, APELLIDO O CORREO)
  // ═══════════════════════════════════════════════════════
  Future<void> _editarCampo({
    required String titulo,
    required String valorActual,
    required String campo,
  }) async {
    final controller = TextEditingController(text: valorActual);
    final formKey = GlobalKey<FormState>();

    final resultado = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(titulo),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            keyboardType: campo == 'correo'
                ? TextInputType.emailAddress
                : TextInputType.text,
            decoration: InputDecoration(
              hintText: campo == 'correo' ? 'tu@correo.com' : 'Escribe aquí...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
            validator: (value) {
              final v = value?.trim() ?? '';
              if (v.isEmpty) return 'Este campo no puede estar vacío';
              if (campo == 'correo' && !v.contains('@')) {
                return 'Correo no válido';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, controller.text.trim());
              }
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );

    if (resultado == null || resultado == valorActual) return;
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator(color: _primary)),
    );

    try {
      final auth = context.read<AuthViewModel>();

      final exito = await auth.actualizarDatosPersonales(
        nombre: campo == 'nombre' ? resultado : null,
        apellido: campo == 'apellido' ? resultado : null,
        correo: campo == 'correo' ? resultado : null,
      );

      if (!mounted) return;
      Navigator.pop(context);

      if (exito) {
        _mostrarSnackGlass(
          context,
          mensaje: '$titulo completado',
          icono: Icons.check_circle_outline,
        );
      } else {
        _mostrarSnackGlass(
          context,
          mensaje: auth.errorMessage ?? 'Error al actualizar',
          icono: Icons.error_outline,
          esError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // ═══════════════════════════════════════════════════════
  //  CARD GENÉRICA
  // ═══════════════════════════════════════════════════════
  Widget _buildCard({
    required IconData icon,
    required String label,
    required String value,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: _primary, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _onSurfaceVariant,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.edit, color: _primary, size: 20),
                ],
              ),
            ),
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(left: 68, right: 16, bottom: 12),
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: _onSurfaceVariant.withValues(alpha: 0.8),
                  height: 1.4,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  CARD MÚLTIPLE (usuario + correo)
  // ═══════════════════════════════════════════════════════
  Widget _buildCardMulti(List<Map<String, dynamic>> items) {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            InkWell(
              onTap: items[i]['onTap'],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(items[i]['icon'], color: _primary, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            items[i]['label'].toString().toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _onSurfaceVariant,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            items[i]['value'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      items[i]['trailing'],
                      color: items[i]['trailing'] == Icons.lock
                          ? _onSurfaceVariant.withValues(alpha: 0.5)
                          : _primary,
                      size: items[i]['trailing'] == Icons.lock ? 18 : 20,
                    ),
                  ],
                ),
              ),
            ),
            if (i < items.length - 1)
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: _surfaceContainerLow,
              ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  CARD QR
  // ═══════════════════════════════════════════════════════
  Widget _buildQRCard() {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.qr_code, color: _primary, size: 22),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Código QR del perfil',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _onSurface,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Comparte tu contacto al instante',
                      style: TextStyle(fontSize: 13, color: _onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.qr_code_scanner, color: _primary, size: 22),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    color: _onSurfaceVariant.withValues(alpha: 0.6),
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  BOTÓN CERRAR SESIÓN
  // ═══════════════════════════════════════════════════════
  Widget _buildBotonCerrarSesion(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: () => _cerrarSesion(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: _errorContainer.withValues(alpha: 0.4),
          foregroundColor: _error,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.logout, size: 20, color: _error),
        label: const Text(
          'Cerrar Sesión',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _error,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  SELECTOR DE INFO
  // ═══════════════════════════════════════════════════════
  Future<void> _mostrarSelectorInfo() async {
    final auth = context.read<AuthViewModel>();
    final infoActual = auth.usuario?.info ?? 'Disponible';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 30,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD4D4D8),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Selecciona tu estado',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1C),
                ),
              ),
            ),
            const Divider(height: 0, color: Color(0xFFF4F4F5)),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _opcionesInfo.length,
              separatorBuilder: (_, __) => const Divider(
                height: 0.1,
                indent: 20,
                endIndent: 20,
                color: Color(0xFFF4F4F5),
              ),
              itemBuilder: (context, index) {
                final opcion = _opcionesInfo[index];
                final textoCompleto = '${opcion['texto']}';
                final isSelected = infoActual == textoCompleto;

                return InkWell(
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _guardarInfo(textoCompleto);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        if (isSelected)
                          const Padding(
                            padding: EdgeInsets.only(right: 12),
                            child: Icon(Icons.check, color: _primary, size: 20),
                          )
                        else
                          const SizedBox(width: 32),
                        Text(
                          textoCompleto,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isSelected
                                ? _primary
                                : const Color(0xFF1A1A1C),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            InkWell(
              onTap: () {
                Navigator.pop(sheetContext);
                _mostrarDialogoPersonalizado();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.edit, color: _primary, size: 16),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Personalizado...',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  GUARDAR INFO EN EL BACKEND
  // ═══════════════════════════════════════════════════════
  Future<void> _guardarInfo(String nuevoInfo) async {
    final auth = context.read<AuthViewModel>();
    final infoActual = auth.usuario?.info ?? 'Disponible';

    if (nuevoInfo == infoActual) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator(color: _primary)),
    );

    try {
      final exito = await auth.actualizarInfo(info: nuevoInfo);

      if (!mounted) return;
      Navigator.pop(context);

      if (exito) {
        _mostrarSnackGlass(
          context,
          mensaje: 'Estado actualizado',
          icono: Icons.check_circle_outline,
        );
      } else {
        _mostrarSnackGlass(
          context,
          mensaje: auth.errorMessage ?? 'Error al actualizar estado',
          icono: Icons.error_outline,
          esError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // ═══════════════════════════════════════════════════════
  //  DIÁLOGO PERSONALIZADO
  // ═══════════════════════════════════════════════════════
  Future<void> _mostrarDialogoPersonalizado() async {
    final auth = context.read<AuthViewModel>();
    final controller = TextEditingController(
      text: auth.usuario?.info ?? 'Disponible',
    );

    final resultado = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Estado personalizado"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Escribe tu estado",
              style: TextStyle(fontSize: 13, color: Color(0xFF52525B)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              maxLength: 50,
              decoration: InputDecoration(
                hintText: 'Ej: Trabajando 💻',
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              final texto = controller.text.trim();
              if (texto.isEmpty) return;
              Navigator.pop(dialogContext, texto);
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );

    if (resultado != null) {
      await _guardarInfo(resultado);
    }
  }

  // ═══════════════════════════════════════════════════════
  //  SNACKBAR CON GLASSMORPHISM
  // ═══════════════════════════════════════════════════════
  void _mostrarSnackGlass(
    BuildContext context, {
    required String mensaje,
    required IconData icono,
    bool esError = false,
  }) {
    final messenger = ScaffoldMessenger.of(context);

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
        padding: EdgeInsets.zero,
        duration: const Duration(seconds: 3),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: (esError ? _error : _primary).withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (esError ? _error : _primary).withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(icono, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      mensaje,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

    // ═══════════════════════════════════════════════════════
  //  CERRAR SESIÓN
  // ═══════════════════════════════════════════════════════
  Future<void> _cerrarSesion(BuildContext context) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text("Cerrar sesión"),
        content: const Text("¿Estás seguro que quieres cerrar sesión?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Cerrar sesión"),
          ),
        ],
      ),
    );

    if (confirmado != true) return;
    if (!context.mounted) return;

    await context.read<AuthViewModel>().cerrarSesion();

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginView()),
      (route) => false,
    );
  }
}