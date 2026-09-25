import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../views/perfil/Perfil.dart';
import '../auth/login_view.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

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

  // ═══════════════ COLORES DEL DESIGN SYSTEM ═══════════════
  static const Color _surface = Color(0xFFF8F9FF);
  static const Color _onSurface = Color(0xFF0B1C30);
  static const Color _onSurfaceVariant = Color(0xFF464554);
  static const Color _outline = Color(0xFF777586);
  static const Color _primary = Color(0xFF2A14B4);
  static const Color _primaryContainer = Color(0xFF4338CA);
  static const Color _onPrimary = Color(0xFFFFFFFF);
  static const Color _primaryFixed = Color(0xFFE3DFFF);
  static const Color _secondary = Color(0xFF0051D5);
  static const Color _secondaryFixed = Color(0xFFDBE1FF);
  static const Color _tertiary = Color(0xFF00423C);
  static const Color _tertiaryContainer = Color(0xFF005C54);
  static const Color _tertiaryFixed = Color(0xFF89F5E7);
  static const Color _tertiaryFixedDim = Color(0xFF6BD8CB);
  static const Color _surfaceContainerLow = Color(0xFFEFF4FF);
  static const Color _surfaceContainerHigh = Color(0xFFDCE9FF);
  static const Color _surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color _error = Color(0xFFBA1A1A);
  static const Color _errorContainer = Color(0xFFFFDAD6);

  // ═══════════════ ESTADO ═══════════════
  bool _showConfigMenu = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final usuario = auth.usuario;

    final nombreCompleto = '${usuario?.nombre ?? ''} ${usuario?.apellido ?? ''}'
        .trim();
    final username = usuario?.username ?? '';
    final correo = usuario?.correo ?? '';
    final fotoUrl = _completarUrl(usuario?.fotoUrl ?? '');

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Configuración',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ═══════════════ PERFIL SNAPSHOT (BENTO CARD) ═══════════════
            _buildProfileSnapshotCard(
              nombreCompleto: nombreCompleto.isEmpty
                  ? 'Usuario'
                  : nombreCompleto,
              username: username,
              fotoUrl: fotoUrl,
            ),
            const SizedBox(height: 24),

            // ═══════════════ CUENTA Y SEGURIDAD ═══════════════
            _buildSectionHeader('Cuenta y Seguridad', trailing: 'Protegida'),
            const SizedBox(height: 8),
            _buildSectionCard([
              {
                'icon': Icons.manage_accounts,
                'bgIcon': _primaryFixed,
                'colorIcon': _primary,
                'title': 'Cuenta',
                'subtitle': 'Número, correo y privacidad personal',
              },
              {
                'icon': Icons.key,
                'bgIcon': _secondaryFixed,
                'colorIcon': _secondary,
                'title': 'Seguridad y Llaves',
                'subtitle': 'Biometría y 3 sesiones activas',
                'badge': '2FA ON',
              },
              {
                'icon': Icons.lock,
                'bgIcon': _tertiaryFixed,
                'colorIcon': _tertiaryContainer,
                'title': 'Privacidad',
                'subtitle': 'Última vez, foto de perfil, confirmaciones',
              },
            ]),
            const SizedBox(height: 24),

            // ═══════════════ AJUSTES DE LA APLICACIÓN ═══════════════
            _buildSectionHeader('Ajustes de la Aplicación'),
            const SizedBox(height: 8),
            _buildSectionCard([
              {
                'icon': Icons.notifications_active,
                'bgIcon': _surfaceContainerHigh,
                'colorIcon': _primary,
                'title': 'Notificaciones y Sonidos',
                'subtitle': 'Tonos, alertas y vista previa en pantalla',
              },
              {
                'icon': Icons.cloud_sync,
                'bgIcon': _surfaceContainerHigh,
                'colorIcon': _primary,
                'title': 'Chats y Almacenamiento',
                'subtitle': 'Copia cifrada en la nube y uso de datos',
                'trailing': '1.2 GB',
              },
              {
                'icon': Icons.palette,
                'bgIcon': _surfaceContainerHigh,
                'colorIcon': _primary,
                'title': 'Apariencia y Tema',
                'subtitle': 'Automático, tamaño tipográfico e índigo',
                'trailingDot': true,
              },
              {
                'icon': Icons.translate,
                'bgIcon': _surfaceContainerHigh,
                'colorIcon': _primary,
                'title': 'Idioma',
                'subtitle': 'Español (España)',
                'trailingText': 'ES',
              },
            ]),
            const SizedBox(height: 24),

            // ═══════════════ SOPORTE Y COMUNIDAD ═══════════════
            _buildSectionHeader('Soporte y Comunidad'),
            const SizedBox(height: 8),
            _buildSectionCard([
              {
                'icon': Icons.help_center,
                'bgIcon': _surfaceContainerLow,
                'colorIcon': _onSurface,
                'title': 'Centro de Ayuda',
                'subtitle': 'Preguntas frecuentes y contacto directo',
              },
              {
                'icon': Icons.person_add,
                'bgIcon': _surfaceContainerLow,
                'colorIcon': _onSurface,
                'title': 'Invitar amigos',
                'subtitle': 'Comparte una invitación con cifrado mutuo',
              },
              {
                'icon': Icons.verified_user,
                'bgIcon': _surfaceContainerLow,
                'colorIcon': _onSurface,
                'title': 'Términos y Privacidad',
                'subtitle': 'Políticas de datos cero registros',
              },
            ]),
            const SizedBox(height: 24),

            // ═══════════════ CERRAR SESIÓN ═══════════════
            _buildBotonCerrarSesion(context),

            // ═══════════════ FOOTER ═══════════════
            const SizedBox(height: 16),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  PERFIL SNAPSHOT CARD
  // ═══════════════════════════════════════════════════════
  Widget _buildProfileSnapshotCard({
    required String nombreCompleto,
    required String username,
    required String fotoUrl,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Row(
            children: [
              // Foto con badge verificado
              Stack(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _surfaceContainerHigh,
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
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: _primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified,
                        color: _onPrimary,
                        size: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Nombre + username + badge
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombreCompleto,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _onSurface,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      username.isEmpty ? '@usuario' : '@$username',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: _tertiaryFixedDim,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Identidad Cifrada',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _tertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Botón editar
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PerfilView()),
                  );
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _surfaceContainerLow,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit, color: _primary, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildQuickButton({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: _surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: _primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback() {
    return Container(
      color: _surfaceContainerHigh,
      child: const Icon(Icons.person, size: 32, color: _primary),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  SECTION HEADER
  // ═══════════════════════════════════════════════════════
  Widget _buildSectionHeader(String title, {String? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _onSurfaceVariant,
              letterSpacing: 1.2,
            ),
          ),
          if (trailing != null)
            Text(
              trailing,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: _primary,
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  SECTION CARD (lista de items)
  // ═══════════════════════════════════════════════════════
  Widget _buildSectionCard(List<Map<String, dynamic>> items) {
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
            _buildSectionItem(items[i]),
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

  Widget _buildSectionItem(Map<String, dynamic> item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icono
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: item['bgIcon'],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(item['icon'], color: item['colorIcon'], size: 20),
              ),
              const SizedBox(width: 12),

              // Textos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item['title'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _onSurface,
                            ),
                          ),
                        ),
                        if (item['badge'] != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              item['badge'],
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item['subtitle'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Trailing
              if (item['trailing'] != null)
                Text(
                  item['trailing'],
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _onSurfaceVariant,
                  ),
                ),
              if (item['trailingText'] != null)
                Text(
                  item['trailingText'],
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _primary,
                  ),
                ),
              if (item['trailingDot'] == true)
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: _primaryContainer,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, color: _outline, size: 20),
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
  //  FOOTER
  // ═══════════════════════════════════════════════════════
  Widget _buildFooter() {
    return Column(children: [
        
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  //  CERRAR SESIÓN
  // ═══════════════════════════════════════════════════════
  Future<void> _cerrarSesion(BuildContext context) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
