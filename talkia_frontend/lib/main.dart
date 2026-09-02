import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'views/auth/login_view.dart';
import 'viewmodels/auth_viewmodel.dart'; 
import 'viewmodels/chat_viewmodel.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Talkia',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const LoginView(),
      ),
    );
  }
}