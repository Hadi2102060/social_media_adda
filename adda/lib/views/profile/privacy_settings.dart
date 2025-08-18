import 'package:flutter/material.dart';

class PrivacySettings extends StatefulWidget {
  const PrivacySettings({super.key});

  @override
  State<PrivacySettings> createState() => _PrivacySettingsState();
}

class _PrivacySettingsState extends State<PrivacySettings>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _backgroundController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _backgroundAnimation;

  // Privacy settings
  bool _isPrivateAccount = false;
  bool _showEmail = true;
  bool _showPhone = true;
  bool _showLocation = true;
  bool _allowComments = true;
  bool _allowLikes = true;
  bool _allowMentions = true;
  bool _allowTags = true;
  bool _showOnlineStatus = true;
  bool _showLastSeen = true;
  bool _allowStoryViews = true;
  bool _allowDirectMessages = true;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _backgroundController = AnimationController(
      duration: Duration(seconds: 7),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));

    _fadeController.forward();
    _slideController.forward();
    _backgroundController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  void _showSaveDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Save Changes'),
        content: Text('Your privacy settings have been updated successfully.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
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
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(Colors.green.shade400, Colors.green.shade500, _backgroundAnimation.value)!,
                      Color.lerp(Colors.teal.shade400, Colors.teal.shade500, _backgroundAnimation.value)!,
                      Color.lerp(Colors.blue.shade400, Colors.blue.shade500, _backgroundAnimation.value)!,
                      Color.lerp(Colors.indigo.shade400, Colors.indigo.shade500, _backgroundAnimation.value)!,
                    ],
                    stops: [0.0, 0.3, 0.7, 1.0],
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.bottomRight,
                      radius: 1.5,
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                // App Bar
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Spacer(),
                        Text(
                          'Privacy Settings',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Spacer(),
                        IconButton(
                          icon: Icon(Icons.save, color: Colors.white),
                          onPressed: _showSaveDialog,
                        ),
                      ],
                    ),
                  ),
                ),

                // Settings Content
                Expanded(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Account Privacy
                            _buildSettingsSection(
                              'Account Privacy',
                              Icons.lock_outline,
                              [
                                _buildSwitchTile(
                                  'Private Account',
                                  'Only approved followers can see your posts',
                                  _isPrivateAccount,
                                  (value) => setState(() => _isPrivateAccount = value),
                                ),
                                _buildSwitchTile(
                                  'Show Email',
                                  'Allow others to see your email address',
                                  _showEmail,
                                  (value) => setState(() => _showEmail = value),
                                ),
                                _buildSwitchTile(
                                  'Show Phone',
                                  'Allow others to see your phone number',
                                  _showPhone,
                                  (value) => setState(() => _showPhone = value),
                                ),
                                _buildSwitchTile(
                                  'Show Location',
                                  'Allow others to see your location',
                                  _showLocation,
                                  (value) => setState(() => _showLocation = value),
                                ),
                              ],
                            ),

                            SizedBox(height: 20),

                            // Interaction Settings
                            _buildSettingsSection(
                              'Interaction Settings',
                              Icons.touch_app,
                              [
                                _buildSwitchTile(
                                  'Allow Comments',
                                  'Let others comment on your posts',
                                  _allowComments,
                                  (value) => setState(() => _allowComments = value),
                                ),
                                _buildSwitchTile(
                                  'Allow Likes',
                                  'Let others like your posts',
                                  _allowLikes,
                                  (value) => setState(() => _allowLikes = value),
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

                            SizedBox(height: 20),

                            // Visibility Settings
                            _buildSettingsSection(
                              'Visibility Settings',
                              Icons.visibility,
                              [
                                _buildSwitchTile(
                                  'Show Online Status',
                                  'Let others see when you\'re online',
                                  _showOnlineStatus,
                                  (value) => setState(() => _showOnlineStatus = value),
                                ),
                                _buildSwitchTile(
                                  'Show Last Seen',
                                  'Let others see when you were last active',
                                  _showLastSeen,
                                  (value) => setState(() => _showLastSeen = value),
                                ),
                                _buildSwitchTile(
                                  'Allow Story Views',
                                  'Let others view your stories',
                                  _allowStoryViews,
                                  (value) => setState(() => _allowStoryViews = value),
                                ),
                                _buildSwitchTile(
                                  'Allow Direct Messages',
                                  'Let others send you direct messages',
                                  _allowDirectMessages,
                                  (value) => setState(() => _allowDirectMessages = value),
                                ),
                              ],
                            ),

                            SizedBox(height: 20),

                            // Blocked Users
                            _buildSettingsSection(
                              'Blocked Users',
                              Icons.block,
                              [
                                _buildListTile(
                                  'Manage Blocked Users',
                                  'View and manage your blocked users list',
                                  Icons.people_outline,
                                  () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Blocked users management coming soon!'),
                                        backgroundColor: Colors.blue,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),

                            SizedBox(height: 20),

                            // Data & Privacy
                            _buildSettingsSection(
                              'Data & Privacy',
                              Icons.security,
                              [
                                _buildListTile(
                                  'Download My Data',
                                  'Get a copy of your data',
                                  Icons.download,
                                  () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Data download feature coming soon!'),
                                        backgroundColor: Colors.blue,
                                      ),
                                    );
                                  },
                                ),
                                _buildListTile(
                                  'Delete Account',
                                  'Permanently delete your account',
                                  Icons.delete_forever,
                                  () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text('Delete Account'),
                                        content: Text('Are you sure you want to permanently delete your account? This action cannot be undone.'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Account deletion feature coming soon!'),
                                                  backgroundColor: Colors.orange,
                                                ),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                            ),
                                            child: Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),

                            SizedBox(height: 30),
                          ],
                        ),
                      ),
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

  Widget _buildSettingsSection(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 5,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blue, size: 24),
              SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(8),
          child: Row(
            children: [
              Icon(icon, color: Colors.grey[600], size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
            ],
          ),
        ),
      ),
    );
  }
} 