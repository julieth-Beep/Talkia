import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../views/perfil/Perfil.dart';
import '../auth/login_view.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'SeguridadView.dart';
import 'TerminosView.dart';
import '../../theme_controller.dart';

class ConfigView extends StatefulWidget {
  const ConfigView({super.key});

  @override
  State<ConfigView> createState() => _ConfigViewState();
}

class _ConfigViewState extends State<ConfigView> {
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

  // ================= PALETA =================
  // En CLARO: mismos valores de antes (diseño intacto).
  // En OSCURO: equivalentes oscuros para que el tema se aplique de verdad.
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _onSurface => _isDark ? const Color(0xFFE6E1E9) : const Color(0xFF0B1C30);
  Color get _onSurfaceVariant => _isDark ? const Color(0xFFC6C4D0) : const Color(0xFF464554);
  Color get _outline => _isDark ? const Color(0xFF918FA0) : const Color(0xFF777586);
  Color get _primary => _isDark ? const Color(0xFFBFC3FF) : const Color(0xFF2A14B4);
  static const Color _primaryContainer = Color(0xFF4338CA);
  static const Color _onPrimary = Color(0xFFFFFFFF);
  Color get _primaryFixed => _isDark ? const Color(0xFF2E2E6E) : const Color(0xFFE3DFFF);
  Color get _secondary => _isDark ? const Color(0xFFA9C7FF) : const Color(0xFF0051D5);
  Color get _secondaryFixed => _isDark ? const Color(0xFF233A66) : const Color(0xFFDBE1FF);
  Color get _tertiary => _isDark ? const Color(0xFF6BD8CB) : const Color(0xFF00423C);
  static const Color _tertiaryFixedDim = Color(0xFF6BD8CB);
  Color get _surfaceContainerLow => _isDark ? const Color(0xFF2A2D3A) : const Color(0xFFEFF4FF);
  Color get _surfaceContainerHigh => _isDark ? const Color(0xFF2B2F3E) : const Color(0xFFDCE9FF);
  Color get _surfaceContainerLowest => _isDark ? const Color(0xFF1B1D24) : const Color(0xFFFFFFFF);
  Color get _error => _isDark ? const Color(0xFFFFB4AB) : const Color(0xFFBA1A1A);
  Color get _errorContainer => _isDark ? const Color(0xFF93000A) : const Color(0xFFFFDAD6);
  Color get _onError => _isDark ? const Color(0xFF690005) : const Color(0xFFFFFFFF);
  Color get _scaffoldBg => _isDark ? const Color(0xFF121316) : const Color(0xFFF8F9FA);
  Color get _appBarFg => _isDark ? const Color(0xFFE6E1E9) : const Color(0xFF1A1A1C);
  // ==========================================

  static const Map<String, String> _idiomasDisponibles = {
    "Español": "ES",
    "Inglés": "EN",
    "Francés": "FR",
    "Italiano": "IT",
    "Portugués": "PT",
    "Alemán": "DE",
    "Mandarín": "ZH",
  };

