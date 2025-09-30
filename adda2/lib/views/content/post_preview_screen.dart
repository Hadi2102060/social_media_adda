import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostPreviewScreen extends StatefulWidget {
  final String image;
  final String caption;
  final String tags;
  final String filter;
  final String? location;

  const PostPreviewScreen({
    super.key,
    required this.image,
    required this.caption,
    required this.tags,
    required this.filter,
    this.location,
  });

  @override
  State<PostPreviewScreen> createState() => _PostPreviewScreenState();
}

class _PostPreviewScreenState extends State<PostPreviewScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _backgroundController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _backgroundAnimation;

  bool _isLoading = false;
  bool _isShared = false;
  bool _addToStory = false;
  bool _shareToFacebook = false;
  bool _shareToTwitter = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  // Save post to Firestore
  Future<void> _savePostToFirestore() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    // Get user data for the post
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() as Map<String, dynamic>?;

    final postData = {
      'userId': user.uid,
      'username': userData?['username'] ?? 'Unknown User',
      'userImage':
          userData?['profileImage'] ?? 'https://picsum.photos/100/100?random=1',
      'postImage': widget.image, // This will be base64 string
      'caption': widget.caption,
      'tags': widget.tags,
      'filter': widget.filter,
      'location': widget.location,
      'privacy': 'public', // You can make this dynamic based on user settings
      'likes': 0,
      'comments': 0,
      'shares': 0,
      'timestamp': FieldValue.serverTimestamp(),
      'createdAt': DateTime.now().toIso8601String(),
    };

    await _firestore.collection('posts').add(postData);
  }

  void _showShareDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check, color: Colors.white, size: 40),
              ),
              SizedBox(height: 20),
              Text(
                'Post Shared!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'Your post has been successfully shared.',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.popUntil(
                    context,
                    (route) => route.isFirst,
                  ); // Go to home
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text('Done', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.error, color: Colors.white, size: 40),
              ),
              SizedBox(height: 20),
              Text(
                'Sharing Failed',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                error,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text('Try Again', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sharePost() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Save post to Firestore
      await _savePostToFirestore();

      // Simulate additional processing time
      await Future.delayed(Duration(seconds: 1));

      setState(() {
        _isLoading = false;
        _isShared = true;
      });

      _showShareDialog();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Failed to share post: ${e.toString()}');
    }
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
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
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
                        Colors.purple.shade400,
                        Colors.purple.shade500,
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
                        Colors.white.withOpacity(0.12),
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
                          'Preview & Share',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Spacer(),
                        IconButton(
                          icon: Icon(Icons.share, color: Colors.white),
                          onPressed: _sharePost,
                        ),
                      ],
                    ),
                  ),
                ),

                // Post Preview
                Expanded(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        margin: EdgeInsets.all(16),
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
                            // Image
                            Expanded(
                              flex: 3,
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
                                  image: DecorationImage(
                                    image:
                                        widget.image.startsWith('data:image/')
                                        ? MemoryImage(
                                            _decodeBase64Image(widget.image),
                                          )
                                        : NetworkImage(widget.image)
                                              as ImageProvider,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),

                            // Caption and Info
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // User Info
                                    StreamBuilder<DocumentSnapshot>(
                                      stream: _firestore
                                          .collection('users')
                                          .doc(_auth.currentUser?.uid)
                                          .snapshots(),
                                      builder: (context, userSnapshot) {
                                        final userImage =
                                            userSnapshot.hasData &&
                                                userSnapshot.data!.exists
                                            ? (userSnapshot.data!.data()
                                                      as Map<
                                                        String,
                                                        dynamic
                                                      >)['profileImage'] ??
                                                  'https://picsum.photos/100/100?random=1'
                                            : 'https://picsum.photos/100/100?random=1';
                                        final username =
                                            userSnapshot.hasData &&
                                                userSnapshot.data!.exists
                                            ? (userSnapshot.data!.data()
                                                      as Map<
                                                        String,
                                                        dynamic
                                                      >)['username'] ??
                                                  'Unknown User'
                                            : 'Unknown User';

                                        return Row(
                                          children: [
                                            _buildUserImage(userImage, 16),
                                            SizedBox(width: 8),
                                            Text(
                                              username,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            Spacer(),
                                            Text(
                                              'now',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                    SizedBox(height: 8),

                                    // Caption
                                    if (widget.caption.isNotEmpty)
                                      Text(
                                        widget.caption,
                                        style: TextStyle(
                                          fontSize: 14,
                                          height: 1.4,
                                        ),
                                      ),

                                    // Tags
                                    if (widget.tags.isNotEmpty)
                                      Padding(
                                        padding: EdgeInsets.only(top: 8),
                                        child: Text(
                                          widget.tags,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.blue,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),

                                    SizedBox(height: 8),

                                    // Filter Info
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.filter,
                                          size: 16,
                                          color: Colors.grey[600],
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Filter: ${widget.filter}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Location Info
                                    if (widget.location != null &&
                                        widget.location!.isNotEmpty) ...[
                                      SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.location_on,
                                            size: 16,
                                            color: Colors.grey[600],
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            widget.location!,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Share Options
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Share Options
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Share Options',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 12),
                                _buildShareOption('Add to Story', _addToStory, (
                                  value,
                                ) {
                                  setState(() => _addToStory = value);
                                }, Icons.auto_stories),
                                _buildShareOption(
                                  'Share to Facebook',
                                  _shareToFacebook,
                                  (value) {
                                    setState(() => _shareToFacebook = value);
                                  },
                                  Icons.facebook,
                                ),
                                _buildShareOption(
                                  'Share to Twitter',
                                  _shareToTwitter,
                                  (value) {
                                    setState(() => _shareToTwitter = value);
                                  },
                                  Icons.flutter_dash,
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 16),

                          // Share Button
                          Container(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _sharePost,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.blue,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'Share Post',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
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
          ),
        ],
      ),
    );
  }

  // Helper method to decode base64 image
  Uint8List _decodeBase64Image(String base64String) {
    try {
      final String data = base64String.split(',').last;
      return base64.decode(data);
    } catch (e) {
      throw Exception('Invalid base64 image');
    }
  }

  // Custom method to handle both network and base64 user images
  Widget _buildUserImage(String imageUrl, double radius) {
    if (imageUrl.startsWith('data:image/')) {
      // Handle base64 image from Firestore
      try {
        final base64String = imageUrl.split(',').last;
        return CircleAvatar(
          radius: radius,
          backgroundImage: MemoryImage(base64.decode(base64String)),
          backgroundColor: Colors.grey[300],
        );
      } catch (e) {
        print('Error decoding base64 image: $e');
        return _buildDefaultUserAvatar(radius);
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

  Widget _buildDefaultUserAvatar(double radius) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[300],
      child: Icon(Icons.person, size: radius, color: Colors.grey[600]),
    );
  }

  Widget _buildShareOption(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeColor: Colors.white),
        ],
      ),
    );
  }
}
