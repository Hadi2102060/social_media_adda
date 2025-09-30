import 'package:flutter/material.dart';
import 'dart:math' as math;

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({Key? key}) : super(key: key);

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _pulseController;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _pulseAnimation;

  bool _isPrivateAccount = false;
  bool _twoFactorAuth = false;
  bool _loginAlerts = true;
  bool _saveLoginInfo = true;
  bool _showActivityStatus = true;
  bool _allowComments = true;
  bool _allowMentions = true;
  bool _allowTags = true;

  @override
  void initState() {
    super.initState();
    
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _backgroundAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_backgroundController);

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated Background
          AnimatedBuilder(
            animation: _backgroundAnimation,
            builder: (context, child) {
              return CustomPaint(
                painter: AnimatedBackgroundPainter(
                  animation: _backgroundAnimation.value,
                  pulse: _pulseAnimation.value,
                ),
                size: Size.infinite,
              );
            },
          ),
          
          // Content
          SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Account Settings',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Privacy Section
                        _buildSectionTitle('Privacy'),
                        _buildPrivacySettings(),
                        
                        const SizedBox(height: 24),
                        
                        // Security Section
                        _buildSectionTitle('Security'),
                        _buildSecuritySettings(),
                        
                        const SizedBox(height: 24),
                        
                        // Account Actions
                        _buildSectionTitle('Account Actions'),
                        _buildAccountActions(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildPrivacySettings() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            'Private Account',
            'Only approved followers can see your posts',
            _isPrivateAccount,
            (value) => setState(() => _isPrivateAccount = value),
          ),
          _buildSwitchTile(
            'Show Activity Status',
            'Let others see when you\'re active',
            _showActivityStatus,
            (value) => setState(() => _showActivityStatus = value),
          ),
          _buildSwitchTile(
            'Allow Comments',
            'Let others comment on your posts',
            _allowComments,
            (value) => setState(() => _allowComments = value),
          ),
          _buildSwitchTile(
            'Allow Mentions',
            'Let others mention you in posts',
            _allowMentions,
            (value) => setState(() => _allowMentions = value),
          ),
          _buildSwitchTile(
            'Allow Tags',
            'Let others tag you in posts',
            _allowTags,
            (value) => setState(() => _allowTags = value),
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySettings() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            'Two-Factor Authentication',
            'Add an extra layer of security',
            _twoFactorAuth,
            (value) => setState(() => _twoFactorAuth = value),
          ),
          _buildSwitchTile(
            'Login Alerts',
            'Get notified of new logins',
            _loginAlerts,
            (value) => setState(() => _loginAlerts = value),
          ),
          _buildSwitchTile(
            'Save Login Info',
            'Remember your login information',
            _saveLoginInfo,
            (value) => setState(() => _saveLoginInfo = value),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountActions() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          _buildActionTile(
            'Change Password',
            Icons.lock_outline,
            () => _showChangePasswordDialog(),
          ),
          _buildActionTile(
            'Download Data',
            Icons.download_outlined,
            () => _showDownloadDataDialog(),
          ),
          _buildActionTile(
            'Deactivate Account',
            Icons.pause_circle_outline,
            () => _showDeactivateDialog(),
            isDestructive: true,
          ),
          _buildActionTile(
            'Delete Account',
            Icons.delete_outline,
            () => _showDeleteAccountDialog(),
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.blue,
            activeTrackColor: Colors.blue.withOpacity(0.3),
            inactiveThumbColor: Colors.white.withOpacity(0.5),
            inactiveTrackColor: Colors.white.withOpacity(0.2),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(String title, IconData icon, VoidCallback onTap, {bool isDestructive = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? Colors.red : Colors.white,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDestructive ? Colors.red : Colors.white,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withOpacity(0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Change Password', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Current Password',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white30),
                ),
              ),
              style: const TextStyle(color: Colors.white),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'New Password',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white30),
                ),
              ),
              style: const TextStyle(color: Colors.white),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSuccessMessage('Password changed successfully!');
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  void _showDownloadDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Download Data', style: TextStyle(color: Colors.white)),
        content: const Text(
          'We\'ll email you a link to download your data within 48 hours.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSuccessMessage('Download request sent!');
            },
            child: const Text('Request'),
          ),
        ],
      ),
    );
  }

  void _showDeactivateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Deactivate Account', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Your account will be temporarily deactivated. You can reactivate it anytime by logging in.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSuccessMessage('Account deactivated!');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Delete Account', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This action cannot be undone. All your data will be permanently deleted.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSuccessMessage('Account deletion requested!');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class AnimatedBackgroundPainter extends CustomPainter {
  final double animation;
  final double pulse;

  AnimatedBackgroundPainter({required this.animation, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.purple.withOpacity(0.3),
          Colors.blue.withOpacity(0.3),
          Colors.pink.withOpacity(0.3),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Animated circles
    for (int i = 0; i < 5; i++) {
      final x = size.width * 0.5 + math.cos(animation + i) * size.width * 0.3;
      final y = size.height * 0.5 + math.sin(animation + i) * size.height * 0.3;
      final radius = 50 * pulse;

      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()
          ..color = Colors.white.withOpacity(0.1)
          ..style = PaintingStyle.fill,
      );
    }

    // Background gradient
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 