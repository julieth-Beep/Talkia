import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController {
  final ValueNotifier<ThemeMode> modeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.system);

  Future<void> cargarTema() async {
    final prefs = await SharedPreferences.getInstance();
    final guardado = prefs.getString('modoTema');
    if (guardado == 'claro') modeNotifier.value = ThemeMode.light;
    if (guardado == 'oscuro') modeNotifier.value = ThemeMode.dark;
    if (guardado == 'sistema') modeNotifier.value = ThemeMode.system;
  }

  Future<void> setMode(ThemeMode modo) async {
    modeNotifier.value = modo;
    final prefs = await SharedPreferences.getInstance();
    final nombre = modo == ThemeMode.light
        ? 'claro'
        : modo == ThemeMode.dark
            ? 'oscuro'
            : 'sistema';
    await prefs.setString('modoTema', nombre);
  }
}

// Instancia global que usa ConfigView
final themeController = ThemeController();