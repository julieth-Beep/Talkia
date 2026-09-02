// Conditional export: en Web usa el archivo _web.dart,
// en cualquier otra plataforma usa el _stub.dart (que no importa nada de JS).
export 'google_web_button_stub.dart'
    if (dart.library.html) 'google_web_button_web.dart';