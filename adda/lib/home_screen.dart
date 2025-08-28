// lib/home_screen.dart

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:adda/login_screen.dart';
import 'package:adda/views/content/camera_screen.dart';
import 'package:adda/views/notifications/notifications_screen.dart';
import 'package:adda/views/profile/privacy_settings.dart';
import 'package:adda/views/profile/profile_edit.dart';
import 'package:adda/views/profile/profile_view.dart';
import 'package:adda/views/search/search_screen.dart';
import 'package:adda/views/social/messenger_screen.dart';

// ⬇️ for gallery → editing
import 'package:image_picker/image_picker.dart';
import 'package:adda/views/content/editing_screen.dart';

/// -------------------- People screen --------------------
class PeopleScreen extends StatelessWidget {
  const PeopleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseDatabase.instance;
    return Scaffold(
      appBar: AppBar(
        title: const Text('People'),
        backgroundColor: const Color(0xFF6a11cb),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: db.ref('users').onValue,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data?.snapshot.value;
          if (data == null || data is! Map) {
            return const Center(child: Text('No users found'));
          }

          final List<Map<String, dynamic>> users = [];
          data.forEach((k, v) {
            if (v is Map) {
              final m = v.map((kk, vv) => MapEntry(kk.toString(), vv));
              users.add({
                'id': k.toString(),
                'name': (m['name'] ?? '').toString(),
                'username': (m['username'] ?? '').toString(),
                'photoUrl': (m['photoUrl'] ?? '').toString(),
                'photoBase64': (m['photoBase64'] ?? '').toString(),
              });
            }
          });

          if (users.isEmpty) return const Center(child: Text('No users found'));

          return ListView.separated(
            itemCount: users.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final u = users[i];
              ImageProvider avatar;
              final b64 = u['photoBase64'] as String;
              final url = u['photoUrl'] as String;
              if (b64.isNotEmpty) {
                try {
                  final clean = b64.contains('base64,')
                      ? b64.split('base64,').last
                      : b64;
                  avatar = MemoryImage(base64Decode(clean));
                } catch (_) {
                  avatar = const NetworkImage(
                    'https://i.pravatar.cc/100?img=65',
                  );
                }
              } else if (url.isNotEmpty) {
                avatar = NetworkImage(url);
              } else {
                avatar = const NetworkImage('https://i.pravatar.cc/100?img=65');
              }

              return ListTile(
                leading: CircleAvatar(backgroundImage: avatar),
                title: Text(u['name'].isNotEmpty ? u['name'] : 'User'),
                subtitle: Text(
                  u['username'].isNotEmpty ? '@${u['username']}' : '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Followed ${u['name'] ?? 'user'}'),
                      ),
                    );
                  },
                  child: const Text('Follow'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// -------------------- Reels / Videos feed --------------------
class ReelsFeedScreen extends StatelessWidget {
  const ReelsFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseDatabase.instance;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reels & Videos'),
        backgroundColor: const Color(0xFF6a11cb),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: db.ref('reels').orderByChild('createdAt').onValue,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data?.snapshot.value;
          if (data == null || data is! Map) {
            return const Center(child: Text('No reels yet'));
          }

          final items = <Map<String, dynamic>>[];
          data.forEach((k, v) {
            if (v is Map) {
              final m = v.map((kk, vv) => MapEntry(kk.toString(), vv));
              items.add({
                'id': k.toString(),
                'authorId': m['authorId'] ?? '',
                'caption': m['caption'] ?? '',
                'thumbUrl': m['thumbUrl'] ?? '',
                'videoUrl': m['videoUrl'] ?? '',
                'createdAt': m['createdAt'] is int ? m['createdAt'] : 0,
              });
            }
          });
          items.sort(
            (a, b) => (b['createdAt'] as int).compareTo(a['createdAt'] as int),
          );

          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 9 / 16,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final r = items[i];
              final thumb = (r['thumbUrl'] ?? '').toString();
              return GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => Dialog(
                      insetPadding: const EdgeInsets.all(12),
                      child: Stack(
                        children: [
                          AspectRatio(
                            aspectRatio: 9 / 16,
                            child: thumb.isNotEmpty
                                ? Image.network(thumb, fit: BoxFit.cover)
                                : Container(
                                    color: Colors.black12,
                                    child: const Center(
                                      child: Icon(
                                        Icons.play_circle_fill,
                                        size: 64,
                                      ),
                                    ),
                                  ),
                          ),
                          Positioned(
                            right: 8,
                            top: 8,
                            child: IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          const Positioned.fill(
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.play_circle_outline, size: 64),
                                  SizedBox(height: 6),
                                  Text('Video playback coming soon'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: thumb.isNotEmpty
                          ? Image.network(thumb, fit: BoxFit.cover)
                          : Container(color: Colors.black12),
                    ),
                    const Positioned(
                      right: 6,
                      bottom: 6,
                      child: Icon(
                        Icons.play_circle_fill,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// -------------------- Settings / Saved / Activity --------------------
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF6a11cb),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Change Password'),
            onTap: () => showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Change Password'),
                content: const Text('Password change feature coming soon!'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Profile'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileEdit()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Settings'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrivacySettings()),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications),
            title: const Text('Notification Settings'),
            value: true,
            onChanged: (val) {},
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text(
              'Delete Account',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () => showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Delete Account'),
                content: const Text(
                  'Are you sure you want to delete your account?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final savedPosts = const [
      {
        'image': 'https://picsum.photos/200/200?random=1',
        'title': 'Beautiful Sunset',
      },
      {
        'image': 'https://picsum.photos/200/200?random=2',
        'title': 'Mountain Adventure',
      },
      {
        'image': 'https://picsum.photos/200/200?random=3',
        'title': 'City Lights',
      },
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved'),
        backgroundColor: const Color(0xFF6a11cb),
      ),
      body: ListView.builder(
        itemCount: savedPosts.length,
        itemBuilder: (_, i) {
          final post = savedPosts[i];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: Image.network(
                post['image']!,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
              title: Text(post['title']!),
              onTap: () => showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(post['title']!),
                  content: Image.network(post['image']!),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final notifications = const [
      {
        'type': 'like',
        'user': 'john_doe',
        'desc': 'liked your post',
        'image': 'https://picsum.photos/40/40?random=10',
      },
      {
        'type': 'comment',
        'user': 'jane_smith',
        'desc': 'commented: Awesome!',
        'image': 'https://picsum.photos/40/40?random=11',
      },
      {
        'type': 'follow',
        'user': 'mike_wilson',
        'desc': 'started following you',
        'image': 'https://picsum.photos/40/40?random=12',
      },
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity'),
        backgroundColor: const Color(0xFF6a11cb),
      ),
      body: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (_, i) {
          final n = notifications[i];
          return ListTile(
            leading: CircleAvatar(backgroundImage: NetworkImage(n['image']!)),
            title: Text('${n['user']} ${n['desc']}'),
            onTap: () => showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Notification'),
                content: Text('${n['user']} ${n['desc']}'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF6a11cb),
        icon: const Icon(Icons.done_all),
        label: const Text('Mark all as read'),
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications marked as read!')),
        ),
      ),
    );
  }
}

/// =================== Home ===================
class MySocialHomepage extends StatefulWidget {
  const MySocialHomepage({super.key});
  @override
  State<MySocialHomepage> createState() => _MySocialHomepageState();
}

class _MySocialHomepageState extends State<MySocialHomepage>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _greetingController;
  late Animation<double> _greetingAnimation;

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseDatabase.instance;

  String? _displayName;
  String? _photoUrl;
  String? _photoBase64;
  DatabaseReference? _userRef;
  StreamSubscription<DatabaseEvent>? _userSub;

  @override
  void initState() {
    super.initState();
    _greetingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _greetingAnimation = CurvedAnimation(
      parent: _greetingController,
      curve: Curves.easeInOut,
    );
    _greetingController.forward();
    _attachCurrentUserStream();
  }

  void _attachCurrentUserStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    _userRef = _db.ref('users/$uid');
    _userSub = _userRef!.onValue.listen((event) {
      final m = event.snapshot.value as Map<dynamic, dynamic>?;
      if (m != null) {
        setState(() {
          _displayName = (m['name'] ?? '') as String;
          _photoUrl = (m['photoUrl'] ?? '') as String?;
          _photoBase64 = (m['photoBase64'] ?? '') as String?;
        });
      }
    });
  }

  @override
  void dispose() {
    _userSub?.cancel();
    _greetingController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(isFromRecovery: false),
      ),
      (_) => false,
    );
  }

  ImageProvider _currentUserImageProvider() {
    if (_photoBase64 != null && _photoBase64!.isNotEmpty) {
      try {
        final clean = _photoBase64!.contains('base64,')
            ? _photoBase64!.split('base64,').last
            : _photoBase64!;
        return MemoryImage(base64Decode(clean));
      } catch (_) {}
    }
    if (_photoUrl != null && _photoUrl!.isNotEmpty)
      return NetworkImage(_photoUrl!);
    return const NetworkImage('https://i.pravatar.cc/100?img=65');
  }

  // Gallery → Editing
  Future<void> _openGalleryAndEdit() async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
      );
      if (file == null) return;
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              EditingScreen(selectedImage: file.path, selectedLocation: null),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open gallery: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = (_displayName?.isNotEmpty == true) ? _displayName! : 'User';
    final imgProvider = _currentUserImageProvider();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),

      /// ===== AppBar =====
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6a11cb), Color(0xFF2575fc)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8,
              ),
              child: Row(
                children: [
                  FadeTransition(
                    opacity: _greetingAnimation,
                    child: const Text(
                      'ADDA',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.messenger_outline,
                      color: Colors.white,
                      size: 26,
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => MessengerScreen()),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.search,
                      color: Colors.white,
                      size: 26,
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SearchScreen()),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert,
                      color: Colors.white,
                      size: 26,
                    ),
                    onSelected: (value) async {
                      if (value == 'settings') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        );
                      } else if (value == 'saved') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SavedScreen(),
                          ),
                        );
                      } else if (value == 'activity') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ActivityScreen(),
                          ),
                        );
                      } else if (value == 'logout') {
                        await _logout();
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'settings',
                        child: _MenuRow(icon: Icons.settings, text: 'Settings'),
                      ),
                      PopupMenuItem(
                        value: 'saved',
                        child: _MenuRow(icon: Icons.bookmark, text: 'Saved'),
                      ),
                      PopupMenuItem(
                        value: 'activity',
                        child: _MenuRow(
                          icon: Icons.notifications,
                          text: 'Activity',
                        ),
                      ),
                      PopupMenuItem(
                        value: 'logout',
                        child: _MenuRow(icon: Icons.logout, text: 'Logout'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      /// ===== Body (composer + stories + feed) =====
      body: RefreshIndicator(
        onRefresh: () async {},
        child: StreamBuilder<DatabaseEvent>(
          stream: _db.ref('posts').orderByChild('createdAt').onValue,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snap.data?.snapshot.value;
            final List<Widget> slivers = [];

            // Composer + Stories
            slivers.add(
              _ComposerWithStories(
                name: name,
                imgProvider: imgProvider,
                openCamera: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CameraScreen()),
                ),
                openGallery: _openGalleryAndEdit,
              ),
            );

            // Feed
            if (data == null) {
              slivers.add(
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: Text('No posts yet. Share something!'),
                  ),
                ),
              );
              return ListView(children: slivers);
            }

            final List<Map<String, dynamic>> posts = [];
            final root = data as Map<dynamic, dynamic>;
            root.forEach((key, value) {
              if (value is Map) {
                final m = value.map((k, v) => MapEntry(k.toString(), v));
                posts.add({
                  'id': key.toString(),
                  'authorId': m['authorId'] ?? '',
                  'authorName': m['authorName'] ?? '',
                  'authorUsername': m['authorUsername'] ?? '',
                  'caption': m['caption'] ?? '',
                  'tags': m['tags'] ?? '',
                  'location': m['location'],
                  'filter': m['filter'] ?? 'Normal',
                  'imageBase64': m['imageBase64'],
                  'imageUrl': m['imageUrl'],
                  'likesCount': (m['likesCount'] ?? 0) as int,
                  'commentsCount': (m['commentsCount'] ?? 0) as int,
                  'sharesCount': (m['sharesCount'] ?? 0) as int,
                  'createdAt': m['createdAt'] is int ? m['createdAt'] : 0,
                });
              }
            });
            posts.sort(
              (a, b) =>
                  (b['createdAt'] as int).compareTo(a['createdAt'] as int),
            );
            slivers.addAll(
              List.generate(posts.length, (i) => _PostCard(post: posts[i])),
            );

            return ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: slivers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => slivers[i],
            );
          },
        ),
      ),

      /// ===== BottomNavigationBar (6 items) =====
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReelsFeedScreen()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CameraScreen()),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PeopleScreen()),
            );
          } else if (index == 4) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => NotificationsScreen()),
            );
          } else if (index == 5) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileView()),
            );
          }
          setState(() => _selectedIndex = index);
        },
        selectedItemColor: const Color(0xFF6a11cb),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.ondemand_video),
            label: 'Video',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: 'Add'),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_outlined),
            label: 'People',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

