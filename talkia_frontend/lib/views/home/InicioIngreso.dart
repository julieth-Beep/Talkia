import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../chat/ListaConversacionesView.dart';
import '../../data/services/Traduccion_Service.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al traducir: $e')),
      );
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
      backgroundColor: const Color(0xFFF8F9FA),
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
        color: const Color(0xFFF8F9FA).withValues(alpha: 0.8),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.translate,
                  color: Color(0xFF4F46E5),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Traductor',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1C),
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
                  child: const Icon(
                    Icons.chat_bubble_outline,
                    color: Color(0xFF52525B),
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
                  child: const Icon(
                    Icons.more_vert,
                    color: Color(0xFF52525B),
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
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFD4D4D8).withValues(alpha: 0.2),
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
              _configMenuItem(Icons.edit, 'Editar Perfil', () {
                setState(() => _showConfigMenu = false);
              }),
              _configMenuItem(Icons.settings, 'Configuración', () {
                setState(() => _showConfigMenu = false);
              }),
              _configMenuItem(Icons.history, 'Historial', () {
                setState(() => _showConfigMenu = false);
              }),
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: const Color(0xFFD4D4D8).withValues(alpha: 0.3),
              ),
              _configMenuItem(Icons.help_outline, 'Ayuda', () {
                setState(() => _showConfigMenu = false);
              }),
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
            Icon(icon, size: 20, color: const Color(0xFF52525B)),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1A1C),
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
      child: GestureDetector(
        onTap: () {},
        child: Container(
          width: 240,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFD4D4D8).withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Color(0xFF4F46E5),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mi Usuario',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1C),
                            ),
                          ),
                          Text(
                            'usuario@email.com',
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(
                                0xFF52525B,
                              ).withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF4F4F5)),
              _profileMenuItem(Icons.edit_outlined, 'Editar Perfil', () {
                setState(() => _showProfileMenu = false);
              }),
              _profileMenuItem(Icons.settings_outlined, 'Configuración', () {
                setState(() => _showProfileMenu = false);
              }),
              _profileMenuItem(Icons.history_outlined, 'Mi Historial', () {
                setState(() => _showProfileMenu = false);
              }),
              _profileMenuItem(Icons.help_outline, 'Ayuda y Soporte', () {
                setState(() => _showProfileMenu = false);
              }),
              const Divider(height: 1, color: Color(0xFFF4F4F5)),
              _profileMenuItem(Icons.logout, 'Cerrar Sesión', () {
                setState(() => _showProfileMenu = false);
                // TODO: Implementar cerrar sesión
              }, isDestructive: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileMenuItem(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    final color = isDestructive
        ? const Color(0xFFBA1A1A)
        : const Color(0xFF1A1A1C);
    final iconColor = isDestructive
        ? const Color(0xFFBA1A1A)
        : const Color(0xFF52525B);

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
                color: const Color(0xFFFDFDFD),
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
                      ? const Color(0xFF4F46E5).withValues(alpha: 0.2)
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
                      style: const TextStyle(
                        fontSize: 22,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A1A1C),
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Escribe algo para traducir...',
                        hintStyle: TextStyle(
                          color: Color(0xFF52525B),
                          fontWeight: FontWeight.w400,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (_) => setState(() {}),
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
                  color: const Color(0xFFFAFAFA),
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
                        Icon(Icons.arrow_forward, color: Colors.white, size: 20),
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
            color: const Color(0xFF4F46E5).withValues(alpha: 0.05),
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
                              ? const Color(0xFF52525B).withValues(alpha: 0.8)
                              : const Color(0xFF1A1A1C),
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
                    color: const Color(0xFFFFFFFF),
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
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: const Color(0xFFD4D4D8).withValues(alpha: 0.1),
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
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1C),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 20,
                  color: Color(0xFF52525B),
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
          color: const Color(0xFFFFFFFF),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFFD4D4D8).withValues(alpha: 0.1),
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
          color: const Color(0xFF4F46E5),
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
        child: Icon(icon, size: 20, color: const Color(0xFF52525B)),
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
              color: const Color(0xFFFFFFFF).withValues(alpha: 0.9),
              border: Border(
                top: BorderSide(
                  color: const Color(0xFFD4D4D8).withValues(alpha: 0.1),
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
                    setState(() {
                      _showConfigMenu = false;
                      _showProfileMenu = !_showProfileMenu;
                      _currentIndex = 2;
                    });
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _currentIndex == 2
                              ? const Color(0xFF4F46E5).withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _showProfileMenu
                              ? Icons.person
                              : Icons.person_outline,
                          size: 24,
                          color: _currentIndex == 2
                              ? const Color(0xFF4F46E5)
                              : const Color(0xFF52525B),
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
                              ? const Color(0xFF4F46E5)
                              : const Color(0xFF52525B),
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
    const activeColor = Color(0xFF4F46E5);
    const inactiveColor = Color(0xFF52525B);

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
    return Container(
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
              'Seleccionar idioma',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1C),
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF4F4F5)),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: languages.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                indent: 20,
                endIndent: 20,
                color: Color(0xFFF4F4F5),
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
                          const Padding(
                            padding: EdgeInsets.only(right: 16),
                            child: Icon(
                              Icons.check,
                              color: Color(0xFF4F46E5),
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
                            color: isSelected
                                ? const Color(0xFF4F46E5)
                                : const Color(0xFF1A1A1C),
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