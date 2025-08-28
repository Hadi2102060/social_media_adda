import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _errorMessage = '';
  String _successMessage = '';

  Future<void> _resetPassword() async {
    setState(() {
      _errorMessage = '';
      _successMessage = '';
    });

    try {
      print(
        'Attempting to send reset email to: ${_emailController.text.trim()}',
      );
      await _auth.sendPasswordResetEmail(email: _emailController.text.trim());
      setState(() {
        _successMessage = 'পাসওয়ার্ড রিসেট লিঙ্ক আপনার ইমেলে পাঠানো হয়েছে।';
      });
      print('Reset email sent successfully.');
    } on FirebaseAuthException catch (e) {
      print('Error occurred: ${e.code} - ${e.message}');
      setState(() {
        if (e.code == 'user-not-found') {
          _errorMessage = 'এই ইমেল দিয়ে কোনো অ্যাকাউন্ট পাওয়া যায়নি।';
        } else if (e.code == 'invalid-email') {
          _errorMessage = 'অবৈধ ইমেল ঠিকানা।';
        } else if (e.code == 'too-many-requests') {
          _errorMessage = 'অনেকগুলো অনুরোধ, পরে আবার চেষ্টা করুন।';
        } else {
          _errorMessage = 'একটি ত্রুটি ঘটেছে। আবার চেষ্টা করুন।';
        }
      });
    } catch (e) {
      print('Unexpected error: $e');
      setState(() {
        _errorMessage = 'অপ্রত্যাশিত ত্রুটি। সাপোর্টের সাথে যোগাযোগ করুন।';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('পাসওয়ার্ড ভুলে গেছেন?'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'আপনার ইমেল ঠিকানা লিখুন। আমরা আপনাকে পাসওয়ার্ড রিসেট করার জন্য একটি লিঙ্ক পাঠাব।',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'ইমেল',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _resetPassword,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 50,
                  vertical: 15,
                ),
                backgroundColor: Colors.blueAccent,
              ),
              child: const Text(
                'রিসেট লিঙ্ক পাঠান',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            if (_successMessage.isNotEmpty)
              Text(
                _successMessage,
                style: const TextStyle(color: Colors.green, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            if (_errorMessage.isNotEmpty)
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