/// ===== Composer + Stories =====
class _ComposerWithStories extends StatelessWidget {
  final String name;
  final ImageProvider imgProvider;
  final VoidCallback openCamera;
  final VoidCallback openGallery;

  const _ComposerWithStories({
    required this.name,
    required this.imgProvider,
    required this.openCamera,
    required this.openGallery,
  });

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser;
    return Column(
      children: [
        // Composer
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileView()),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(radius: 22, backgroundImage: imgProvider),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 80,
                      child: Text(
                        name,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: GestureDetector(
                  onTap: openCamera,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.edit, color: Color(0xFF6a11cb)),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            "What's on your mind?",
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.black54,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.photo_library_outlined,
                            color: Color(0xFF2575fc),
                          ),
                          tooltip: 'Open gallery',
                          onPressed: openGallery,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Stories row
        if (me != null) _StoriesRow(currentUid: me.uid),
      ],
    );
  }
}

/// ===== Stories row widget =====
class _StoriesRow extends StatefulWidget {
  final String currentUid;
  const _StoriesRow({required this.currentUid});

  @override
  State<_StoriesRow> createState() => _StoriesRowState();
}

class _StoriesRowState extends State<_StoriesRow> {
  final _db = FirebaseDatabase.instance;
  Set<String> _allowedUids = {};

