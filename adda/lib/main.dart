import 'package:adda/home_screen.dart';
import 'package:adda/login_screen.dart';
import 'package:adda/signup_screen.dart';
import 'package:adda/wrapper_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auth UI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: false),
      initialRoute: '/',
      routes: {
        '/': (_) => const WrapperScreen(),
        '/home': (_) => const MySocialHomepage(),
        '/login': (_) => const LoginScreen(isFromRecovery: false),
        '/signup': (_) => const SignUpScreen(),
      },
    );
  }
}
