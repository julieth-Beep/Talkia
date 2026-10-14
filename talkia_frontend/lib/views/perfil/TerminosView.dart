import 'package:flutter/material.dart';

class TerminosView extends StatelessWidget {
  const TerminosView({super.key});

  static const _terminos = '''
TÉRMINOS Y CONDICIONES DE TALKIA

1. Aceptación
Al usar Talkia aceptas estos términos.

2. Cuenta
Eres responsable de mantener la confidencialidad de tu contraseña.

3. Uso aceptable
No puedes usar Talkia para actividades ilegales o spam.

4. Contenido
Conservas los derechos sobre tu contenido. Nos concedes una licencia para mostrarlo en la app.

5. Privacidad
Solo recopilamos los datos necesarios para el funcionamiento (correo, nombre, idioma).
No compartimos tu información con terceros sin tu consentimiento.

6. Terminación
Puedes eliminar tu cuenta en cualquier momento.
''';

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Términos y privacidad'),
          bottom: const TabBar(tabs: [
            Tab(text: 'Términos'),
            Tab(text: 'Privacidad'),
          ]),
        ),
        body: const TabBarView(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Text(_terminos),
            ),
            SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Text(
                'POLÍTICA DE PRIVACIDAD\n\n'
                'Datos que recopilamos: correo, nombre, apellido, idioma preferido '
                'y foto de perfil (opcional).\n\n'
                'Uso: autenticación, personalización y funcionamiento del chat.\n\n'
                'No vendemos ni compartimos tus datos con terceros.\n\n'
                'Puedes solicitar la eliminación de tu cuenta y datos en '
                'cualquier momento escribiendo a privacidad@talkia.app.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}