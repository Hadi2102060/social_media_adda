// lib/views/profile/profile_view.dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:adda/views/profile/profile_edit.dart';
import 'package:adda/views/profile/privacy_settings.dart';
import 'package:adda/views/privacy/account_settings_screen.dart';
import 'package:adda/views/privacy/block_report_screen.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView>
    with TickerProviderStateMixin {
  // Animations
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _backgroundController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _backgroundAnimation;

  // Firebase
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseDatabase.instance;
  DatabaseReference? _userRef;
  StreamSubscription<DatabaseEvent>? _userSub;
  StreamSubscription<User?>? _authSub;

  // State
  bool _initialLoading = true;
  String? _errorText;

  // Profile fields
  String _name = '';
  String _username = '';
  String _bio = '';
  String _email = '';
  String _phone = '';
  String _location = '';
  String _website = '';
  String? _photoBase64; // raw base64 string from DB
  Uint8List? _photoBytes; // decoded bytes (cache bust friendly)
  int _followers = 0;
  int _following = 0;
  int _posts = 0;

  // Demo posts (UI only)
  final List<Map<String, dynamic>> _postsList = const [
    {'image': 'https://picsum.photos/300/300?random=10', 'likes': 234},
    {'image': 'https://picsum.photos/300/300?random=11', 'likes': 156},
    {'image': 'https://picsum.photos/300/300?random=12', 'likes': 89},
  ];

  @override
  void initState() {
    super.initState();

    // Animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );
    _backgroundAnimation = CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    );

    _fadeController.forward();
    _slideController.forward();
    _backgroundController.repeat(reverse: true);

    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (_auth.currentUser == null) {
      // Not logged in yet: listen auth, but don't keep spinner forever
      _authSub = _auth.authStateChanges().listen((u) {
        if (u != null) {
          _setupRefsAndLoad(u.uid);
        } else {
          if (mounted) {
            setState(() {
              _initialLoading = false;
              _errorText = 'You are not logged in.';
            });
          }
        }
      });
      setState(() => _initialLoading = false);
      return;
    }
    _setupRefsAndLoad(_auth.currentUser!.uid);
  }

  Future<void> _setupRefsAndLoad(String uid) async {
    _userRef = _db.ref('users/$uid');

    // 1) one-time fetch to avoid infinite spinner
    await _refreshOnce();

    // 2) live updates
    _userSub?.cancel();
    _userSub = _userRef!.onValue.listen(
      (event) => _applySnapshot(event.snapshot.value),
      onError: (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Realtime update failed: $e')));
      },
    );
  }

  Future<void> _refreshOnce() async {
    try {
      final snap = await _userRef!.get().timeout(const Duration(seconds: 6));
      _applySnapshot(snap.value);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorText = 'Failed to load profile once: $e';
        });
      }
    } finally {
      if (mounted) setState(() => _initialLoading = false);
    }
  }

  // --- Base64 helpers --- //
  String _sanitizeBase64(String s) {
    // remove data URL prefix if present
    final idx = s.indexOf('base64,');
    if (idx != -1) {
      s = s.substring(idx + 7);
    }
    // trim whitespace/newlines
    s = s.replaceAll(RegExp(r'\s'), '');
    return s;
  }

  Uint8List? _decodeBase64(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final cleaned = _sanitizeBase64(raw);
      return base64Decode(cleaned);
    } catch (e) {
      // ignore decode error; show placeholder
      return null;
    }
  }

  void _applySnapshot(dynamic raw) {
    if (!mounted) return;

    final data = (raw is Map) ? raw : null;

    setState(() {
      if (data != null) {
        _name = (data['name'] ?? '') as String;
        _username = (data['username'] ?? '') as String;
        _bio = (data['bio'] ?? '') as String;
        _email = (data['email'] ?? '') as String;
        _phone = (data['phone'] ?? '') as String;
        _location = (data['location'] ?? '') as String;
        _website = (data['website'] ?? '') as String;

        // handle photoBase64 safely (decode + cache)
        final newB64 = (data['photoBase64'] ?? null) as String?;
        if (newB64 != _photoBase64) {
          _photoBase64 = newB64;
          _photoBytes = _decodeBase64(_photoBase64);
        }

        // optional stats
        final f1 = data['followers'];
        final f2 = data['following'];
        final p = data['posts'];
        if (f1 is int) _followers = f1;
        if (f2 is int) _following = f2;
        if (p is int) _posts = p;

        _errorText = null;
      } else {
        _errorText ??= 'No profile data yet.';
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _backgroundController.dispose();
    _userSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }

  ImageProvider _avatarProvider() {
    if (_photoBytes != null && _photoBytes!.isNotEmpty) {
      // New MemoryImage instance with fresh bytes → cache bust
      return MemoryImage(_photoBytes!);
    }
    // placeholder
    return const NetworkImage('https://i.pravatar.cc/100?img=65');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated background
          AnimatedBuilder(
            animation: _backgroundAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(
                        Colors.purple.shade300,
                        Colors.purple.shade400,
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
                      Color.lerp(
                        Colors.deepPurple.shade400,
                        Colors.deepPurple.shade500,
                        _backgroundAnimation.value,
                      )!,
                    ],
                    stops: const [0.0, 0.3, 0.7, 1.0],
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topRight,
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

          SafeArea(
            child: _initialLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        // App Bar
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                const Spacer(),
                                const Text(
                                  'Profile',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                PopupMenuButton<String>(
                                  icon: const Icon(
                                    Icons.settings,
                                    color: Colors.white,
                                  ),
                                  onSelected: (value) {
                                    switch (value) {
                                      case 'account_settings':
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const AccountSettingsScreen(),
                                          ),
                                        );
                                        break;
                                      case 'block_report':
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const BlockReportScreen(),
                                          ),
                                        );
                                        break;
                                      case 'privacy_settings':
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const PrivacySettings(),
                                          ),
                                        );
                                        break;
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'account_settings',
                                      child: Row(
                                        children: const [
                                          Icon(
                                            Icons.security,
                                            color: Colors.blue,
                                          ),
                                          SizedBox(width: 8),
                                          Text('Account Settings'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'block_report',
                                      child: Row(
                                        children: const [
                                          Icon(Icons.block, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Block & Report'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'privacy_settings',
                                      child: Row(
                                        children: const [
                                          Icon(
                                            Icons.privacy_tip,
                                            color: Colors.orange,
                                          ),
                                          SizedBox(width: 8),
                                          Text('Privacy Settings'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Error banner
                        if (_errorText != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.red.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info, color: Colors.red),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorText!,
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Profile Header
                        SlideTransition(
                          position: _slideAnimation,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: Container(
                              margin: const EdgeInsets.all(16),
                              padding: const EdgeInsets.all(20),
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
                                  // Cover + Avatar + Edit
                                  Stack(
                                    children: [
                                      Container(
                                        height: 120,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                          image: const DecorationImage(
                                            image: NetworkImage(
                                              'https://picsum.photos/800/300?blur=2',
                                            ),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        left: 20,
                                        child: Container(
                                          width: 80,
                                          height: 80,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 4,
                                            ),
                                            image: DecorationImage(
                                              image: _avatarProvider(),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 10,
                                        right: 10,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.9,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.edit,
                                              color: Colors.blue,
                                            ),
                                            onPressed: () async {
                                              await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      const ProfileEdit(),
                                                ),
                                              );
                                              // নিশ্চিতভাবে সাথে সাথে রিফ্রেশ
                                              await _refreshOnce();
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),

                                  // User Info
                                  Column(
                                    children: [
                                      Text(
                                        _name.isNotEmpty ? _name : 'Your Name',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _username.isNotEmpty
                                            ? '@$_username'
                                            : '@username',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      if (_bio.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        Text(
                                          _bio,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black87,
                                            height: 1.4,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                      const SizedBox(height: 20),

                                      // Stats
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          _buildStatItem(
                                            'Posts',
                                            _posts.toString(),
                                          ),
                                          _buildStatItem(
                                            'Followers',
                                            _followers.toString(),
                                          ),
                                          _buildStatItem(
                                            'Following',
                                            _following.toString(),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),

                                      // Actions
                                      Column(
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: ElevatedButton.icon(
                                                  onPressed: () async {
                                                    await Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            const ProfileEdit(),
                                                      ),
                                                    );
                                                    await _refreshOnce();
                                                  },
                                                  icon: const Icon(Icons.edit),
                                                  label: const Text(
                                                    'Edit Profile',
                                                  ),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.blue,
                                                    foregroundColor:
                                                        Colors.white,
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 12,
                                                        ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: OutlinedButton.icon(
                                                  onPressed: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            const PrivacySettings(),
                                                      ),
                                                    );
                                                  },
                                                  icon: const Icon(
                                                    Icons.settings,
                                                  ),
                                                  label: const Text('Settings'),
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor:
                                                        Colors.blue,
                                                    side: const BorderSide(
                                                      color: Colors.blue,
                                                    ),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 12,
                                                        ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: OutlinedButton.icon(
                                                  onPressed: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            const AccountSettingsScreen(),
                                                      ),
                                                    );
                                                  },
                                                  icon: const Icon(
                                                    Icons.security,
                                                    color: Colors.orange,
                                                  ),
                                                  label: const Text(
                                                    'Privacy & Security',
                                                  ),
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor:
                                                        Colors.orange,
                                                    side: const BorderSide(
                                                      color: Colors.orange,
                                                    ),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 12,
                                                        ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Posts Grid
                        SlideTransition(
                          position: _slideAnimation,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Posts',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 3,
                                          crossAxisSpacing: 8,
                                          mainAxisSpacing: 8,
                                        ),
                                    itemCount: _postsList.length,
                                    itemBuilder: (context, index) {
                                      final post = _postsList[index];
                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Stack(
                                          children: [
                                            Image.network(
                                              post['image'],
                                              width: double.infinity,
                                              height: double.infinity,
                                              fit: BoxFit.cover,
                                            ),
                                            Positioned(
                                              bottom: 0,
                                              left: 0,
                                              right: 0,
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topCenter,
                                                    end: Alignment.bottomCenter,
                                                    colors: [
                                                      Colors.transparent,
                                                      Colors.black.withOpacity(
                                                        0.7,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.favorite,
                                                      color: Colors.white,
                                                      size: 12,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '${post['likes']}',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}
