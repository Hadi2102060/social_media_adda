import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'profile_edit.dart';
import 'privacy_settings.dart';
import 'package:adda2/views/privacy/account_settings_screen.dart';
import 'package:adda2/views/privacy/block_report_screen.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _backgroundController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _backgroundAnimation;

  String? _uid;

  final List<Map<String, dynamic>> posts = [
    {
      'image': 'https://picsum.photos/300/300?random=10',
      'likes': 234,
      'comments': 45,
      'caption': 'Beautiful sunset today! 🌅',
      'time': '2 hours ago',
    },
    {
      'image': 'https://picsum.photos/300/300?random=11',
      'likes': 156,
      'comments': 23,
      'caption': 'Coffee and coding ☕️',
      'time': '1 day ago',
    },
    {
      'image': 'https://picsum.photos/300/300?random=12',
      'likes': 89,
      'comments': 12,
      'caption': 'Weekend vibes 😎',
      'time': '3 days ago',
    },
  ];

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();

    final user = _auth.currentUser;
    _uid = user?.uid;

    _fadeController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _backgroundController = AnimationController(
      duration: Duration(seconds: 4),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );
    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.easeInOut),
    );

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

  // Custom method to handle both network and base64 images
  Widget _buildProfileImage(String imageUrl, double radius) {
    if (imageUrl.startsWith('data:image/')) {
      // Handle base64 image from Firestore
      try {
        final base64String = imageUrl.split(',').last;
        return CircleAvatar(
          radius: radius,
          backgroundImage: MemoryImage(base64Decode(base64String)),
          backgroundColor: Colors.grey[300],
        );
      } catch (e) {
        print('Error decoding base64 image: $e');
        return _buildDefaultAvatar(radius);
      }
    } else {
      // Handle network image
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(imageUrl),
        backgroundColor: Colors.grey[300],
        child: imageUrl.contains('picsum')
            ? null
            : Icon(Icons.person, size: radius, color: Colors.grey[600]),
      );
    }
  }

  // Custom method for cover image
  Widget _buildCoverImage(String imageUrl, double height, double width) {
    if (imageUrl.startsWith('data:image/')) {
      // Handle base64 image from Firestore
      try {
        final base64String = imageUrl.split(',').last;
        return Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            image: DecorationImage(
              image: MemoryImage(base64Decode(base64String)),
              fit: BoxFit.cover,
            ),
          ),
        );
      } catch (e) {
        print('Error decoding base64 cover image: $e');
        return _buildDefaultCover(height, width);
      }
    } else {
      // Handle network image
      return Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          image: DecorationImage(
            image: NetworkImage(imageUrl),
            fit: BoxFit.cover,
          ),
        ),
        child: imageUrl.contains('picsum')
            ? null
            : Icon(Icons.photo, size: 40, color: Colors.grey),
      );
    }
  }

  // Default avatar when no image is available
  Widget _buildDefaultAvatar(double radius) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[300],
      child: Icon(Icons.person, size: radius, color: Colors.grey[600]),
    );
  }

  // Default cover when no image is available
  Widget _buildDefaultCover(double height, double width) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.grey[300],
      ),
      child: Icon(Icons.photo, size: 40, color: Colors.grey[600]),
    );
  }

  // Custom method for post images
  Widget _buildPostImage(String imageUrl, double width, double height) {
    if (imageUrl.startsWith('data:image/')) {
      // Handle base64 image from Firestore
      try {
        final base64String = imageUrl.split(',').last;
        return Image.memory(
          base64Decode(base64String),
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: width,
              height: height,
              color: Colors.grey[300],
              child: Icon(Icons.photo, color: Colors.grey),
            );
          },
        );
      } catch (e) {
        print('Error decoding base64 post image: $e');
        return Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: Icon(Icons.photo, color: Colors.grey),
        );
      }
    } else {
      // Handle network image
      return Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey[300],
            child: Icon(Icons.photo, color: Colors.grey),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_uid == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'No user logged in',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    final userDocStream = _firestore.collection('users').doc(_uid).snapshots();

    return Scaffold(
      body: Stack(
        children: [
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
                    stops: [0.0, 0.3, 0.7, 1.0],
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
            child: StreamBuilder<DocumentSnapshot>(
              stream: userDocStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.white,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Error loading profile',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          style: TextStyle(color: Colors.white, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_off, size: 64, color: Colors.white),
                        SizedBox(height: 16),
                        Text(
                          'Profile not found',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProfileEdit(),
                              ),
                            );
                          },
                          child: Text('Create Profile'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final data =
                    snapshot.data!.data() as Map<String, dynamic>? ?? {};

                final name = data['name'] ?? 'No name';
                final username = data['username'] ?? 'No username';
                final bio = data['bio'] ?? '';
                final email = data['email'] ?? '';
                final followers = (data['followers'] ?? 0);
                final following = (data['following'] ?? 0);
                final postsCount = (data['posts'] ?? posts.length);
                final profileImage = data['profileImage'];
                final coverImage =
                    data['coverImage'] ??
                    'https://picsum.photos/400/200?random=2';
                final location = data['location'] ?? '';
                final website = data['website'] ?? '';
                final phone = data['phone'] ?? '';

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                              Spacer(),
                              Text(
                                'Profile',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Spacer(),
                              PopupMenuButton<String>(
                                icon: Icon(Icons.settings, color: Colors.white),
                                onSelected: (value) {
                                  switch (value) {
                                    case 'account_settings':
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              AccountSettingsScreen(),
                                        ),
                                      );
                                      break;
                                    case 'block_report':
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              BlockReportScreen(),
                                        ),
                                      );
                                      break;
                                    case 'privacy_settings':
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              PrivacySettings(),
                                        ),
                                      );
                                      break;
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'account_settings',
                                    child: Row(
                                      children: [
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
                                      children: [
                                        Icon(Icons.block, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Block & Report'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'privacy_settings',
                                    child: Row(
                                      children: [
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

                      SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Container(
                            margin: EdgeInsets.all(16),
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
                              children: [
                                Stack(
                                  children: [
                                    // Cover Image with proper base64 handling
                                    _buildCoverImage(
                                      coverImage,
                                      120,
                                      double.infinity,
                                    ),

                                    // Profile Image with proper base64 handling
                                    Positioned(
                                      bottom: 0,
                                      left: 20,
                                      child:
                                          profileImage != null &&
                                              profileImage.isNotEmpty
                                          ? _buildProfileImage(profileImage, 40)
                                          : _buildDefaultAvatar(40),
                                    ),

                                    // Edit Button
                                    Positioned(
                                      top: 10,
                                      right: 10,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.9),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: IconButton(
                                          icon: Icon(
                                            Icons.edit,
                                            color: Colors.blue,
                                          ),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ProfileEdit(),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 20),

                                Column(
                                  children: [
                                    Text(
                                      name,
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      '@$username',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    SizedBox(height: 8),

                                    // Additional profile info
                                    if (bio.isNotEmpty) ...[
                                      SizedBox(height: 8),
                                      Text(
                                        bio,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                          height: 1.4,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],

                                    if (location.isNotEmpty) ...[
                                      SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.location_on,
                                            size: 14,
                                            color: Colors.grey,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            location,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],

                                    SizedBox(height: 12),

                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        _buildStatItem(
                                          'Posts',
                                          postsCount.toString(),
                                        ),
                                        _buildStatItem(
                                          'Followers',
                                          followers.toString(),
                                        ),
                                        _buildStatItem(
                                          'Following',
                                          following.toString(),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 20),

                                    Column(
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          ProfileEdit(),
                                                    ),
                                                  );
                                                },
                                                icon: Icon(Icons.edit),
                                                label: Text('Edit Profile'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.blue,
                                                  foregroundColor: Colors.white,
                                                  padding: EdgeInsets.symmetric(
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
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          PrivacySettings(),
                                                    ),
                                                  );
                                                },
                                                icon: Icon(Icons.settings),
                                                label: Text('Settings'),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: Colors.blue,
                                                  side: BorderSide(
                                                    color: Colors.blue,
                                                  ),
                                                  padding: EdgeInsets.symmetric(
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
                                        SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          AccountSettingsScreen(),
                                                    ),
                                                  );
                                                },
                                                icon: Icon(
                                                  Icons.security,
                                                  color: Colors.orange,
                                                ),
                                                label: Text(
                                                  'Privacy & Security',
                                                ),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor:
                                                      Colors.orange,
                                                  side: BorderSide(
                                                    color: Colors.orange,
                                                  ),
                                                  padding: EdgeInsets.symmetric(
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

                      SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Posts',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 16),
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        crossAxisSpacing: 8,
                                        mainAxisSpacing: 8,
                                      ),
                                  itemCount: posts.length,
                                  itemBuilder: (context, index) {
                                    return _buildPostItem(posts[index]);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                );
              },
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
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildPostItem(Map<String, dynamic> post) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            _buildPostImage(post['image'], double.infinity, double.infinity),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                  ),
                ),
                padding: EdgeInsets.all(8),
                child: Row(
                  children: [
                    Icon(Icons.favorite, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text(
                      post['likes'].toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
