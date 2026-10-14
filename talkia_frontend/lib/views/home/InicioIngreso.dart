import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../chat/ListaConversacionesView.dart';
import '../../views/perfil/Configuracion.dart';
import '../../data/services/Traduccion_Service.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../auth/login_view.dart';

class InicioIngresoView extends StatefulWidget {
  const InicioIngresoView({super.key});

  @override
  State<InicioIngresoView> createState() => _InicioIngresoViewState();
}

class _InicioIngresoViewState extends State<InicioIngresoView> {
  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _targetController = TextEditingController();

  String _sourceLang = 'Español';
  String _targetLang = 'Inglés';

  bool _showConfigMenu = false;
  bool _showProfileMenu = false;
  bool _traduciendo = false;
  int _currentIndex = 0;

  // ─────────────── PALETA (claro = valores originales, oscuro = equivalentes) ───────────────
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _scaffoldBg => _isDark ? const Color(0xFF121316) : const Color(0xFFF8F9FA);
  Color get _accent => _isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4F46E5); // acento indigo
  Color get _onSurface => _isDark ? const Color(0xFFE6E1E9) : const Color(0xFF1A1A1C);
  Color get _onSurfaceVariant => _isDark ? const Color(0xFFA1A1AA) : const Color(0xFF52525B);
  Color get _surfaceContainerLowest => _isDark ? const Color(0xFF1B1D24) : const Color(0xFFFFFFFF);
  Color get _surfaceContainer => _isDark ? const Color(0xFF1E2028) : const Color(0xFFFAFAFA);
  Color get _sourceCardBg => _isDark ? const Color(0xFF1B1D24) : const Color(0xFFFDFDFD);
  Color get _targetCardBg => _isDark
      ? const Color(0xFF4F46E5).withValues(alpha: 0.12)
      : const Color(0xFF4F46E5).withValues(alpha: 0.05);
  Color get _border => _isDark ? const Color(0xFF3F414D) : const Color(0xFFD4D4D8);
  Color get _divider => _isDark ? const Color(0xFF2A2D3A) : const Color(0xFFF4F4F5);
  Color get _handle => _isDark ? const Color(0xFF3A3D4A) : const Color(0xFFD4D4D8);
  Color get _error => _isDark ? const Color(0xFFFFB4AB) : const Color(0xFFBA1A1A);
  Color get _onError => _isDark ? const Color(0xFF690005) : const Color(0xFFFFFFFF);
  // ───────────────────────────────────────────────────────────────────────────────────────────

  final List<String> _languages = [
    'Español',
    'Inglés',
    'Francés',
    'Italiano',
    'Mandarín',
    'Portugués',
    'Alemán',
    'Japonés',
    'Ruso',
    'Coreano',
  ];

  @override
  void dispose() {
    _sourceController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  void _closeAllMenus() {
    setState(() {
      _showConfigMenu = false;
      _showProfileMenu = false;
    });
  }

  Future<void> _cerrarSesion() async {
    // Cerrar el menú primero
    setState(() => _showProfileMenu = false);

    // Confirmar con el usuario
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
              foregroundColor: _onError,
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
    if (!mounted) return;

    // Cerrar sesión en el ViewModel
    await context.read<AuthViewModel>().cerrarSesion();

    if (!mounted) return;

    // Navegar al login y limpiar todo el stack
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginView()),
      (route) => false,
    );
  }

  void _swapLanguages() {
    setState(() {
      final temp = _sourceLang;
      _sourceLang = _targetLang;
      _targetLang = temp;

      final tempText = _sourceController.text;
      _sourceController.text = _targetController.text;
      _targetController.text = tempText;
    });
  }

  void _clearSource() {
    setState(() {
      _sourceController.clear();
      _targetController.clear();
    });
  }

  void _traducir() async {
    final texto = _sourceController.text.trim();
    if (texto.isEmpty || _traduciendo) return;

    setState(() => _traduciendo = true);

    try {
      final resultado = await TraduccionService.traducir(
        texto: texto,
        idiomaDestino: _targetLang,
        idiomaOrigen: _sourceLang,
      );
      if (!mounted) return;
      setState(() {
        _targetController.text = resultado;
        _traduciendo = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _traduciendo = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al traducir: $e')));
    }
  }

  void _copiarTexto() {
    if (_targetController.text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _targetController.text));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Texto copiado'),
          backgroundColor: Color.fromARGB(255, 163, 159, 233),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showLanguageSelector({required bool isSource}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _LanguageBottomSheet(
        languages: _languages,
        selectedLang: isSource ? _sourceLang : _targetLang,
        onSelected: (lang) {
          setState(() {
            if (isSource) {
              _sourceLang = lang;
            } else {
              _targetLang = lang;
            }
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: _scaffoldBg,
      body: Stack(
        children: [
          // Overlay para cerrar menús al tocar fuera
          if (_showConfigMenu || _showProfileMenu)
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeAllMenus,
                child: Container(color: Colors.transparent),
              ),
            ),

          // Contenido principal
          SafeArea(
            child: Column(
              children: [
                _buildTopAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1024),
                      child: isMobile
                          ? _buildMobileLayout()
                          : _buildDesktopLayout(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom NavBar (solo móvil)
          if (isMobile) _buildBottomNavBar(),

          // Menú de configuración (TopAppBar)
          if (_showConfigMenu) _buildConfigOverlay(),

          // Dropdown de perfil (BottomNavBar)
          if (_showProfileMenu) _buildProfileDropdown(),
        ],
      ),
    );
  }

  // ==================== TOP APP BAR ====================
  Widget _buildTopAppBar() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: _scaffoldBg.withValues(alpha: 0.8),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.translate,
                  color: _accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Traductor',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ListaConversacionesView(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline,
                    color: _onSurfaceVariant,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showProfileMenu = false;
                    _showConfigMenu = !_showConfigMenu;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Icon(
                    Icons.more_vert,
                    color: _onSurfaceVariant,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== CONFIG MENU (TOP APP BAR) ====================
  Widget _buildConfigOverlay() {
    return Positioned(
      top: 70,
      right: 20,
      child: GestureDetector(
        onTap: () {},
        child: Container(
          width: 224,
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: _surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _border.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(-2, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _profileMenuItem(Icons.edit_outlined, 'Perfil', () {
                setState(() => _showConfigMenu = false);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ConfigView()),
                );
              }),
              _profileMenuItem(Icons.settings_outlined, 'Configuración', () {
                setState(() => _showProfileMenu = false);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ConfigView()),
                );
              }),
              _profileMenuItem(Icons.history_outlined, 'Mi Historial', () {
                setState(() => _showProfileMenu = false);
              }),
              _profileMenuItem(Icons.help_outline, 'Ayuda y Soporte', () {
                setState(() => _showProfileMenu = false);
              }),
              Divider(height: 1, color: _divider),
              _profileMenuItem(Icons.logout, 'Cerrar Sesión', () {
                _cerrarSesion();
              }, isDestructive: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _configMenuItem(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: _onSurfaceVariant),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: _onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== PROFILE DROPDOWN (BOTTOM NAV) ====================
  Widget _buildProfileDropdown() {
    return Positioned(
      bottom: 80 + MediaQuery.of(context).padding.bottom,
      right: 16,
      child: GestureDetector(),
    );
  }

  Widget _profileMenuItem(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    final color = isDestructive ? _error : _onSurface;
    final iconColor = isDestructive ? _error : _onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== MOBILE LAYOUT ====================
  Widget _buildMobileLayout() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        children: [
          _buildSourceColumn(),
          const SizedBox(height: 32),
          _buildSwapButton(vertical: true),
          const SizedBox(height: 32),
          _buildTargetColumn(),
        ],
      ),
    );
  }

  // ==================== DESKTOP LAYOUT ====================
  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildSourceColumn()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: _buildSwapButton(vertical: false),
        ),
        Expanded(child: _buildTargetColumn()),
      ],
    );
  }

  // ==================== SOURCE COLUMN ====================
  Widget _buildSourceColumn() {
    return Column(
      children: [
        _buildLanguageChip(
          language: _sourceLang,
          onTap: () => _showLanguageSelector(isSource: true),
        ),
        const SizedBox(height: 24),
        Stack(
          children: [
            Container(
              height: 350, // <-- ALTURA FIJA: ya no crece con el texto
              decoration: BoxDecoration(
                color: _sourceCardBg,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(-2, 8),
                  ),
                ],
                border: Border.all(
                  color: _sourceController.text.isNotEmpty
                      ? _accent.withValues(alpha: 0.2)
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: ListenableBuilder(
                  listenable: _sourceController,
                  builder: (context, child) {
                    return TextField(
                      controller: _sourceController,
                      maxLines: null,
                      style: TextStyle(
                        fontSize: 22,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                        color: _onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Escribe algo para traducir...',
                        hintStyle: TextStyle(
                          color: _onSurfaceVariant,
                          fontWeight: FontWeight.w400,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (_) => setState(() {}),
                      cursorColor: _accent,
                    );
                  },
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _surfaceContainer,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _actionButton(Icons.close, 'Limpiar', _clearSource),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _traduciendo ? null : _traducir,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              disabledBackgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                ),
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4F46E5).withValues(alpha: 0.25),
                    blurRadius: 30,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
              child: _traduciendo
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Traducir',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  // ==================== TARGET COLUMN ====================
  Widget _buildTargetColumn() {
    return Column(
      children: [
        _buildLanguageChip(
          language: _targetLang,
          onTap: () => _showLanguageSelector(isSource: false),
        ),
        const SizedBox(height: 24),
        Container(
          height: 350, // <-- ALTURA FIJA: ya no se encoge con el texto
          decoration: BoxDecoration(
            color: _targetCardBg,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(-2, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Stack(
            children: [
              // Texto con scroll, alineado arriba
              Positioned.fill(
                child: SingleChildScrollView(
                  child: ListenableBuilder(
                    listenable: _targetController,
                    builder: (context, child) {
                      return Text(
                        _targetController.text.isEmpty
                            ? 'La traducción aparecerá aquí...'
                            : _targetController.text,
                        style: TextStyle(
                          fontSize: 22,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                          color: _targetController.text.isEmpty
                              ? _onSurfaceVariant.withValues(alpha: 0.8)
                              : _onSurface,
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Botones de acción siempre abajo a la derecha
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _actionButton(Icons.content_copy, 'Copiar', _copiarTexto),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== LANGUAGE CHIP ====================
  Widget _buildLanguageChip({
    required String language,
    required VoidCallback onTap,
  }) {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: _surfaceContainerLowest,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: _border.withValues(alpha: 0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  language,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 20,
                  color: _onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== SWAP BUTTON ====================
  Widget _buildSwapButton({required bool vertical}) {
    return GestureDetector(
      onTap: _swapLanguages,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surfaceContainerLowest,
          shape: BoxShape.circle,
          border: Border.all(
            color: _border.withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Icon(
          vertical ? Icons.swap_vert : Icons.swap_horiz,
          size: 28,
          color: _accent,
        ),
      ),
    );
  }

  // ==================== ACTION BUTTON ====================
  Widget _actionButton(IconData icon, String tooltip, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(999)),
        child: Icon(icon, size: 20, color: _onSurfaceVariant),
      ),
    );
  }

  // ==================== BOTTOM NAV BAR ====================
  Widget _buildBottomNavBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 80 + MediaQuery.of(context).padding.bottom,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: _surfaceContainerLowest.withValues(alpha: 0.9),
              border: Border(
                top: BorderSide(
                  color: _border.withValues(alpha: 0.1),
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(
                  icon: Icons.translate,
                  label: 'Inicio',
                  isActive: _currentIndex == 0,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                _navItem(
                  icon: Icons.history,
                  label: 'Historial',
                  isActive: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                _navItem(
                  icon: Icons.chat_bubble_outline,
                  label: 'Chat',
                  isActive: false,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ListaConversacionesView(),
                      ),
                    );
                  },
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ConfigView(),
                      ),
                    );
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _currentIndex == 2
                              ? _accent.withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _showProfileMenu
                              ? Icons.person
                              : Icons.person_outline,
                          size: 24,
                          color: _currentIndex == 2
                              ? _accent
                              : _onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Perfil',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: _currentIndex == 2
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: _currentIndex == 2
                              ? _accent
                              : _onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final activeColor = _accent;
    final inactiveColor = _onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isActive
                  ? activeColor.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 24,
              color: isActive ? activeColor : inactiveColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: isActive ? activeColor : inactiveColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== LANGUAGE BOTTOM SHEET ====================
class _LanguageBottomSheet extends StatelessWidget {
  final List<String> languages;
  final String selectedLang;
  final ValueChanged<String> onSelected;

  const _LanguageBottomSheet({
    required this.languages,
    required this.selectedLang,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? const Color(0xFF1B1D24) : const Color(0xFFFFFFFF);
    final handle = isDark ? const Color(0xFF3A3D4A) : const Color(0xFFD4D4D8);
    final titleColor = isDark ? const Color(0xFFE6E1E9) : const Color(0xFF1A1A1C);
    final dividerColor = isDark ? const Color(0xFF2A2D3A) : const Color(0xFFF4F4F5);
    final accent = isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4F46E5);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
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
              color: handle,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Seleccionar idioma',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
            ),
          ),
          Divider(height: 1, color: dividerColor),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: languages.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                indent: 20,
                endIndent: 20,
                color: dividerColor,
              ),
              itemBuilder: (context, index) {
                final lang = languages[index];
                final isSelected = lang == selectedLang;
                return InkWell(
                  onTap: () => onSelected(lang),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        if (isSelected)
                          Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: Icon(
                              Icons.check,
                              color: accent,
                              size: 20,
                            ),
                          )
                        else
                          const SizedBox(width: 36),
                        Text(
                          lang,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isSelected ? accent : titleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}