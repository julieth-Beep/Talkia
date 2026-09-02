import 'package:flutter/material.dart';

// Versión "vacía" para Android/iOS — nunca se usa en la práctica
// porque el build ya filtra por kIsWeb, pero el compilador necesita
// que este archivo exista y compile en todas las plataformas.
Widget buildGoogleWebButton() {
  return const SizedBox.shrink();
}