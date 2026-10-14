import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../data/services/Usuario_Service.dart';

class SeguridadView extends StatefulWidget {
  const SeguridadView({super.key});

  @override
  State<SeguridadView> createState() => _SeguridadViewState();
}

class _SeguridadViewState extends State<SeguridadView> {
  bool _cargando = false;

  // ───────────────────────── PALETA ─────────────────────────
  // En CLARO: mismos valores de antes. En OSCURO: equivalentes.
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _onSurface => _isDark ? const Color(0xFFE6E1E9) : const Color(0xFF0B1C30);
  Color get _onSurfaceVariant => _isDark ? const Color(0xFFC6C4D0) : const Color(0xFF464554);
  Color get _outline => _isDark ? const Color(0xFF918FA0) : const Color(0xFF777586);
  Color get _primary => _isDark ? const Color(0xFFBFC3FF) : const Color(0xFF2A14B4);
  Color get _primaryFixed => _isDark ? const Color(0xFF2E2E6E) : const Color(0xFFE3DFFF);
  Color get _secondary => _isDark ? const Color(0xFFA9C7FF) : const Color(0xFF0051D5);
  Color get _secondaryFixed => _isDark ? const Color(0xFF233A66) : const Color(0xFFDBE1FF);
  Color get _surfaceContainerLow => _isDark ? const Color(0xFF2A2D3A) : const Color(0xFFEFF4FF);
  Color get _surfaceContainerLowest => _isDark ? const Color(0xFF1B1D24) : Colors.white;
  Color get _scaffoldBg => _isDark ? const Color(0xFF121316) : const Color(0xFFF8F9FA);
  Color get _appBarFg => _isDark ? const Color(0xFFE6E1E9) : const Color(0xFF1A1A1C);
  // Botones rellenos (fondo marca + texto blanco en ambos modos)
  Color get _botonPrimario => _isDark ? const Color(0xFF4338CA) : const Color(0xFF2A14B4);
  // ───────────────────────────────────────────────────────────

  // ───────────────────────── CORREO ─────────────────────────

  Future<void> _cambiarCorreo() async {
    final auth = context.read<AuthViewModel>();
    final usuario = auth.usuario;
    if (usuario == null) return;

    final controller = TextEditingController(text: usuario.correo);
    final nuevo = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cambiar correo'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Nuevo correo',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _botonPrimario,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (nuevo == null || nuevo.isEmpty || nuevo == usuario.correo) return;
    if (!context.mounted) return;

    setState(() => _cargando = true);
    try {
      await UsuarioService.actualizarDatosPersonales(
        usuarioId: usuario.id!,
        correo: nuevo,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Correo actualizado')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // ─────────────────────── CONTRASEÑA ───────────────────────

  Future<void> _flujoContrasena() async {
    final auth = context.read<AuthViewModel>();
    final usuario = auth.usuario;
    if (usuario == null) return;

    // Paso 1: confirmar envío de código
    final enviar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Verificación necesaria'),
        content: Text(
            'Te enviaremos un código de verificación a ${usuario.correo} para cambiar tu contraseña.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _botonPrimario,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enviar código'),
          ),
        ],
      ),
    );
    if (enviar != true || !context.mounted) return;

    setState(() => _cargando = true);
    try {
      await UsuarioService.solicitarRecuperacion(correo: usuario.correo);
    } catch (e) {
      if (mounted) {
        setState(() => _cargando = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
      return;
    }
    if (mounted) setState(() => _cargando = false);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Código enviado a tu correo')),
    );

    // Paso 2: insertar el código
    final codigo = await _pedirTexto(
      titulo: 'Ingresa el código',
      label: 'Código de verificación',
      keyboardType: TextInputType.number,
    );
    if (codigo == null || codigo.isEmpty) return;

    // Paso 3: nueva contraseña (con toggle para verla)
    final nueva = await _pedirNuevaContrasena();
    if (nueva == null || nueva.isEmpty) return;
    if (!context.mounted) return;

    setState(() => _cargando = true);
    try {
      await UsuarioService.restablecerContrasena(
        correo: usuario.correo,
        token: codigo,
        nuevaPassword: nueva,
      );
      if (!mounted) return;

      // Paso 4: mostrar la contraseña final
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Contraseña actualizada'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tu nueva contraseña es:'),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  nueva,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<String?> _pedirTexto({
    required String titulo,
    required String label,
    TextInputType keyboardType = TextInputType.text,
  }) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(titulo),
        content: TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _botonPrimario,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  Future<String?> _pedirNuevaContrasena() async {
    final controller = TextEditingController();
    bool visible = false;

    return showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Nueva contraseña'),
          content: TextField(
            controller: controller,
            obscureText: !visible,
            decoration: InputDecoration(
              labelText: 'Nueva contraseña',
              suffixIcon: IconButton(
                icon: Icon(visible ? Icons.visibility : Icons.visibility_off),
                onPressed: () =>
                    setDialogState(() => visible = !visible),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _botonPrimario,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────── UI ───────────────────────────

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthViewModel>().usuario;

    return Scaffold(
      backgroundColor: _scaffoldBg,
      appBar: AppBar(
        title: Text(
          'Seguridad',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _appBarFg,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: _scaffoldBg,
        foregroundColor: _appBarFg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _appBarFg),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'INICIO DE SESIÓN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _onSurfaceVariant,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
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
                        _item(
                          icon: Icons.email_outlined,
                          bgIcon: _primaryFixed,
                          colorIcon: _primary,
                          title: 'Correo',
                          subtitle: usuario?.correo ?? '',
                          onTap: _cambiarCorreo,
                        ),
                        Container(
                          height: 1,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          color: _surfaceContainerLow,
                        ),
                        _item(
                          icon: Icons.password,
                          bgIcon: _secondaryFixed,
                          colorIcon: _secondary,
                          title: 'Contraseña',
                          subtitle: 'Ver o cambiar contraseña',
                          onTap: _flujoContrasena,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'Para ver o cambiar tu contraseña te enviaremos un código de verificación a tu correo. Por seguridad, la contraseña nunca se muestra sin verificación.',
                      style: TextStyle(fontSize: 12, color: _onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _item({
    required IconData icon,
    required Color bgIcon,
    required Color colorIcon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: bgIcon,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: colorIcon, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: _onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: _outline, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}