  // constant size for square story tiles
  static const double _storySize = 84;

  @override
  void initState() {
    super.initState();
    _loadConnections();
  }

  Future<void> _loadConnections() async {
    final snap = await _db.ref('connections/${widget.currentUid}').get();
    final s = <String>{widget.currentUid}; // include me
    if (snap.value is Map) {
      final m = snap.value as Map;
      m.forEach((k, v) {
        if (v == true) s.add(k.toString());
      });
    }
    setState(() => _allowedUids = s);
  }

  bool _isValidStory(Map s) {
    final createdAt = (s['createdAt'] ?? 0) as int;
    final expiresAt = (s['expiresAt'] ?? 0) as int;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (expiresAt > 0) return now < expiresAt;
    if (createdAt > 0) {
      return now - createdAt < 24 * 60 * 60 * 1000; // 24h
    }
    return false;
  }

  bool _userHasValidStory(String uid, dynamic storiesRoot) {
    if (storiesRoot is! Map) return false;
    final userStories = storiesRoot[uid];
    if (userStories is! Map) return false;
    return userStories.values.whereType<Map>().any(_isValidStory);
  }

  void _openCreateStory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoryCreateScreen(currentUid: widget.currentUid),
      ),
    );
  }

  void _openViewerFor(String uid) async {
    final db = FirebaseDatabase.instance;
    final snap = await db.ref('stories/$uid').get();
    if (snap.value is! Map) return;
    final m = (snap.value as Map).map((k, v) => MapEntry(k.toString(), v));
    final items = <_StoryItem>[];
    m.forEach((k, v) {
      if (v is Map && _isValidStory(v)) {
        items.add(
          _StoryItem(
            id: k,
            mediaUrl: (v['mediaUrl'] ?? '').toString(),
            mediaBase64: (v['mediaBase64'] ?? '').toString(),
            type: (v['type'] ?? 'image').toString(),
            createdAt: (v['createdAt'] ?? 0) as int,
          ),
        );
      }
    });
    items.sort((a, b) => (a.createdAt).compareTo(b.createdAt));
    if (items.isEmpty) return;

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoryViewerScreen(uid: uid, items: items),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_allowedUids.isEmpty) return const SizedBox(height: 120);

    return SizedBox(
      height: 120, // fixed — keeps a single row
      child: StreamBuilder<DatabaseEvent>(
        stream: _db.ref('stories').onValue,
        builder: (context, snap) {
          final data = snap.data?.snapshot.value;
          final bubbles = <Widget>[];

          // 1) Create Story bubble (always first)
          bubbles.add(
            _CreateStoryBubble(
              uid: widget.currentUid,
              onTapCreate: _openCreateStory,
              size: _storySize,
            ),
          );

          // 2) Your Story bubble (viewer) — only if you have a valid story
          if (_userHasValidStory(widget.currentUid, data)) {
            bubbles.add(
              _StoryBubble(
                uid: widget.currentUid,
                label: 'Your Story',
                onTapOpen: () => _openViewerFor(widget.currentUid),
                size: _storySize,
              ),
            );
          }

          // 3) Friends' stories
          if (data is Map) {
            for (final uid in _allowedUids) {
              if (uid == widget.currentUid) continue;
              if (_userHasValidStory(uid, data)) {
                bubbles.add(
                  _StoryBubble(
                    uid: uid,
                    label: null,
                    onTapOpen: () => _openViewerFor(uid),
                    size: _storySize,
                  ),
                );
              }
            }
          }

          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemBuilder: (_, i) => i == 0
                ? Row(children: [const SizedBox(width: 4), bubbles[i]])
                : bubbles[i],
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemCount: bubbles.length,
          );
        },
      ),
    );
  }
}

