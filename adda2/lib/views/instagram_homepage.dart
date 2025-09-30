import 'package:adda2/views/people_request/PeopleScreen.dart';
import 'package:adda2/views/videos/VideoScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:adda2/views/profile/profile_view.dart';
import 'package:adda2/views/content/camera_screen.dart';
import 'package:adda2/views/social/direct_messages_screen.dart';
import 'package:adda2/views/social/post_detail_screen.dart';
import 'package:adda2/views/search/search_screen.dart';
import 'package:adda2/views/search/explore_screen.dart';
import 'package:adda2/views/stories/story_creation_screen.dart';
import 'package:adda2/views/stories/story_viewer_screen.dart';
import 'package:adda2/views/notifications/notifications_screen.dart';

// Define constants at the file level for global access
const Color kBlue = Color(0xFF1877F2);
const Color kBg = Color(0xFFF0F2F5);
const Color kCard = Colors.white;

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

  final List<Map<String, String>> stories = [
    {'name': 'You', 'image': 'https://picsum.photos/60/60?random=1'},
    {'name': 'john_doe', 'image': 'https://picsum.photos/60/60?random=2'},
    {'name': 'jane', 'image': 'https://picsum.photos/60/60?random=3'},
    {'name': 'mike', 'image': 'https://picsum.photos/60/60?random=4'},
    {'name': 'sarah', 'image': 'https://picsum.photos/60/60?random=5'},
    {'name': 'alex', 'image': 'https://picsum.photos/60/60?random=6'},
    {'name': 'emma', 'image': 'https://picsum.photos/60/60?random=7'},
  ];

  final Map<String, String?> savedCategoryByPost = {};

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _greetingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _greetingAnimation = CurvedAnimation(
      parent: _greetingController,
      curve: Curves.easeInOut,
    );
    _greetingController.forward();
  }

  @override
  void dispose() {
    _greetingController.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1200),
      ),
    );
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

  // Default avatar when no image is available
  Widget _buildDefaultAvatar(double radius) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[300],
      child: Icon(Icons.person, size: radius, color: Colors.grey[600]),
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
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'Please log in',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: kBg,
      appBar: _facebookAppBar(context),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
          await Future.delayed(const Duration(milliseconds: 600));
        },
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Composer Card (moved to top)
            _composerCard(),

            // Stories Row
            _storiesRow(),

            // Posts Section - SIMPLIFIED QUERY
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('posts')
                  .where('privacy', isEqualTo: 'public')
                  .orderBy('timestamp', descending: true)
                  .limit(20)
                  .snapshots(),
              builder: (context, postsSnapshot) {
                if (postsSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (postsSnapshot.hasError) {
                  return _buildErrorState(
                    'Error loading posts: ${postsSnapshot.error}',
                  );
                }

                if (!postsSnapshot.hasData ||
                    postsSnapshot.data!.docs.isEmpty) {
                  return _buildEmptyPostsState();
                }

                List<QueryDocumentSnapshot> postDocs = postsSnapshot.data!.docs;
                List<Map<String, dynamic>> fetchedPosts = postDocs.map((doc) {
                  Map<String, dynamic> data =
                      doc.data() as Map<String, dynamic>;
                  data['id'] = doc.id;
                  return data;
                }).toList();

                return Column(
                  children: fetchedPosts
                      .map(
                        (post) => FeedCard(
                          key: ValueKey(post['id']),
                          post: post,
                          initialSavedCategory: savedCategoryByPost[post['id']],
                          onSaveCategoryChanged: (cat) {
                            setState(
                              () => savedCategoryByPost[post['id']] = cat,
                            );
                            if (cat == null) {
                              _toast("Removed from Saved");
                            } else {
                              _toast("Saved to $cat");
                            }
                          },
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: _bottomBar(context),
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: Colors.grey, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {});
            },
            child: Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kBlue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPostsState() {
    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.feed, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No posts yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Be the first to share something!',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CameraScreen()),
              );
            },
            child: Text('Create First Post'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kBlue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _facebookAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: kBlue,
      elevation: 0,
      titleSpacing: 12,
      title: const Text(
        "ADDA",
        style: TextStyle(
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
          color: Colors.white,
        ),
      ),
      actions: [
        _circleIcon(
          icon: Icons.search,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            );
          },
        ),
        _circleIcon(
          icon: Icons.message,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DirectMessagesScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _circleIcon({required IconData icon, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }

  Widget _composerCard() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore
          .collection('users')
          .doc(_auth.currentUser?.uid)
          .snapshots(),
      builder: (context, userSnapshot) {
        final profileImage = userSnapshot.hasData && userSnapshot.data!.exists
            ? (userSnapshot.data!.data()
                      as Map<String, dynamic>)['profileImage'] ??
                  'https://picsum.photos/60/60?random=1'
            : 'https://picsum.photos/60/60?random=1';

        return Container(
          margin: const EdgeInsets.only(top: 8),
          color: kCard,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfileView()),
                      );
                    },
                    child: _buildProfileImage(profileImage, 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CameraScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: kBg,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Text(
                          "What's on your mind?",
                          style: TextStyle(color: Colors.black54, fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _composerAction(
                    icon: Icons.video_call,
                    label: "Live",
                    onTap: () {
                      _toast("Live feature coming soon!");
                    },
                  ),
                  _composerAction(
                    icon: Icons.photo_library_rounded,
                    label: "Photo",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CameraScreen()),
                      );
                    },
                  ),
                  _composerAction(
                    icon: Icons.poll_rounded,
                    label: "Quick Poll",
                    onTap: () {
                      _toast("Poll created (demo)");
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _composerAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: kBlue),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _storiesRow() {
    return Container(
      color: kCard,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SizedBox(
        height: 110,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: stories.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _storyCard(
                isCreate: true,
                name: "Create Story",
                imageUrl: stories[0]['image']!,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const StoryCreationScreen(),
                    ),
                  );
                },
              );
            }
            final s = stories[index - 1];
            return _storyCard(
              isCreate: false,
              name: s['name']!,
              imageUrl: s['image']!,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StoryViewerScreen()),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _storyCard({
    required bool isCreate,
    required String name,
    required String imageUrl,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: kBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.person, color: Colors.grey),
                      );
                    },
                  ),
                ),
                if (isCreate)
                  Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.only(right: 2, bottom: 2),
                    decoration: const BoxDecoration(
                      color: kBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, size: 16, color: Colors.white),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                name,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomBar(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore
          .collection('users')
          .doc(_auth.currentUser?.uid)
          .snapshots(),
      builder: (context, userSnapshot) {
        final profileImage = userSnapshot.hasData && userSnapshot.data!.exists
            ? (userSnapshot.data!.data()
                      as Map<String, dynamic>)['profileImage'] ??
                  'https://picsum.photos/40/40?random=1'
            : 'https://picsum.photos/40/40?random=1';

        return BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: kCard,
          currentIndex: _selectedIndex,
          selectedItemColor: kBlue,
          unselectedItemColor: Colors.grey,
          onTap: (index) {
            _handleBottomNavTap(index, context);
          },
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.video_library),
              label: 'Video',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.add_circle),
              label: 'Add',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.group),
              label: 'People',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.notifications),
              label: 'Notifications',
            ),
            BottomNavigationBarItem(
              icon: CircleAvatar(
                radius: 12,
                backgroundImage: NetworkImage(profileImage),
                onBackgroundImageError: (exception, stackTrace) {
                  // Handle error
                },
                child: profileImage.contains('picsum')
                    ? null
                    : Icon(Icons.person, size: 12),
              ),
              label: 'Profile',
            ),
          ],
        );
      },
    );
  }

  void _handleBottomNavTap(int index, BuildContext context) {
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const VideoScreen()),
      );
      return;
    }
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CameraScreen()),
      );
      return;
    }
    if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PeopleScreen()),
      );
      return;
    }
    if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
      );
      return;
    }
    if (index == 5) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileView()),
      );
      return;
    }
    setState(() => _selectedIndex = index);
  }
}




