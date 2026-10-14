import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'views/auth/login_view.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/chat_viewmodel.dart';
import 'viewmodels/admin_viewmodel.dart';
import 'theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await themeController.cargarTema(); // carga el tema guardado antes de arrancar
  runApp(const TalkiaApp());
}

class TalkiaApp extends StatelessWidget {
  const TalkiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthViewModel()),
        ChangeNotifierProvider(create: (context) => ChatViewModel()),
        ChangeNotifierProvider(create: (_) => AdminViewModel()),
      ],
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeController.modeNotifier,
        builder: (context, modo, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Talkia',
            themeMode: modo,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF2A14B4),
                brightness: Brightness.light,
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF2A14B4),
                brightness: Brightness.dark,
              ),
            ),
            home: const LoginView(),
          );
        },
      ),
    );
  }
}