import 'package:adda/home_screen.dart';
import 'package:adda/login_screen.dart';
import 'package:adda/providers/feed_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WrapperScreen extends StatelessWidget {
  const WrapperScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1) Connecting/Waiting state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2) Logged-in state
        final user = snapshot.data;
        if (user != null) {
          // এখানে FeedProvider ইনিশিয়ালাইজ করে রিয়েলটাইম ফিড লিসেনার চালু করছি
          return ChangeNotifierProvider(
            create: (_) {
              final fp = FeedProvider(currentUserId: user.uid);
              fp.start(); // friends + own + trending listeners
              return fp;
            },
            child: const MySocialHomepage(),
          );
        }

        // 3) Logged-out state
        return const LoginScreen(isFromRecovery: false);
      },
    );
  }
}
