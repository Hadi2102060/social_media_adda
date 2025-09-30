import 'package:adda2/views/people_request/FriendsListScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'profile_edit.dart';
import 'privacy_settings.dart';
import 'package:adda2/views/privacy/account_settings_screen.dart';
import 'package:adda2/views/privacy/block_report_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  String? _uid;
  final ImagePicker _picker = ImagePicker();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();

    final user = _auth.currentUser;
    _uid = user?.uid;

    _fadeController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );

    _fadeController.forward();
    _scaleController.forward();
  }

  // Method to pick and update cover image from gallery
  Future<void> _updateCoverImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1440,
        maxHeight: 800,
        imageQuality: 90,
      );

      if (image != null) {
        // Show loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Updating cover...',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        );

        // Convert image to base64
        final bytes = await File(image.path).readAsBytes();
        final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

        // Update in Firestore
        await _firestore.collection('users').doc(_uid).update({
          'coverImage': base64Image,
          'updatedAt': Timestamp.now(),
        });

        // Hide loading
        Navigator.of(context).pop();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Cover photo updated successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      // Hide loading if any error
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      print('❌ Error updating cover image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text('Failed to update cover photo'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  // Custom method to handle both network and base64 images
  Widget _buildProfileImage(String? imageUrl, double radius) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return _buildDefaultAvatar(radius);
    }

    if (imageUrl.startsWith('data:image/')) {
      try {
        final base64String = imageUrl.split(',').last;
        return CircleAvatar(
          radius: radius,
          backgroundImage: MemoryImage(base64Decode(base64String)),
          backgroundColor: Colors.grey[200],
        );
      } catch (e) {
        return _buildDefaultAvatar(radius);
      }
    } else {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(imageUrl),
        backgroundColor: Colors.grey[200],
      );
    }
  }

  // Default avatar when no image is available
  Widget _buildDefaultAvatar(double radius) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[200],
      child: Icon(Icons.person, size: radius, color: Colors.grey[500]),
    );
  }

  // Custom method for post images
  Widget _buildPostImage(String? imageUrl, double width, double height) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: Icon(Icons.photo, color: Colors.grey[400], size: 30),
      );
    }

    if (imageUrl.startsWith('data:image/')) {
      try {
        final base64String = imageUrl.split(',').last;
        return Image.memory(
          base64Decode(base64String),
          width: width,
          height: height,
          fit: BoxFit.cover,
        );
      } catch (e) {
        return Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: Icon(Icons.photo, color: Colors.grey[400]),
        );
      }
    } else {
      return Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            color: Colors.grey[200],
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey[200],
            child: Icon(Icons.photo, color: Colors.grey[400]),
          );
        },
      );
    }
  }

  // Stream to get user's posts
  Stream<QuerySnapshot> _getUserPosts() {
    if (_uid == null) return Stream<QuerySnapshot>.empty();

    return _firestore
        .collection('posts')
        .where('userId', isEqualTo: _uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error) {
          return Stream<QuerySnapshot>.empty();
        });
  }

  // Stream to get user's friends count
  Stream<int> _getFriendsCount() {
    if (_uid == null) return Stream.value(0);

    return _firestore
        .collection('users')
        .doc(_uid)
        .collection('friends')
        .snapshots()
        .map((snapshot) => snapshot.docs.length)
        .handleError((error) => 0);
  }

  // Stream to get user's friends list for display
  Stream<QuerySnapshot> _getFriendsList() {
    if (_uid == null) return Stream<QuerySnapshot>.empty();

    return _firestore
        .collection('users')
        .doc(_uid)
        .collection('friends')
        .limit(9) // Show only 9 friends in profile
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    if (_uid == null) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
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
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: userDocStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              );
            }

            if (snapshot.hasError ||
                !snapshot.hasData ||
                !snapshot.data!.exists) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_off, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Profile not found',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};

            final name = data['name'] ?? 'No name';
            final username = data['username'] ?? 'No username';
            final bio = data['bio'] ?? '';
            final followers = (data['followers'] ?? 0);
            final following = (data['following'] ?? 0);
            final profileImage = data['profileImage'];
            final coverImage = data['coverImage'];
            final location = data['location'] ?? '';

            return ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: CustomScrollView(
                  slivers: [
                    // Cover Photo Section
                    SliverAppBar(
                      expandedHeight: 280,
                      stretch: true,
                      flexibleSpace: FlexibleSpaceBar(
                        stretchModes: [StretchMode.zoomBackground],
                        background: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Cover Image
                            coverImage != null && coverImage.isNotEmpty
                                ? coverImage.startsWith('data:image/')
                                      ? Image.memory(
                                          base64Decode(
                                            coverImage.split(',').last,
                                          ),
                                          fit: BoxFit.cover,
                                        )
                                      : Image.network(
                                          coverImage,
                                          fit: BoxFit.cover,
                                        )
                                : Container(
                                    color: Colors.grey[300],
                                    child: Icon(
                                      Icons.photo_camera,
                                      size: 50,
                                      color: Colors.grey[500],
                                    ),
                                  ),

                            // Gradient Overlay
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.3),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),

                            // Edit Cover Button
                            Positioned(
                              top: 16,
                              right: 16,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  icon: Icon(Icons.camera_alt, size: 20),
                                  onPressed: _updateCoverImage,
                                  color: Colors.blue,
                                  tooltip: 'Update Cover Photo',
                                ),
                              ),
                            ),

                            // Profile Info Overlay
                            Positioned(
                              left: 20,
                              right: 20,
                              bottom: 20,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      // Profile Picture
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 4,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            75,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black26,
                                              blurRadius: 10,
                                            ),
                                          ],
                                        ),
                                        child: _buildProfileImage(
                                          profileImage,
                                          70,
                                        ),
                                      ),
                                      SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 28,
                                                fontWeight: FontWeight.bold,
                                                shadows: [
                                                  Shadow(
                                                    color: Colors.black45,
                                                    blurRadius: 10,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              '@$username',
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(
                                                  0.9,
                                                ),
                                                fontSize: 16,
                                                shadows: [
                                                  Shadow(
                                                    color: Colors.black45,
                                                    blurRadius: 10,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  if (bio.isNotEmpty)
                                    Text(
                                      bio,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 14,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black45,
                                            blurRadius: 10,
                                          ),
                                        ],
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      backgroundColor: Colors.transparent,
                      automaticallyImplyLeading: false,
                    ),

                    // Main Content Section
                    SliverList(
                      delegate: SliverChildListDelegate([
                        // Stats Card
                        Container(
                          margin: EdgeInsets.all(16),
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Stats Row
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatItem(
                                    'Posts',
                                    Icons.grid_on,
                                    Colors.blue,
                                  ),
                                  _buildStatItem(
                                    'Followers',
                                    Icons.people,
                                    Colors.green,
                                  ),
                                  _buildStatItem(
                                    'Following',
                                    Icons.person_add,
                                    Colors.orange,
                                  ),
                                  _buildFriendsStatItem(),
                                ],
                              ),
                              SizedBox(height: 20),

                              // Location and Action Buttons
                              Row(
                                children: [
                                  if (location.isNotEmpty) ...[
                                    Icon(
                                      Icons.location_on,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      location,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Spacer(),
                                  ],
                                  _buildActionButton(
                                    'Edit Profile',
                                    Icons.edit,
                                    Colors.blue,
                                    () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ProfileEdit(),
                                        ),
                                      );
                                    },
                                  ),
                                  SizedBox(width: 8),
                                  _buildActionButton(
                                    'Settings',
                                    Icons.settings,
                                    Colors.grey,
                                    () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              PrivacySettings(),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Friends Section
                        Container(
                          margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Friends',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Spacer(),
                                  StreamBuilder<int>(
                                    stream: _getFriendsCount(),
                                    builder: (context, snapshot) {
                                      final count = snapshot.data ?? 0;
                                      return Text(
                                        '$count friends',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              _buildFriendsGrid(),
                              SizedBox(height: 12),
                              Center(
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            FriendsListScreen(userId: _uid!),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'See All Friends',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Posts Section Header
                        Container(
                          padding: EdgeInsets.fromLTRB(20, 10, 20, 16),
                          child: Text(
                            'Posts',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ]),
                    ),

                    // Posts Grid Section - FIXED: Now properly using SliverGrid
                    StreamBuilder<QuerySnapshot>(
                      stream: _getUserPosts(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return SliverToBoxAdapter(
                            child: Container(
                              padding: EdgeInsets.all(40),
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.blue,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return SliverToBoxAdapter(child: _buildErrorWidget());
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return SliverToBoxAdapter(
                            child: _buildNoPostsWidget(),
                          );
                        }

                        final posts = snapshot.data!.docs;

                        return SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 2,
                                mainAxisSpacing: 2,
                                childAspectRatio: 1.0,
                              ),
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final post =
                                posts[index].data() as Map<String, dynamic>;
                            return _buildPostGridItem(post);
                          }, childCount: posts.length),
                        );
                      },
                    ),

                    SliverToBoxAdapter(child: SizedBox(height: 20)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, IconData icon, Color color) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getUserPosts(),
      builder: (context, snapshot) {
        int count = 0;

        if (label == 'Posts') {
          count = snapshot.hasData ? snapshot.data!.docs.length : 0;
        } else if (label == 'Followers') {
          count = 0; // You'll need to implement this
        } else if (label == 'Following') {
          count = 0; // You'll need to implement this
        }

        return Column(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFriendsStatItem() {
    return StreamBuilder<int>(
      stream: _getFriendsCount(),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;

        return Column(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.people_alt, size: 20, color: Colors.purple),
            ),
            SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              'Friends',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionButton(
    String text,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: IconButton(
        icon: Icon(icon, size: 18, color: color),
        onPressed: onPressed,
        tooltip: text,
      ),
    );
  }

  Widget _buildFriendsGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getFriendsList(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                Icon(Icons.people_outline, size: 50, color: Colors.grey[400]),
                SizedBox(height: 8),
                Text(
                  'No friends yet',
                  style: TextStyle(color: Colors.grey[500]),
                ),
                SizedBox(height: 8),
                Text(
                  'Connect with people to see friends here',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final friends = snapshot.data!.docs;
        final rowCount = (friends.length / 3).ceil();

        return Column(
          children: List.generate(rowCount, (rowIndex) {
            return Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Row(
                children: List.generate(3, (colIndex) {
                  final index = rowIndex * 3 + colIndex;
                  if (index >= friends.length)
                    return Expanded(child: Container());

                  final friend = friends[index];
                  return Expanded(
                    child: FutureBuilder<DocumentSnapshot>(
                      future: _firestore
                          .collection('users')
                          .doc(friend.id)
                          .get(),
                      builder: (context, userSnapshot) {
                        if (userSnapshot.hasData && userSnapshot.data!.exists) {
                          final userData =
                              userSnapshot.data!.data() as Map<String, dynamic>;
                          final friendName = userData['name'] ?? 'Friend';
                          final profileImage = userData['profileImage'];

                          return Container(
                            margin: EdgeInsets.symmetric(horizontal: 4),
                            child: Column(
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey[200]!,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: _buildProfileImage(profileImage, 40),
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  friendName.split(' ')[0],
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          );
                        }
                        return Container(
                          margin: EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.person,
                                  color: Colors.grey[400],
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Friend',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                }),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'Unable to load posts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Please check your connection and try again',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() {});
            },
            child: Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoPostsWidget() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.photo_library_outlined, size: 70, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'No Posts Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'When you share photos, they will appear here',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to create post screen
            },
            icon: Icon(Icons.add_a_photo, size: 18),
            label: Text('Create First Post'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostGridItem(Map<String, dynamic> post) {
    final imageUrl = post['postImage'] ?? '';
    final likes = post['likes'] ?? 0;
    final comments = post['comments'] ?? 0;

    return Container(
      color: Colors.white,
      child: Stack(
        children: [
          _buildPostImage(imageUrl, double.infinity, double.infinity),

          // Engagement Overlay (only show if there are likes or comments)
          if (likes > 0 || comments > 0)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildEngagementItem(Icons.favorite, likes.toString()),
                    _buildEngagementItem(Icons.comment, comments.toString()),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEngagementItem(IconData icon, String count) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 12),
        SizedBox(width: 4),
        Text(
          count,
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
