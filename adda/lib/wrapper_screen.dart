import 'package:adda/home_screen.dart';
import 'package:adda/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class WrapperScreen extends StatefulWidget {
  const WrapperScreen({super.key});

  @override
  State<WrapperScreen> createState() => _WrapperScreenState();
}

class _WrapperScreenState extends State<WrapperScreen> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return LoginScreen(isFromRecovery: true);
          //return MySocialHomepage();
        } else {
          //return MySocialHomepage();
          return LoginScreen(isFromRecovery: true);
        }
      },
    );
  }
}
