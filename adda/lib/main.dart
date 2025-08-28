// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:adda/forgotten_password.dart';
import 'package:adda/home_screen.dart';
import 'package:adda/login_screen.dart';
import 'package:adda/signup_screen.dart';
import 'package:adda/wrapper_screen.dart';

import 'firebase_options.dart'; // FlutterFire CLI generated

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize Firebase exactly once (guarded)
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else {
      Firebase.app(); // reuse existing default app
    }
  } on FirebaseException catch (e) {
    // Hot restart এর সময় যদি already initialized থাকে, duplicate-app এলে ইগনোর
    if (e.code != 'duplicate-app') rethrow;
  }

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
        '/forgot-password': (_) => const ForgotPasswordScreen(),
      },
    );
  }
}