  void _proximamente(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Próximamente'), duration: Duration(seconds: 1)),
    );
  }

  Future<void> _cambiarIdioma(BuildContext context) async {
    final auth = context.read<AuthViewModel>();
    final usuario = auth.usuario;
    if (usuario == null) return;

    final seleccionado = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Elige tu idioma',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            ..._idiomasDisponibles.keys.map((idioma) => ListTile(
                  title: Text(idioma),
                  trailing: idioma == usuario.idiomaPredeterminado
                      ? Icon(Icons.check, color: _primary)
                      : null,
                  onTap: () => Navigator.pop(context, idioma),
                )),
          ],
        ),
      ),
    );

    if (seleccionado == null || seleccionado == usuario.idiomaPredeterminado) return;
    if (!context.mounted) return;

    final exito = await auth.completarPerfil(
      id: usuario.id!,
      idiomaPredeterminado: seleccionado,
    );

    if (!context.mounted) return;
  }

  Future<void> _cambiarTema(BuildContext context) async {
    final seleccionado = await showModalBottomSheet<ThemeMode>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Apariencia', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            ListTile(
              title: const Text('Claro'),
              trailing: themeController.modeNotifier.value == ThemeMode.light
                  ? Icon(Icons.check, color: _primary) : null,
              onTap: () => Navigator.pop(context, ThemeMode.light),
            ),
            ListTile(
              title: const Text('Oscuro'),
              trailing: themeController.modeNotifier.value == ThemeMode.dark
                  ? Icon(Icons.check, color: _primary) : null,
              onTap: () => Navigator.pop(context, ThemeMode.dark),
            ),
            ListTile(
              title: const Text('Automático (sistema)'),
              trailing: themeController.modeNotifier.value == ThemeMode.system
                  ? Icon(Icons.check, color: _primary) : null,
              onTap: () => Navigator.pop(context, ThemeMode.system),
            ),
          ],
        ),
      ),
    );

    if (seleccionado == null) return;
    themeController.setMode(seleccionado);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final usuario = auth.usuario;

    final nombreCompleto = '${usuario?.nombre ?? ''} ${usuario?.apellido ?? ''}'.trim();
    final username = usuario?.username ?? '';
    final fotoUrl = _completarUrl(usuario?.fotoUrl ?? '');
    final idiomaActual = usuario?.idiomaPredeterminado ?? 'Español';
    final idiomaCodigo = _idiomasDisponibles[idiomaActual] ?? 'ES';

    return Scaffold(
      backgroundColor: _scaffoldBg,
      appBar: AppBar(
        title: Text(
          'Configuración',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _appBarFg, letterSpacing: -0.5),
        ),
        backgroundColor: _scaffoldBg,
        foregroundColor: _appBarFg,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _appBarFg),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileSnapshotCard(
              context: context,
              nombreCompleto: nombreCompleto.isEmpty ? 'Usuario' : nombreCompleto,
              username: username,
              fotoUrl: fotoUrl,
            ),
            const SizedBox(height: 24),

            _buildSectionHeader('Cuenta y Seguridad'),
            const SizedBox(height: 8),
            _buildSectionCard(context, [
              {
                'icon': Icons.manage_accounts,
                'bgIcon': _primaryFixed,
                'colorIcon': _primary,
                'title': 'Cuenta',
                'subtitle': 'Número, correo y privacidad personal',
                'onTap': () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PerfilView()),
                    ),
              },
              {
                'icon': Icons.key,
                'bgIcon': _secondaryFixed,
                'colorIcon': _secondary,
                'title': 'Seguridad',
                'subtitle': 'Correo y contraseña',
                'onTap': () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SeguridadView()),
                    ),
              },
            ]),
            const SizedBox(height: 24),

            _buildSectionHeader('Ajustes de la Aplicación'),
            const SizedBox(height: 8),
            _buildSectionCard(context, [
              {
                'icon': Icons.notifications_active,
                'bgIcon': _surfaceContainerHigh,
                'colorIcon': _primary,
                'title': 'Notificaciones y Sonidos',
                'subtitle': 'Tonos, alertas y vista previa en pantalla',
                'onTap': () => _proximamente(context),
              },
              {
                'icon': Icons.palette,
                'bgIcon': _surfaceContainerHigh,
                'colorIcon': _primary,
                'title': 'Apariencia y Tema',
                'subtitle': 'Claro, oscuro o automático',
                'onTap': () => _cambiarTema(context),
              },
              {
                'icon': Icons.translate,
                'bgIcon': _surfaceContainerHigh,
                'colorIcon': _primary,
                'title': 'Idioma',
                'subtitle': idiomaActual,
                'trailingText': idiomaCodigo,
                'onTap': () => _cambiarIdioma(context),
              },
            ]),
            const SizedBox(height: 24),

            _buildSectionHeader('Soporte y Comunidad'),
            const SizedBox(height: 8),
            _buildSectionCard(context, [
              {
                'icon': Icons.help_center,
                'bgIcon': _surfaceContainerLow,
                'colorIcon': _onSurface,
                'title': 'Centro de Ayuda',
                'subtitle': 'Preguntas frecuentes y contacto directo',
                'onTap': () => _proximamente(context),
              },
              {
                'icon': Icons.person_add,
                'bgIcon': _surfaceContainerLow,
                'colorIcon': _onSurface,
                'title': 'Invitar amigos',
                'subtitle': 'Comparte una invitación con cifrado mutuo',
                'onTap': () => _proximamente(context),
              },
              {
                'icon': Icons.verified_user,
                'bgIcon': _surfaceContainerLow,
                'colorIcon': _onSurface,
                'title': 'Términos y Privacidad',
                'subtitle': 'Políticas de datos cero registros',
                'onTap': () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TerminosView()),
                    ),
              },
            ]),
            const SizedBox(height: 24),

            _buildBotonCerrarSesion(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSnapshotCard({
    required BuildContext context,
    required String nombreCompleto,
    required String username,
    required String fotoUrl,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 1))],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(shape: BoxShape.circle, color: _surfaceContainerHigh),
                child: ClipOval(
                  child: fotoUrl.isNotEmpty
                      ? Image.network(fotoUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _avatarFallback())
                      : _avatarFallback(),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(color: _primaryContainer, shape: BoxShape.circle),
                  child: const Icon(Icons.verified, color: _onPrimary, size: 12),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nombreCompleto,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _onSurface, letterSpacing: -0.2)),
                const SizedBox(height: 2),
                Text(username.isEmpty ? '@usuario' : '@$username',
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: _onSurfaceVariant)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: _tertiaryFixedDim, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text('Identidad Cifrada', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _tertiary)),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PerfilView())),
            child: Container(
              width: 36,
              height: 36,
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback() {
    return Container(color: _surfaceContainerHigh, child: Icon(Icons.person, size: 32, color: _primary));
  }

  Widget _buildSectionHeader(String title, {String? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title.toUpperCase(),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _onSurfaceVariant, letterSpacing: 1.2)),
          if (trailing != null) Text(trailing, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _primary)),
        ],
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context, List<Map<String, dynamic>> items) {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 1))],
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _buildSectionItem(items[i]),
            if (i < items.length - 1)
              Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 16), color: _surfaceContainerLow),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionItem(Map<String, dynamic> item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item['onTap'] as VoidCallback?,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: item['bgIcon'], borderRadius: BorderRadius.circular(8)),
                child: Icon(item['icon'], color: item['colorIcon'], size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['title'], maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _onSurface)),
                    const SizedBox(height: 2),
                    Text(item['subtitle'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: _onSurfaceVariant)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (item['trailingText'] != null)
                Text(item['trailingText'], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _primary)),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right, color: _outline, size: 20),
            ],
          ),
        ),
      ),
    );
  }

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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: Icon(Icons.logout, size: 20, color: _error),
        label: Text('Cerrar Sesión', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _error)),
      ),
    );
  }

  Future<void> _cerrarSesion(BuildContext context) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Cerrar sesión"),
        content: const Text("¿Estás seguro que quieres cerrar sesión?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: _error, foregroundColor: _onError, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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