class _StoryItem {
  final String id;
  final String mediaUrl; // optional
  final String mediaBase64; // optional
  final String type; // "image" | "video"
  final int createdAt;
  _StoryItem({
    required this.id,
    required this.mediaUrl,
    required this.mediaBase64,
    required this.type,
    required this.createdAt,
  });
}

/// ===== Create Story bubble (SQUARE) =====
class _CreateStoryBubble extends StatelessWidget {
  final String uid;
  final VoidCallback onTapCreate;
  final double size;
  const _CreateStoryBubble({
    required this.uid,
    required this.onTapCreate,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DataSnapshot>(
      future: FirebaseDatabase.instance.ref('users/$uid').get(),
      builder: (_, snap) {
        ImageProvider avatar = const NetworkImage(
          'https://i.pravatar.cc/100?img=65',
        );
        if (snap.data?.value is Map) {
          final m = (snap.data!.value as Map).map(
            (k, v) => MapEntry(k.toString(), v),
          );
          final photoUrl = (m['photoUrl'] ?? '').toString();
          final photoBase64 = (m['photoBase64'] ?? '').toString();
          if (photoBase64.isNotEmpty) {
            try {
              final clean = photoBase64.contains('base64,')
                  ? photoBase64.split('base64,').last
                  : photoBase64;
              avatar = MemoryImage(base64Decode(clean));
            } catch (_) {}
          } else if (photoUrl.isNotEmpty) {
            avatar = NetworkImage(photoUrl);
          }
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: onTapCreate,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: size,
                    height: size,
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6a11cb), Color(0xFF2575fc)],
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image(image: avatar, fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(1.5),
                      child: const CircleAvatar(
                        radius: 10,
                        backgroundColor: Color(0xFF6a11cb),
                        child: Icon(Icons.add, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: size,
              child: const Text(
                'Create',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// ===== Regular Story bubble (SQUARE) =====
class _StoryBubble extends StatelessWidget {
  final String uid;
  final String? label;
  final VoidCallback onTapOpen;
  final double size;

  const _StoryBubble({
    required this.uid,
    required this.onTapOpen,
    required this.size,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final db = FirebaseDatabase.instance;
    return FutureBuilder<DataSnapshot>(
      future: db.ref('users/$uid').get(),
      builder: (_, snap) {
        ImageProvider avatar = const NetworkImage(
          'https://i.pravatar.cc/100?img=65',
        );
        String name = 'User';
        if (snap.data?.value is Map) {
          final m = (snap.data!.value as Map).map(
            (k, v) => MapEntry(k.toString(), v),
          );
          name = (m['name'] ?? name).toString();
          final photoUrl = (m['photoUrl'] ?? '').toString();
          final photoBase64 = (m['photoBase64'] ?? '').toString();
          if (photoBase64.isNotEmpty) {
            try {
              final clean = photoBase64.contains('base64,')
                  ? photoBase64.split('base64,').last
                  : photoBase64;
              avatar = MemoryImage(base64Decode(clean));
            } catch (_) {}
          } else if (photoUrl.isNotEmpty) {
            avatar = NetworkImage(photoUrl);
          }
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: onTapOpen,
              child: Container(
                width: size,
                height: size,
                padding: const EdgeInsets.all(2.5),
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  gradient: LinearGradient(
                    colors: [Color(0xFF6a11cb), Color(0xFF2575fc)],
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image(image: avatar, fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: size,
              child: Text(
                label ?? name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// ===== Story Viewer (image + base64) =====
class StoryViewerScreen extends StatefulWidget {
  final String uid;
  final List<_StoryItem> items;
  const StoryViewerScreen({super.key, required this.uid, required this.items});

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> {
  late final PageController _pc;
  int _current = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pc = PageController();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      if (_current < widget.items.length - 1) {
        _current++;
        _pc.animateToPage(
          _current,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeIn,
        );
        setState(() {});
      } else {
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pc.dispose();
    super.dispose();
  }

  Uint8List? _decodeBase64(String b64) {
    if (b64.isEmpty) return null;
    try {
      final clean = b64.contains('base64,') ? b64.split('base64,').last : b64;
      return base64Decode(clean);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pc,
              itemCount: widget.items.length,
              onPageChanged: (i) {
                setState(() => _current = i);
                _startTimer();
              },
              itemBuilder: (_, i) {
                final s = widget.items[i];
                if (s.type == 'image') {
                  final bytes = _decodeBase64(s.mediaBase64);
                  final imgWidget = s.mediaUrl.isNotEmpty
                      ? Image.network(s.mediaUrl, fit: BoxFit.cover)
                      : (bytes != null
                            ? Image.memory(bytes, fit: BoxFit.cover)
                            : const SizedBox());
                  return GestureDetector(
                    onTapUp: (d) {
                      final w = MediaQuery.of(context).size.width;
                      if (d.localPosition.dx > w / 2 &&
                          _current < widget.items.length - 1) {
                        _pc.nextPage(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                        );
                      } else if (_current > 0) {
                        _pc.previousPage(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Center(
                      child: AspectRatio(aspectRatio: 9 / 16, child: imgWidget),
                    ),
                  );
                } else {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.play_circle_outline,
                          color: Colors.white,
                          size: 64,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Video story (player to be added)',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
            // progress bars
            Positioned(
              left: 8,
              right: 8,
              top: 8,
              child: Row(
                children: List.generate(
                  widget.items.length,
                  (i) => Expanded(
                    child: Container(
                      margin: EdgeInsets.only(
                        right: i == widget.items.length - 1 ? 0 : 4,
                      ),
                      height: 3,
                      decoration: BoxDecoration(
                        color: i <= _current ? Colors.white : Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // close
            Positioned(
              right: 8,
              top: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// -------------------- Story Create Screen (keyboard-safe) --------------------
class StoryCreateScreen extends StatefulWidget {
  final String currentUid;
  const StoryCreateScreen({super.key, required this.currentUid});

  @override
  State<StoryCreateScreen> createState() => _StoryCreateScreenState();
}

class _StoryCreateScreenState extends State<StoryCreateScreen> {
  XFile? _picked;
  bool _busy = false;
  final _caption = TextEditingController();

  Future<void> _pick(ImageSource src) async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: src, imageQuality: 92);
    if (x != null) setState(() => _picked = x);
  }

  Future<void> _shareStory() async {
    if (_picked == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select an image')));
      return;
    }
    setState(() => _busy = true);
    try {
      final bytes = await File(_picked!.path).readAsBytes();
      final b64 = base64Encode(bytes);

      final db = FirebaseDatabase.instance;
      final ref = db.ref('stories/${widget.currentUid}').push();
      final now = DateTime.now().millisecondsSinceEpoch;
      await ref.set({
        'id': ref.key,
        'type': 'image',
        'mediaBase64': 'data:image/jpeg;base64,$b64',
        'caption': _caption.text.trim(),
        'createdAt': ServerValue.timestamp,
        'expiresAt': now + 24 * 60 * 60 * 1000, // 24h
      });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Story shared!')));
      Navigator.pop(context); // back to Home
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    double previewHeight = size.width * 16 / 9;
    final maxAllow = size.height * 0.7;
    if (previewHeight > maxAllow) previewHeight = maxAllow;

    final preview = _picked == null
        ? Container(
            color: Colors.black12,
            child: const Center(child: Text('Select an image')),
          )
        : Image.file(File(_picked!.path), fit: BoxFit.cover);

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Create Story'),
        backgroundColor: const Color(0xFF6a11cb),
        actions: [
          TextButton(
            onPressed: _busy ? null : _shareStory,
            child: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(),
                  )
                : const Text('Share', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 12,
                right: 12,
                bottom: bottomInset + 16,
                top: 12,
              ),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: previewHeight,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: preview,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _caption,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      hintText: 'Add a caption (optional)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _busy
                            ? null
                            : () => _pick(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Gallery'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _busy
                            ? null
                            : () => _pick(ImageSource.camera),
                        icon: const Icon(Icons.photo_camera_outlined),
                        label: const Text('Camera'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// =================== Existing feed widgets (unchanged) ===================
class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MenuRow({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [Icon(icon, size: 20), const SizedBox(width: 8), Text(text)],
    );
  }
}

class _PostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  const _PostCard({required this.post});
  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseDatabase.instance;

  final GlobalKey _likeKey = GlobalKey();
  OverlayEntry? _overlay;

  bool _busyShare = false;
  bool _busySave = false;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final postId = post['id'] as String;
    final authorId = (post['authorId'] ?? '') as String;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                _AuthorAvatar(authorId: authorId),
                const SizedBox(width: 10),
                Expanded(
                  child: _AuthorNameAndTime(
                    authorId: authorId,
                    fallbackName: post['authorName'],
                    createdAt: post['createdAt'],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz),
                  visualDensity: const VisualDensity(
                    horizontal: -4,
                    vertical: -4,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _openPostMenu(post),
                ),
              ],
            ),
          ),

          if ((post['caption'] as String).isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Text(
                post['caption'] as String,
                style: const TextStyle(fontSize: 15),
                softWrap: true,
              ),
            ),

          if ((post['imageUrl'] ?? '').toString().isNotEmpty ||
              (post['imageBase64'] ?? '').toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AspectRatio(aspectRatio: 1, child: _buildImage(post)),
              ),
            ),

          if ((post['tags'] as String).isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                post['tags'] as String,
                style: const TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.w500,
                ),
                softWrap: true,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                _LiveCount(
                  path: 'posts/$postId/likesCount',
                  icon: Icons.thumb_up_alt_rounded,
                ),
                const SizedBox(width: 14),
                _LiveCount(
                  path: 'posts/$postId/commentsCount',
                  icon: Icons.comment_rounded,
                ),
                const SizedBox(width: 14),
                _LiveCount(
                  path: 'posts/$postId/sharesCount',
                  icon: Icons.share_rounded,
                ),
                const Spacer(),
              ],
            ),
          ),
          const Divider(height: 1),

          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Row(
              children: [
                _ReactionButton(
                  key: _likeKey,
                  postId: postId,
                  anchorKey: _likeKey,
                  onShowOverlay: _showReactionsOverlay,
                ),
                _ActionBtn(
                  icon: Icons.comment_outlined,
                  label: 'Comment',
                  onTap: () => _openComments(postId),
                ),
                _ActionBtn(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  onTap: _busyShare
                      ? null
                      : () async {
                          setState(() => _busyShare = true);
                          await _sharePost(postId);
                          if (mounted) setState(() => _busyShare = false);
                        },
                ),
                _SaveButton(
                  postId: postId,
                  isBusy: _busySave,
                  onBusy: (v) => setState(() => _busySave = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ===== Post options menu =====
  void _openPostMenu(Map<String, dynamic> post) {
    final postId = post['id'] as String;
    final authorId = (post['authorId'] ?? '') as String;
    final isMine = _auth.currentUser?.uid == authorId;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('View profile'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileView()),
                  );
                },
              ),
              if (isMine)
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text(
                    'Delete post',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmAndDelete(postId, authorId);
                  },
                ),
              if (!isMine)
                ListTile(
                  leading: const Icon(Icons.flag_outlined),
                  title: const Text('Report post'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Reported. Thank you.')),
                    );
                  },
                ),
              const SizedBox(height: 6),
            ],
          ),
        );
      },
    );
  }

  void _confirmAndDelete(String postId, String authorId) async {
    final isMine = _auth.currentUser?.uid == authorId;
    if (!isMine) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can delete only your own post.')),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete post?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    await _deletePost(postId);
  }

  Future<void> _deletePost(String postId) async {
    try {
      final updates = <String, Object?>{
        'posts/$postId': null,
        'post_comments/$postId': null,
        'post_reactions/$postId': null,
      };
      await _db.ref().update(updates);

      final savedSnap = await _db.ref('saved').get();
      if (savedSnap.value is Map) {
        final m = savedSnap.value as Map;
        final futures = <Future>[];
        m.forEach((uid, mp) {
          if (mp is Map && mp.containsKey(postId)) {
            futures.add(_db.ref('saved/$uid/$postId').remove());
          }
        });
        await Future.wait(futures);
      }

      final feedsSnap = await _db.ref('feeds').get();
      if (feedsSnap.value is Map) {
        final m = feedsSnap.value as Map;
        final futures = <Future>[];
        m.forEach((uid, mp) {
          if (mp is Map && mp.containsKey(postId)) {
            futures.add(_db.ref('feeds/$uid/$postId').remove());
          }
        });
        await Future.wait(futures);
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Post deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }

  Widget _buildImage(Map<String, dynamic> post) {
    final imageUrl = (post['imageUrl'] ?? '').toString();
    final base64Str = (post['imageBase64'] ?? '').toString();
    if (imageUrl.isNotEmpty) {
      return Image.network(imageUrl, fit: BoxFit.cover);
    }
    try {
      final clean = base64Str.contains('base64,')
          ? base64Str.split('base64,').last
          : base64Str;
      final Uint8List bytes = base64Decode(clean);
      return Image.memory(bytes, fit: BoxFit.cover);
    } catch (_) {
      return const SizedBox.shrink();
    }
  }

  Future<void> _openComments(String postId) async {
    final TextEditingController _c = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.72,
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Comments',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Divider(),
                Expanded(
                  child: StreamBuilder<DatabaseEvent>(
                    stream: FirebaseDatabase.instance
                        .ref('post_comments/$postId')
                        .orderByChild('createdAt')
                        .onValue,
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final data = snap.data?.snapshot.value;
                      if (data == null)
                        return const Center(child: Text('No comments yet'));
                      final map = (data as Map).map(
                        (k, v) => MapEntry(k.toString(), v),
                      );
                      final items =
                          map.entries
                              .map(
                                (e) => (e.value as Map).map(
                                  (k, v) => MapEntry(k.toString(), v),
                                ),
                              )
                              .toList()
                            ..sort(
                              (a, b) => (a['createdAt'] ?? 0).compareTo(
                                b['createdAt'] ?? 0,
                              ),
                            );
                      return ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (_, i) {
                          final c = items[i];
                          return ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.person, size: 16),
                            ),
                            title: Text(
                              (c['authorName'] ?? 'User').toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text((c['text'] ?? '').toString()),
                          );
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    left: 12,
                    right: 12,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 12,
                    top: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _c,
                          decoration: InputDecoration(
                            hintText: 'Write a comment...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send, color: Colors.blue),
                        onPressed: () async {
                          final txt = _c.text.trim();
                          if (txt.isEmpty) return;
                          final u = FirebaseAuth.instance.currentUser!;
                          final userSnap = await FirebaseDatabase.instance
                              .ref('users/${u.uid}')
                              .get();
                          final name =
                              (userSnap.value as Map?)?['name'] ??
                              (u.email?.split('@').first ?? 'you');

                          final ref = FirebaseDatabase.instance
                              .ref('post_comments/$postId')
                              .push();
                          await ref.set({
                            'id': ref.key,
                            'authorId': u.uid,
                            'authorName': name,
                            'text': txt,
                            'createdAt': ServerValue.timestamp,
                          });

                          await FirebaseDatabase.instance
                              .ref('posts/$postId/commentsCount')
                              .runTransaction((value) {
                                final v = (value ?? 0) as int;
                                return Transaction.success(v + 1);
                              });

                          _c.clear();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _sharePost(String postId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.ref('feeds/$uid/$postId').set(true);
    await _db.ref('posts/$postId/sharesCount').runTransaction((value) {
      final v = (value ?? 0) as int;
      return Transaction.success(v + 1);
    });
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Post shared to your feed')));
    }
  }

  // ===== Reaction overlay =====
  void _showReactionsOverlay(GlobalKey anchorKey, String postId) {
    _removeOverlay();

    final box = anchorKey.currentContext!.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;
    final screen = MediaQuery.of(context).size;

    final width = (screen.width - 16).clamp(220.0, 320.0);
    final overlay = OverlayEntry(
      builder: (_) {
        final top = (offset.dy - 74).clamp(8.0, screen.height - 120.0);
        final centerX = offset.dx + size.width / 2;
        final left = (centerX - width / 2).clamp(
          8.0,
          screen.width - width - 8.0,
        );

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: _removeOverlay,
                child: Container(color: Colors.transparent),
              ),
            ),
            Positioned(
              left: left,
              top: top,
              width: width,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: _ReactionRow(
                    onSelected: (type) async {
                      await _setReaction(postId, type);
                      _removeOverlay();
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context, rootOverlay: true).insert(overlay);
    _overlay = overlay;
    Future.delayed(const Duration(seconds: 3), () => _removeOverlay());
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  Future<void> _setReaction(String postId, String? newType) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final db = FirebaseDatabase.instance;
    final reactRef = db.ref('post_reactions/$postId/$uid');
    final snap = await reactRef.get();
    final prev = snap.value as String?;

    if (newType == null) {
      if (prev != null) {
        await reactRef.remove();
        await db.ref('posts/$postId/likesCount').runTransaction((value) {
          final v = (value ?? 0) as int;
          return Transaction.success(v > 0 ? v - 1 : 0);
        });
      }
      return;
    }

    if (prev == null) {
      await reactRef.set(newType);
      await db.ref('posts/$postId/likesCount').runTransaction((value) {
        final v = (value ?? 0) as int;
        return Transaction.success(v + 1);
      });
    } else if (prev != newType) {
      await reactRef.set(newType);
    }
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;

  const _ActionBtn({
    required this.icon,
    required this.label,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20, color: color ?? Colors.black87),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color ?? Colors.black87,
                      fontWeight: FontWeight.w600,
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
}

class _SaveButton extends StatelessWidget {
  final String postId;
  final bool isBusy;
  final ValueChanged<bool> onBusy;
  const _SaveButton({
    required this.postId,
    required this.isBusy,
    required this.onBusy,
  });

  @override
  Widget build(BuildContext context) {
    final _auth = FirebaseAuth.instance;
    final _db = FirebaseDatabase.instance;
    final uid = _auth.currentUser?.uid;

    if (uid == null) {
      return const _ActionBtn(icon: Icons.bookmark_border, label: 'Save');
    }

    final saveRef = _db.ref('saved/$uid/$postId');

    return StreamBuilder<DatabaseEvent>(
      stream: saveRef.onValue,
      builder: (_, snap) {
        final isSaved = (snap.data?.snapshot.value == true);
        return _ActionBtn(
          icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
          color: isSaved ? Colors.amber[800] : null,
          label: 'Save',
          onTap: isBusy
              ? null
              : () async {
                  onBusy(true);
                  try {
                    if (isSaved) {
                      await saveRef.remove();
                    } else {
                      await saveRef.set(true);
                    }
                  } finally {
                    onBusy(false);
                  }
                },
        );
      },
    );
  }
}

class _LiveCount extends StatelessWidget {
  final String path;
  final IconData icon;
  const _LiveCount({required this.path, required this.icon});
  @override
  Widget build(BuildContext context) {
    final _db = FirebaseDatabase.instance;
    return StreamBuilder<DatabaseEvent>(
      stream: _db.ref(path).onValue,
      builder: (_, snap) {
        final v = (snap.data?.snapshot.value ?? 0) as int;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.grey[700]),
            const SizedBox(width: 4),
            Text(
              '$v',
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ],
        );
      },
    );
  }
}

class _AuthorAvatar extends StatelessWidget {
  final String authorId;
  const _AuthorAvatar({required this.authorId});
  @override
  Widget build(BuildContext context) {
    final _db = FirebaseDatabase.instance;
    return StreamBuilder<DatabaseEvent>(
      stream: _db.ref('users/$authorId').onValue,
      builder: (_, snap) {
        final data = snap.data?.snapshot.value as Map<dynamic, dynamic>?;
        ImageProvider? img;
        if (data != null) {
          final photoUrl = (data['photoUrl'] ?? '') as String;
          final photoBase64 = data['photoBase64'] as String?;
          if (photoBase64 != null && photoBase64.isNotEmpty) {
            try {
              final clean = photoBase64.contains('base64,')
                  ? photoBase64.split('base64,').last
                  : photoBase64;
              img = MemoryImage(base64Decode(clean));
            } catch (_) {}
          } else if (photoUrl.isNotEmpty) {
            img = NetworkImage(photoUrl);
          }
        }
        img ??= const NetworkImage('https://i.pravatar.cc/100?img=65');
        return CircleAvatar(radius: 18, backgroundImage: img);
      },
    );
  }
}

class _AuthorNameAndTime extends StatelessWidget {
  final String authorId;
  final String? fallbackName;
  final int? createdAt;
  const _AuthorNameAndTime({
    required this.authorId,
    this.fallbackName,
    this.createdAt,
  });

  @override
  Widget build(BuildContext context) {
    final _db = FirebaseDatabase.instance;
    return StreamBuilder<DatabaseEvent>(
      stream: _db.ref('users/$authorId').onValue,
      builder: (_, snap) {
        String name = fallbackName ?? 'User';
        if (snap.data?.snapshot.value is Map) {
          final m = snap.data!.snapshot.value as Map;
          name = (m['name'] ?? name).toString();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              _formatTime(createdAt ?? 0),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        );
      },
    );
  }

  static String _formatTime(int ms) {
    try {
      final dt = DateTime.fromMillisecondsSinceEpoch(ms);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}

/// ========= Reaction button & overlay =========
class _ReactionButton extends StatelessWidget {
  final String postId;
  final GlobalKey anchorKey;
  final void Function(GlobalKey anchorKey, String postId) onShowOverlay;

  const _ReactionButton({
    super.key,
    required this.postId,
    required this.anchorKey,
    required this.onShowOverlay,
  });

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const _ActionBtn(icon: Icons.thumb_up_outlined, label: 'Like');
    }
    final reactRef = FirebaseDatabase.instance.ref(
      'post_reactions/$postId/$uid',
    );

    return StreamBuilder<DatabaseEvent>(
      stream: reactRef.onValue,
      builder: (_, snap) {
        final current = snap.data?.snapshot.value as String?;
        final label = _reactionLabel(current);
        final color = current == null ? null : Colors.blue;

        return Expanded(
          child: InkWell(
            onTap: () async {
              if (current == null) {
                await _setReaction(postId, 'like');
              } else {
                await _setReaction(postId, null);
              }
            },
            onLongPress: () => onShowOverlay(anchorKey, postId),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    key: anchorKey,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _reactionEmoji(current),
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: color ?? Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _reactionLabel(String? type) {
    switch (type) {
      case 'love':
        return 'Love';
      case 'care':
        return 'Care';
      case 'haha':
        return 'Haha';
      case 'sad':
        return 'Sad';
      case 'angry':
        return 'Angry';
      case 'like':
        return 'Like';
      default:
        return 'Like';
    }
  }

  String _reactionEmoji(String? type) {
    switch (type) {
      case 'love':
        return '❤️';
      case 'care':
        return '🥰';
      case 'haha':
        return '😂';
      case 'sad':
        return '😢';
      case 'angry':
        return '😡';
      case 'like':
        return '👍';
      default:
        return '👍';
    }
  }

  Future<void> _setReaction(String postId, String? newType) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final db = FirebaseDatabase.instance;
    final reactRef = db.ref('post_reactions/$postId/$uid');
    final snap = await reactRef.get();
    final prev = snap.value as String?;

    if (newType == null) {
      if (prev != null) {
        await reactRef.remove();
        await db.ref('posts/$postId/likesCount').runTransaction((value) {
          final v = (value ?? 0) as int;
          return Transaction.success(v > 0 ? v - 1 : 0);
        });
      }
      return;
    }

    if (prev == null) {
      await reactRef.set(newType);
      await db.ref('posts/$postId/likesCount').runTransaction((value) {
        final v = (value ?? 0) as int;
        return Transaction.success(v + 1);
      });
    } else if (prev != newType) {
      await reactRef.set(newType);
    }
  }
}

class _ReactionRow extends StatelessWidget {
  final void Function(String type) onSelected;
  const _ReactionRow({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final items = const [
      ('like', '👍', 'Like'),
      ('love', '❤️', 'Love'),
      ('care', '🥰', 'Care'),
      ('haha', '😂', 'Haha'),
      ('sad', '😢', 'Sad'),
      ('angry', '😡', 'Angry'),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: items.map((e) {
        return InkWell(
          onTap: () => onSelected(e.$1),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(e.$2, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 4),
              Text(
                e.$3,
                style: const TextStyle(fontSize: 11, color: Colors.black87),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
