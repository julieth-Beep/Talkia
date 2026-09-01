import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'views/auth/login_view.dart';
import 'viewmodels/auth_viewmodel.dart'; 

void main() {
  runApp(const TalkiaApp());
}

class TalkiaApp extends StatelessWidget {
  const TalkiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider( 
      create: (context) => AuthViewModel(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Talkia',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const LoginView(), 
      ),
    );
  }
}