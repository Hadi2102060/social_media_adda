import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'instagram_homepage.dart';
import 'password_recovery_screen.dart';
import 'signup_screen.dart';

class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen>
    with TickerProviderStateMixin {
  // ---------------- Colors (palette) ----------------
  static const Color kBgTop = Color(0xFF0B1220);
  static const Color kBgMid = Color(0xFF131A2D);
  static const Color kBgBottom = Color(0xFF1D2440);
  static const Color kAccent = Color(0xFF00D1FF);
  static const Color kAccent2 = Color(0xFF7C5CFF);

  // ---------------- Animations ----------------
  late final AnimationController _logoController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();
  late final Animation<double> _logoScale = CurvedAnimation(
    parent: _logoController,
    curve: Curves.easeOutBack,
  );

  late final AnimationController _bgController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 16),
  )..repeat();

  late final AnimationController _glowController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
    lowerBound: 0.0,
    upperBound: 1.0,
  )..repeat(reverse: true);

  // Shake when error
  late final AnimationController _shakeCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  late final Animation<double> _shakeAnim = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0, end: -10), weight: 1),
    TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
    TweenSequenceItem(tween: Tween(begin: 10, end: -7), weight: 2),
    TweenSequenceItem(tween: Tween(begin: -7, end: 5), weight: 2),
    TweenSequenceItem(tween: Tween(begin: 5, end: 0), weight: 1),
  ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeOut));

  // Parallax tilt
  Offset _tilt = Offset.zero;

  // ---------------- Form ----------------
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();

  bool _isPasswordVisible = false;
  bool _rememberMe = true;
  bool _loading = false;
  bool _googleLoading = false;

  @override
  void dispose() {
    _logoController.dispose();
    _bgController.dispose();
    _glowController.dispose();
    _shakeCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  // ---------------- Auth: Email/Password ----------------
  Future<void> _emailPasswordSignIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      _shakeCtrl.forward(from: 0);
      return;
    }
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (!mounted) return;
      _showWelcomeDialog();
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Failed to sign in');
    } catch (_) {
      _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ---------------- Auth: Google ----------------
  Future<void> _googleSignIn() async {
    setState(() => _googleLoading = true);
    try {
      final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();
      if (gUser == null) return; // cancelled
      final gAuth = await gUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      if (!mounted) return;
      _showWelcomeDialog();
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Google sign-in failed');
    } catch (_) {
      _showError('Google sign-in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  // ---------------- UI helpers ----------------
  void _showError(String msg) {
    _shakeCtrl.forward(from: 0);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: Colors.redAccent, content: Text(msg)),
    );
  }

  void _showWelcomeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.fromLTRB(28, 30, 28, 22),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.22)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _glowController,
                    builder: (_, __) {
                      final t = _glowController.value;
                      return Container(
                        width: 86 + 4 * sin(t * pi),
                        height: 86 + 4 * sin(t * pi),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [kAccent, kAccent2],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 42,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Welcome back to ADDA!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You are signed in successfully.',
                    style: TextStyle(color: Colors.white.withOpacity(0.9)),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kAccent2,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => MySocialHomepage()),
                        );
                      },
                      child: const Text(
                        'Continue',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- Build ----------------
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      // keep default resizeToAvoidBottomInset = true
      body: GestureDetector(
        onPanUpdate: (d) => setState(() {
          final nextTilt = _tilt + d.delta / 200;
          _tilt = Offset(
            nextTilt.dx.clamp(-0.4, 0.4),
            nextTilt.dy.clamp(-0.4, 0.4),
          );
        }),
        onPanEnd: (_) => setState(() => _tilt = Offset.zero),
        child: Stack(
          children: [
            _AnimatedBackground(controller: _bgController),

            // floating orbs
            IgnorePointer(
              child: Stack(
                children: const [
                  _FloatingOrb(size: 140, dx: -0.8, dy: -0.7, speed: 0.6),
                  _FloatingOrb(size: 120, dx: 0.85, dy: -0.75, speed: 0.8),
                  _FloatingOrb(size: 160, dx: -0.9, dy: 0.85, speed: 0.7),
                  _FloatingOrb(size: 110, dx: 0.8, dy: 0.75, speed: 0.5),
                ],
              ),
            ),

            SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  22,
                  18,
                  22,
                  18 + bottomInset, // keyboard-aware bottom padding
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: size.height - 36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 10),
                      // Logo
                      ScaleTransition(
                        scale: _logoScale,
                        child: AnimatedBuilder(
                          animation: _glowController,
                          builder: (_, __) {
                            final glow = 6.0 + 8.0 * _glowController.value;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: kAccent.withOpacity(0.35),
                                    blurRadius: glow,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: ShaderMask(
                                shaderCallback: (rect) => const LinearGradient(
                                  colors: [kAccent, kAccent2],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ).createShader(rect),
                                child: const Text(
                                  'ADDA',
                                  style: TextStyle(
                                    fontSize: 46,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Welcome back — let’s catch up!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Glass card with max width + tilt + shake
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: AnimatedBuilder(
                            animation: _shakeAnim,
                            builder: (_, child) {
                              return Transform.translate(
                                offset: Offset(_shakeAnim.value, 0),
                                child: child,
                              );
                            },
                            child: Transform(
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.001)
                                ..rotateX(_tilt.dy)
                                ..rotateY(-_tilt.dx),
                              alignment: Alignment.center,
                              child: _GlassCard(
                                emailCtrl: _emailCtrl,
                                passwordCtrl: _passwordCtrl,
                                emailFocus: _emailFocus,
                                passFocus: _passFocus,
                                formKey: _formKey,
                                rememberMe: _rememberMe,
                                isPasswordVisible: _isPasswordVisible,
                                loading: _loading,
                                googleLoading: _googleLoading,
                                onRemember: (v) =>
                                    setState(() => _rememberMe = v),
                                onTogglePassword: () => setState(
                                  () =>
                                      _isPasswordVisible = !_isPasswordVisible,
                                ),
                                onForgot: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const PasswordRecoveryScreen(),
                                    ),
                                  );
                                  if (mounted) setState(() {});
                                },
                                onEmailSignIn: _emailPasswordSignIn,
                                onGoogleSignIn: _googleSignIn,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Don’t have an account?',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.92),
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SignupScreen(),
                                ),
                              );
                              if (mounted) setState(() {});
                            },
                            child: const Text(
                              'Sign Up',
                              style: TextStyle(
                                color: kAccent,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================= Helper Widgets =======================

class _AnimatedBackground extends StatelessWidget {
  final AnimationController controller;
  const _AnimatedBackground({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = controller.value;
        return Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _SigninScreenState.kBgTop,
                    _SigninScreenState.kBgMid,
                    _SigninScreenState.kBgBottom,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Transform.rotate(
              angle: t * 2 * pi,
              child: Container(
                decoration: BoxDecoration(
                  gradient: SweepGradient(
                    startAngle: 0,
                    endAngle: 2 * pi,
                    colors: [
                      Colors.transparent,
                      _SigninScreenState.kAccent.withOpacity(0.08),
                      Colors.transparent,
                      _SigninScreenState.kAccent2.withOpacity(0.08),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                    center: Alignment(
                      0.1 * sin(t * 2 * pi),
                      -0.1 * cos(t * 2 * pi),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FloatingOrb extends StatelessWidget {
  final double size;
  final double dx, dy;
  final double speed;
  const _FloatingOrb({
    required this.size,
    required this.dx,
    required this.dy,
    required this.speed,
  });

  @override
  Widget build(BuildContext context) {
    // lightweight "tick" to rebuild
    final ctrl = Tween<double>(begin: 0, end: 1).animate(
      AlwaysStoppedAnimation(
        (DateTime.now().millisecondsSinceEpoch % 4000) / 4000,
      ),
    );

    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final t = (DateTime.now().millisecondsSinceEpoch / 1000.0) * speed;
        final wobbleX = 0.02 * sin(t);
        final wobbleY = 0.03 * cos(t * 0.8);

        return Align(
          alignment: Alignment(dx + wobbleX, dy + wobbleY),
          child: IgnorePointer(
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _SigninScreenState.kAccent2.withOpacity(0.14),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GlassCard extends StatelessWidget {
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final FocusNode emailFocus;
  final FocusNode passFocus;
  final GlobalKey<FormState> formKey;

  final bool rememberMe;
  final bool isPasswordVisible;
  final bool loading;
  final bool googleLoading;

  final ValueChanged<bool> onRemember;
  final VoidCallback onTogglePassword;
  final VoidCallback onForgot;
  final VoidCallback onEmailSignIn;
  final VoidCallback onGoogleSignIn;

  const _GlassCard({
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.emailFocus,
    required this.passFocus,
    required this.formKey,
    required this.rememberMe,
    required this.isPasswordVisible,
    required this.loading,
    required this.googleLoading,
    required this.onRemember,
    required this.onTogglePassword,
    required this.onForgot,
    required this.onEmailSignIn,
    required this.onGoogleSignIn,
  });

  @override
  Widget build(BuildContext context) {
    // Card content is fully responsive & overflow-safe
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withOpacity(0.22)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 26,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title row: safe with Expanded
                Row(
                  children: [
                    Container(
                      height: 34,
                      width: 34,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            _SigninScreenState.kAccent,
                            _SigninScreenState.kAccent2,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(
                        Icons.lock_open_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Sign in to your ADDA account',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.95),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                _Field(
                  controller: emailCtrl,
                  label: 'Email',
                  hint: 'you@example.com',
                  icon: Icons.mail_outline_rounded,
                  focusNode: emailFocus,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.isEmpty) return 'Please enter your email';
                    final ok = RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value);
                    if (!ok) return 'Please enter a valid email';
                    return null;
                  },
                ),

                const SizedBox(height: 12),
                _Field(
                  controller: passwordCtrl,
                  label: 'Password',
                  hint: '••••••••',
                  icon: Icons.lock_outline_rounded,
                  focusNode: passFocus,
                  obscure: true,
                  suffix: IconButton(
                    splashRadius: 22,
                    icon: Icon(
                      Icons.visibility_rounded,
                      color: Colors.white.withOpacity(0.95),
                    ),
                    onPressed: onTogglePassword,
                  ),
                  validator: (v) {
                    final value = v ?? '';
                    if (value.trim().isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 8),

                // >>> Responsive "Remember me / Forgot Password?" <<<
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Use Wrap to avoid horizontal overflow at small widths
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      alignment: constraints.maxWidth < 360
                          ? WrapAlignment.start
                          : WrapAlignment.spaceBetween,
                      children: [
                        // left chunk: switch + label
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch.adaptive(
                              value: rememberMe,
                              activeColor: _SigninScreenState.kAccent2,
                              onChanged: onRemember,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Remember me',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),

                        // right chunk: forgot button, shrink-to-fit
                        FittedBox(
                          child: TextButton(
                            onPressed: onForgot,
                            style: TextButton.styleFrom(
                              minimumSize: const Size(0, 0),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: _SigninScreenState.kAccent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 10),
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: loading ? null : onEmailSignIn,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: _SigninScreenState.kAccent2,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Sign In',
                              key: ValueKey('signin_text'),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    Expanded(child: _divider()),
                  ],
                ),

                const SizedBox(height: 12),
                SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: googleLoading ? null : onGoogleSignIn,
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: googleLoading
                          ? const SizedBox(
                              key: ValueKey('gload'),
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _SigninScreenState.kAccent,
                              ),
                            )
                          : const Icon(
                              Icons.g_mobiledata_rounded,
                              key: ValueKey('gicon'),
                              color: _SigninScreenState.kAccent,
                            ),
                    ),
                    label: const FittedBox(
                      child: Text(
                        'Continue with Google',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white.withOpacity(0.25)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      backgroundColor: Colors.white.withOpacity(0.07),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),

                const SizedBox(height: 10),
                SizedBox(
                  height: 48,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => MySocialHomepage()),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Continue as guest',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.98),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _divider() =>
      Container(height: 1, color: Colors.white.withOpacity(0.22));
}

class _Field extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscure = false,
    this.suffix,
    this.validator,
    this.focusNode,
  });

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode?.addListener(_onFocus);
  }

  void _onFocus() =>
      setState(() => _focused = widget.focusNode?.hasFocus ?? false);

  @override
  void dispose() {
    widget.focusNode?.removeListener(_onFocus);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glow = _focused ? 0.18 : 0.08;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _SigninScreenState.kAccent.withOpacity(glow),
            blurRadius: _focused ? 22 : 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextFormField(
        controller: widget.controller,
        keyboardType: widget.keyboardType,
        obscureText: widget.obscure,
        validator: widget.validator,
        style: const TextStyle(color: Colors.white),
        cursorColor: _SigninScreenState.kAccent,
        focusNode: widget.focusNode,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.55)),
          labelStyle: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Icon(widget.icon, color: Colors.white.withOpacity(0.95)),
          suffixIcon: widget.suffix,
          filled: true,
          fillColor: Colors.white.withOpacity(0.12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.white.withOpacity(0.25),
              width: 1.2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: _SigninScreenState.kAccent,
              width: 1.6,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