// FeedCard and _Reaction classes with base64 image support
class FeedCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final String? initialSavedCategory;
  final ValueChanged<String?> onSaveCategoryChanged;

  const FeedCard({
    super.key,
    required this.post,
    required this.initialSavedCategory,
    required this.onSaveCategoryChanged,
  });

  @override
  State<FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends State<FeedCard> {
  static const List<_Reaction> reactions = [
    _Reaction('Like', '👍', kBlue),
    _Reaction('Love', '❤️', Color(0xFFE0245E)),
    _Reaction('Care', '🥰', Color(0xFFFFA000)),
    _Reaction('Haha', '😆', Color(0xFFFFC107)),
    _Reaction('Sad', '😢', Color(0xFF6D4C41)),
    _Reaction('Angry', '😣', Color(0xFFDD2C00)),
  ];

  _Reaction? selectedReaction;
  late int likeBase;
  late int commentsCountBase;
  late int sharesCountBase;

  final List<Map<String, dynamic>> comments = [];

  String? savedCategory;

  final _likeButtonKey = GlobalKey();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    likeBase = (widget.post['likes'] ?? 0) as int;
    commentsCountBase = (widget.post['comments'] ?? 0) as int;
    sharesCountBase = (widget.post['shares'] ?? 0) as int;
    savedCategory = widget.initialSavedCategory;
    _checkUserReaction();
    _loadComments();
  }

  // Check if current user has already reacted to this post
  void _checkUserReaction() async {
    try {
      final reactionDoc = await _firestore
          .collection('posts')
          .doc(widget.post['id'])
          .collection('reactions')
          .doc(_auth.currentUser!.uid)
          .get();

      if (reactionDoc.exists) {
        final reactionData = reactionDoc.data();
        final reactionType = reactionData?['reactionType'] ?? 'like';
        final matchingReaction = reactions.firstWhere(
          (r) => r.name.toLowerCase() == reactionType.toLowerCase(),
          orElse: () => reactions.first,
        );

        if (mounted) {
          setState(() {
            selectedReaction = matchingReaction;
          });
        }
      }
    } catch (e) {
      print('Error checking user reaction: $e');
    }
  }

  // Load comments from Firestore
  void _loadComments() async {
    try {
      final commentsSnapshot = await _firestore
          .collection('posts')
          .doc(widget.post['id'])
          .collection('comments')
          .orderBy('timestamp', descending: false)
          .get();

      if (mounted) {
        setState(() {
          comments.clear();
          comments.addAll(
            commentsSnapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                'userId': data['userId'],
                'userName': data['userName'] ?? 'User',
                'userImage': data['userImage'] ?? '',
                'text': data['text'],
                'timestamp': data['timestamp'],
              };
            }),
          );
        });
      }
    } catch (e) {
      print('Error loading comments: $e');
    }
  }

  // Show toast message
  void _showToast(String msg) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1200),
      ),
    );
  }

  int get displayedLikes => likeBase;
  int get displayedComments => comments.length;
  int get displayedShares => sharesCountBase;

  void _toggleLikeQuick() {
    setState(() {
      if (selectedReaction == null) {
        selectedReaction = reactions.first;
        _updateReactionInFirestore('like');
      } else {
        if (selectedReaction!.name == 'Like') {
          selectedReaction = null;
          _removeReactionFromFirestore();
        } else {
          selectedReaction = reactions.first;
          _updateReactionInFirestore('like');
        }
      }
    });
  }

  void _updateReactionInFirestore(String reactionType) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final postRef = _firestore.collection('posts').doc(widget.post['id']);
      final reactionRef = postRef.collection('reactions').doc(currentUser.uid);

      // Check if user already reacted
      final existingReaction = await reactionRef.get();

      if (existingReaction.exists) {
        _showToast("You already reacted to this post");
        return;
      }

      // Add or update reaction
      await reactionRef.set({
        'userId': currentUser.uid,
        'userName': currentUser.displayName ?? 'User',
        'userImage': currentUser.photoURL ?? '',
        'reactionType': reactionType,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update likes count in post document
      final postDoc = await postRef.get();
      final currentLikes = (postDoc.data()?['likes'] ?? 0) as int;
      await postRef.update({'likes': currentLikes + 1});

      // Update local state
      if (mounted) {
        setState(() {
          likeBase = currentLikes + 1;
        });
      }
    } catch (e) {
      print('Error updating reaction: $e');
      _showToast("Error updating reaction");
    }
  }

  void _removeReactionFromFirestore() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final postRef = _firestore.collection('posts').doc(widget.post['id']);
      final reactionRef = postRef.collection('reactions').doc(currentUser.uid);

      // Remove reaction
      await reactionRef.delete();

      // Update likes count in post document
      final postDoc = await postRef.get();
      final currentLikes = (postDoc.data()?['likes'] ?? 0) as int;
      await postRef.update({'likes': currentLikes > 0 ? currentLikes - 1 : 0});

      // Update local state
      if (mounted) {
        setState(() {
          likeBase = currentLikes > 0 ? currentLikes - 1 : 0;
        });
      }
    } catch (e) {
      print('Error removing reaction: $e');
      _showToast("Error removing reaction");
    }
  }

  void _pickReaction() async {
    final RenderBox? renderBox =
        _likeButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);

    final chosen = await showGeneralDialog<_Reaction>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withOpacity(0.2),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.topLeft,
          child: Transform.translate(
            offset: Offset(
              offset.dx.clamp(0, MediaQuery.of(context).size.width - 300),
              offset.dy - 60,
            ),
            child: Material(
              color: kCard,
              borderRadius: BorderRadius.circular(30),
              elevation: 4,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: reactions
                        .map(
                          (r) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context, r),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    r.emoji,
                                    style: const TextStyle(fontSize: 28),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    r.name,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: r.color,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.8,
            end: 1.0,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: child,
        );
      },
    );

    if (mounted && chosen != null) {
      setState(() {
        selectedReaction = chosen;
        _updateReactionInFirestore(chosen.name.toLowerCase());
      });
    }
  }

  void _showLikesList() async {
    try {
      final reactionsSnapshot = await _firestore
          .collection('posts')
          .doc(widget.post['id'])
          .collection('reactions')
          .orderBy('timestamp', descending: true)
          .get();

      final reactions = reactionsSnapshot.docs;

      if (reactions.isEmpty) {
        _showToast("No likes yet");
        return;
      }

      showModalBottomSheet(
        context: context,
        backgroundColor: kCard,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (context) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.6,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  "Likes",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: reactions.length,
                    itemBuilder: (context, index) {
                      final reaction = reactions[index];
                      final data = reaction.data();
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: kBg,
                          child:
                              data['userImage'] != null &&
                                  data['userImage'].isNotEmpty
                              ? Image.network(
                                  data['userImage'],
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(Icons.person, color: kBlue);
                                  },
                                )
                              : Icon(Icons.person, color: kBlue),
                        ),
                        title: Text(
                          data['userName'] ?? 'User',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'Reacted with ${data['reactionType']}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        trailing: Text(
                          _getReactionEmoji(data['reactionType']),
                          style: TextStyle(fontSize: 20),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      print('Error fetching likes: $e');
      _showToast("Error loading likes");
    }
  }

  String _getReactionEmoji(String reactionType) {
    switch (reactionType.toLowerCase()) {
      case 'love':
        return '❤️';
      case 'care':
        return '🥰';
      case 'haha':
        return '😆';
      case 'sad':
        return '😢';
      case 'angry':
        return '😣';
      default:
        return '👍';
    }
  }

  void _openComments() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kCard,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            top: 8,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Comments (${comments.length})",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: comments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.mode_comment_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No comments yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Be the first to comment!',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: comments.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, index) {
                          final comment = comments[index];
                          return ListTile(
                            dense: true,
                            leading:
                                comment['userImage'] != null &&
                                    comment['userImage'].isNotEmpty
                                ? CircleAvatar(
                                    backgroundImage: NetworkImage(
                                      comment['userImage'],
                                    ),
                                    radius: 18,
                                  )
                                : CircleAvatar(
                                    backgroundColor: kBg,
                                    radius: 18,
                                    child: Icon(
                                      Icons.person,
                                      color: kBlue,
                                      size: 18,
                                    ),
                                  ),
                            title: Text(
                              comment['userName'] ?? "User",
                              style: TextStyle(fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              comment['text'] ?? "",
                              style: TextStyle(fontSize: 14),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        hintText: "Write a comment…",
                        isDense: true,
                        filled: true,
                        fillColor: kBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () async {
                      if (controller.text.trim().isEmpty) return;

                      try {
                        final currentUser = _auth.currentUser;
                        if (currentUser == null) return;

                        // Add comment to Firestore
                        await _firestore
                            .collection('posts')
                            .doc(widget.post['id'])
                            .collection('comments')
                            .add({
                              'userId': currentUser.uid,
                              'userName': currentUser.displayName ?? 'User',
                              'userImage': currentUser.photoURL ?? '',
                              'text': controller.text.trim(),
                              'timestamp': FieldValue.serverTimestamp(),
                            });

                        // Reload comments
                        _loadComments();

                        // Clear text field
                        controller.clear();

                        _showToast("Comment added");
                      } catch (e) {
                        print('Error adding comment: $e');
                        _showToast("Error adding comment");
                      }
                    },
                    icon: const Icon(Icons.send),
                    color: kBlue,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _openShareSheet() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: kCard,
      showDragHandle: true,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 6),
          const Text(
            "Share Post",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          ListTile(
            leading: const Icon(Icons.public),
            title: const Text("Share to Feed"),
            onTap: () => Navigator.pop(context, "feed"),
          ),
          ListTile(
            leading: const Icon(Icons.message_outlined),
            title: const Text("Share via Direct Message"),
            onTap: () => Navigator.pop(context, "dm"),
          ),
          ListTile(
            leading: const Icon(Icons.link),
            title: const Text("Copy Link"),
            onTap: () => Navigator.pop(context, "link"),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );

    if (choice == null) return;
    setState(() {
      sharesCountBase += 1;
    });
    final messenger = ScaffoldMessenger.of(context);
    if (choice == "feed") {
      messenger.showSnackBar(
        const SnackBar(content: Text("Shared to Feed (demo)")),
      );
    } else if (choice == "dm") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DirectMessagesScreen()),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text("Link copied (demo)")),
      );
    }
  }

  void _openMoreOptions() async {
    final List<MenuOption> options = [
      MenuOption(
        icon: Icons.add_circle_outline,
        title: "(+) Interested",
        color: Colors.green,
        iconColor: Colors.green,
      ),
      MenuOption(
        icon: Icons.remove_circle_outline,
        title: "(-) Not interested",
        color: Colors.orange,
        iconColor: Colors.orange,
      ),
      MenuOption(
        icon: Icons.bookmark_border,
        title: "Save Post",
        color: kBlue,
        iconColor: kBlue,
      ),
      MenuOption(
        icon: Icons.visibility_off,
        title: "Hide Post",
        color: Colors.grey,
        iconColor: Colors.grey,
      ),
      MenuOption(
        icon: Icons.report_problem,
        title: "Report Post",
        color: Colors.red,
        iconColor: Colors.red,
      ),
      MenuOption(
        icon: Icons.notifications_none,
        title: "Turn on notifications for this post",
        color: Colors.purple,
        iconColor: Colors.purple,
      ),
      MenuOption(
        icon: Icons.link,
        title: "Copy Link",
        color: Colors.teal,
        iconColor: Colors.teal,
      ),
    ];

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with gradient
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kBlue.withOpacity(0.1), kBlue.withOpacity(0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    // Drag handle
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Post Options",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Choose an action for this post",
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              // Scrollable options
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: Scrollbar(
                  thumbVisibility: true,
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: options.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final option = options[index];
                      return _buildMenuOption(option);
                    },
                  ),
                ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey[200]!)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuOption(MenuOption option) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          _handleMenuOption(option.title);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: option.color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: option.color.withOpacity(0.1), width: 1),
          ),
          child: Row(
            children: [
              // Icon with background
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: option.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(option.icon, color: option.iconColor, size: 20),
              ),
              const SizedBox(width: 16),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (option.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        option.subtitle!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ),
              // Chevron icon
              Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _handleMenuOption(String option) {
    switch (option) {
      case "(+) Interested":
        _showToast("Marked as interested");
        break;
      case "(-) Not interested":
        _showToast("Marked as not interested");
        break;
      case "Save Post":
        _handleSaveFromOptions();
        break;
      case "Hide Post":
        _showToast("Post hidden");
        break;
      case "Report Post":
        _showReportDialog();
        break;
      case "Turn on notifications for this post":
        _showToast("Notifications turned on for this post");
        break;
      case "Copy Link":
        _showToast("Link copied");
        break;
    }
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Report Post", style: TextStyle(color: Colors.red)),
        content: Text(
          "Are you sure you want to report this post? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showToast("Post reported successfully");
            },
            child: Text("Report", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _handleSaveFromOptions() {
    final categories = ["Music", "Education", "TV & Movies", "Sports"];
    showModalBottomSheet<String?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kBlue.withOpacity(0.1), kBlue.withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    "Save to…",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Choose a category to save this post",
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            // Categories
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: categories
                    .map(
                      (c) => ChoiceChip(
                        label: Text(
                          c,
                          style: TextStyle(
                            color: savedCategory == c ? Colors.white : kBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        selected: savedCategory == c,
                        selectedColor: kBlue,
                        backgroundColor: kBlue.withOpacity(0.1),
                        checkmarkColor: Colors.white,
                        onSelected: (_) {
                          Navigator.pop(context, c);
                          setState(() {
                            savedCategory = c;
                          });
                          widget.onSaveCategoryChanged(c);
                          _showToast("Saved to $c");
                        },
                      ),
                    )
                    .toList(),
              ),
            ),

            // Remove option
            if (savedCategory != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context, null);
                    setState(() {
                      savedCategory = null;
                    });
                    widget.onSaveCategoryChanged(null);
                    _showToast("Removed from Saved");
                  },
                  child: Text(
                    "Remove from Saved",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Format timestamp to readable time
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown time';

    try {
      DateTime postTime;

      if (timestamp is Timestamp) {
        postTime = timestamp.toDate();
      } else if (timestamp is String) {
        postTime = DateTime.parse(timestamp);
      } else {
        return 'Unknown time';
      }

      final now = DateTime.now();
      final difference = now.difference(postTime);

      if (difference.inSeconds < 60) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${postTime.day}/${postTime.month}/${postTime.year}';
      }
    } catch (e) {
      print('Error formatting timestamp: $e');
      return 'Unknown time';
    }
  }

  // Custom method to handle both network and base64 images
  Widget _buildUserImage(String imageUrl, double radius) {
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
        print('Error decoding base64 user image: $e');
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, size: 64, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'Failed to load image',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          },
        );
      } catch (e) {
        print('Error decoding base64 post image: $e');
        return Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, size: 64, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'Failed to load image',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, size: 64, color: Colors.grey),
                SizedBox(height: 8),
                Text(
                  'Failed to load image',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReacted = selectedReaction != null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      color: kCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 6, 6),
            child: Row(
              children: [
                _buildUserImage(
                  widget.post['userImage'] ?? 'https://picsum.photos/40/40',
                  18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.post['username'] ?? 'Unknown',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _formatTimestamp(widget.post['timestamp']),
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz),
                  onPressed: _openMoreOptions,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              widget.post['caption'] ?? '',
              style: const TextStyle(fontSize: 14.5),
            ),
          ),
          if (widget.post['postImage'] != null)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PostDetailScreen(post: widget.post),
                  ),
                );
              },
              child: _buildPostImage(
                widget.post['postImage'],
                double.infinity,
                320,
              ),
            ),
          // Fixed Like, Comment, Share Count Section
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                // Like count with click functionality
                if (displayedLikes > 0) ...[
                  GestureDetector(
                    onTap: _showLikesList,
                    child: Row(
                      children: [
                        Text(
                          selectedReaction?.emoji ?? '👍',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$displayedLikes',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                ],

                // Comment count
                if (displayedComments > 0) ...[
                  GestureDetector(
                    onTap: _openComments,
                    child: Text(
                      '$displayedComments comments',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],

                // Share count
                if (displayedShares > 0) ...[
                  Text(
                    '$displayedShares shares',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],

                // Show message when no interactions
                if (displayedLikes == 0 &&
                    displayedComments == 0 &&
                    displayedShares == 0)
                  Text(
                    'No interactions yet',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Action Buttons Row
          Row(
            children: [
              Expanded(
                child: InkWell(
                  key: _likeButtonKey,
                  onTap: _toggleLikeQuick,
                  onLongPress: _pickReaction,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          selectedReaction?.emoji ?? '👍',
                          style: TextStyle(
                            fontSize: 20,
                            color: isReacted
                                ? selectedReaction!.color
                                : Colors.black54,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            selectedReaction?.name ?? 'Like',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: isReacted
                                  ? selectedReaction!.color
                                  : Colors.black54,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: _openComments,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.mode_comment_outlined,
                          size: 20,
                          color: Colors.black54,
                        ),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Comment',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.black54,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: _openShareSheet,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.share_outlined,
                          size: 20,
                          color: Colors.black54,
                        ),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Share',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.black54,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }
}

class _Reaction {
  final String name;
  final String emoji;
  final Color color;
  const _Reaction(this.name, this.emoji, this.color);
}

class MenuOption {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color color;
  final Color iconColor;

  const MenuOption({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.color,
    required this.iconColor,
  });
}
