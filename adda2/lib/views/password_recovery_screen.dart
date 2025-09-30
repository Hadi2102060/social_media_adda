import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <-- add this
import 'package:adda2/views/signin_screen.dart';

class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen({super.key});

  @override
  State<PasswordRecoveryScreen> createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _backgroundController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _backgroundAnimation;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _backgroundController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
    _backgroundController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _backgroundController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    final email = _emailController.text.trim();

    try {
      // Sends the real password reset email using Firebase Auth
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;
      _showSuccessDialog(email);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String msg = 'Failed to send reset email.';
      switch (e.code) {
        case 'invalid-email':
          msg = 'This email address is invalid.';
          break;
        case 'user-not-found':
          msg = 'No user found for this email.';
          break;
        case 'missing-android-pkg-name':
        case 'missing-continue-uri':
        case 'invalid-continue-uri':
        case 'unauthorized-continue-uri':
          msg = 'Reset link configuration error. Please contact support.';
          break;
        case 'network-request-failed':
          msg = 'Network error. Check your connection and try again.';
          break;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.redAccent, content: Text(msg)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('Something went wrong. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.email, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 20),
              const Text(
                'Email Sent!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                'We sent a password reset link to:\n$email',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              const Text(
                'Open your inbox and follow the link to set a new password.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const SigninScreen()),
                    (_) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'Back to Sign In',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Animated Background
          AnimatedBuilder(
            animation: _backgroundAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.lerp(
                        Colors.teal.shade400,
                        Colors.teal.shade500,
                        _backgroundAnimation.value,
                      )!,
                      Color.lerp(
                        Colors.cyan.shade400,
                        Colors.cyan.shade500,
                        _backgroundAnimation.value,
                      )!,
                      Color.lerp(
                        Colors.blue.shade400,
                        Colors.blue.shade500,
                        _backgroundAnimation.value,
                      )!,
                      Color.lerp(
                        Colors.indigo.shade400,
                        Colors.indigo.shade500,
                        _backgroundAnimation.value,
                      )!,
                    ],
                    stops: const [0.0, 0.3, 0.7, 1.0],
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.2,
                      colors: [
                        Colors.white.withOpacity(0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // small floating particles (kept)
          Positioned(
            top: 120,
            left: 30,
            child: AnimatedBuilder(
              animation: _backgroundController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    25 * _backgroundAnimation.value,
                    10 * _backgroundAnimation.value,
                  ),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 200,
            right: 50,
            child: AnimatedBuilder(
              animation: _backgroundController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    -20 * _backgroundAnimation.value,
                    15 * _backgroundAnimation.value,
                  ),
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: 200,
            left: 80,
            child: AnimatedBuilder(
              animation: _backgroundController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    15 * _backgroundAnimation.value,
                    -20 * _backgroundAnimation.value,
                  ),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.25),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: 150,
            right: 30,
            child: AnimatedBuilder(
              animation: _backgroundController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    -10 * _backgroundAnimation.value,
                    25 * _backgroundAnimation.value,
                  ),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.15),
                    ),
                  ),
                );
              },
            ),
          ),

          // Main Content
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                24 + bottomInset,
              ), // keyboard-aware
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),

                    // Lock Icon with Animation
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                spreadRadius: 5,
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.lock_reset,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Title
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: const Text(
                        'Forgot Password?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 2),
                              blurRadius: 4,
                              color: Colors.black26,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Description
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        'Don\'t worry! It happens. Please enter the email address associated with your account.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.5,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 2,
                              color: Colors.black26,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Email Field + Submit
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                spreadRadius: 5,
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildEmailField(),
                              const SizedBox(height: 32),
                              _buildSubmitButton(), // calls _sendResetEmail()
                              const SizedBox(height: 24),

                              // Back to Sign In
                              FadeTransition(
                                opacity: _fadeAnimation,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Remember your password? ',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const SigninScreen(),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        'Sign In',
                                        style: TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 40),

                              // Additional Help
                              FadeTransition(
                                opacity: _fadeAnimation,
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.help_outline,
                                        color: Colors.blue,
                                        size: 30,
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Need Help?',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'If you\'re still having trouble, contact our support team.',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton(
                                        onPressed: () {
                                          // open support page / email composer
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          foregroundColor: Colors.blue,
                                          elevation: 0,
                                          side: const BorderSide(
                                            color: Colors.blue,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        child: const Text('Contact Support'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter your email';
          }
          if (!RegExp(
            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
          ).hasMatch(value.trim())) {
            return 'Please enter a valid email';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: 'Email Address',
          prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blue, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _sendResetEmail,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Send Reset Link',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
