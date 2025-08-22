import 'package:adda/login_screen.dart';
import 'package:adda/views/content/camera_screen.dart';
import 'package:adda/views/feed/post_action_bar.dart';
import 'package:adda/views/notifications/notifications_screen.dart';
import 'package:adda/views/profile/privacy_settings.dart';
import 'package:adda/views/profile/profile_edit.dart';
import 'package:adda/views/profile/profile_view.dart';
import 'package:adda/views/search/search_screen.dart';
import 'package:adda/views/social/messenger_screen.dart';
import 'package:adda/views/social/post_detail_screen.dart';
import 'package:adda/views/stories/story_creation_screen.dart';
import 'package:adda/views/stories/story_viewer_screen.dart';
import 'package:flutter/material.dart';

// Added import for PrivacySettings

// Placeholder screens for menu
class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: Color(0xFF6a11cb),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.lock),
            title: Text('Change Password'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Change Password'),
                  content: Text('Password change feature coming soon!'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.edit),
            title: Text('Edit Profile'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileEdit()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.privacy_tip),
            title: Text('Privacy Settings'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PrivacySettings()),
              );
            },
          ),
          SwitchListTile(
            secondary: Icon(Icons.notifications),
            title: Text('Notification Settings'),
            value: true,
            onChanged: (val) {},
          ),
          ListTile(
            leading: Icon(Icons.delete_forever, color: Colors.red),
            title: Text('Delete Account', style: TextStyle(color: Colors.red)),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Delete Account'),
                  content: Text(
                    'Are you sure you want to delete your account?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class SavedScreen extends StatelessWidget {
  final List<Map<String, String>> savedPosts = [
    {
      'image': 'https://picsum.photos/200/200?random=1',
      'title': 'Beautiful Sunset',
    },
    {
      'image': 'https://picsum.photos/200/200?random=2',
      'title': 'Mountain Adventure',
    },
    {'image': 'https://picsum.photos/200/200?random=3', 'title': 'City Lights'},
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Saved'), backgroundColor: Color(0xFF6a11cb)),
      body: ListView.builder(
        itemCount: savedPosts.length,
        itemBuilder: (context, index) {
          final post = savedPosts[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: Image.network(
                post['image']!,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
              title: Text(post['title']!),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(post['title']!),
                    content: Image.network(post['image']!),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class ActivityScreen extends StatelessWidget {
  final List<Map<String, String>> notifications = [
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Activity'),
        backgroundColor: Color(0xFF6a11cb),
      ),
      body: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final n = notifications[index];
          return ListTile(
            leading: CircleAvatar(backgroundImage: NetworkImage(n['image']!)),
            title: Text('${n['user']} ${n['desc']}'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Notification'),
                  content: Text('${n['user']} ${n['desc']}'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('OK'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Color(0xFF6a11cb),
        icon: Icon(Icons.done_all),
        label: Text('Mark all as read'),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('All notifications marked as read!')),
          );
        },
      ),
    );
  }
}

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
  final String username = "Adda";

  // Who to follow
  final List<Map<String, String>> suggestions = [
    {'name': 'Ayesha', 'image': 'https://picsum.photos/40/40?random=13'},
    {'name': 'Rifat', 'image': 'https://picsum.photos/40/40?random=14'},
    {'name': 'Nabil', 'image': 'https://picsum.photos/40/40?random=15'},
  ];

  final List<String> greetings = [
    "Good Morning",
    "Good Afternoon",
    "Good Evening",
    "Welcome Back",
    "Have a great day!",
  ];
  String getGreeting() {
    int hour = DateTime.now().hour;
    if (hour < 12) return greetings[0];
    if (hour < 17) return greetings[1];
    if (hour < 20) return greetings[2];
    return greetings[3];
  }

  // Sample data for stories
  final List<Map<String, String>> stories = [
    {'name': 'You', 'image': 'https://picsum.photos/60/60?random=1'},
    {'name': 'john_doe', 'image': 'https://picsum.photos/60/60?random=2'},
    {'name': 'jane_smith', 'image': 'https://picsum.photos/60/60?random=3'},
    {'name': 'mike_wilson', 'image': 'https://picsum.photos/60/60?random=4'},
    {'name': 'sarah_jones', 'image': 'https://picsum.photos/60/60?random=5'},
    {'name': 'alex_brown', 'image': 'https://picsum.photos/60/60?random=6'},
    {'name': 'emma_davis', 'image': 'https://picsum.photos/60/60?random=7'},
  ];

  // Trending topics
  final List<String> trending = [
    // "#Flutter",
    // "#CampusLife",
    // "#Travel",
    // "#Foodie",
    // "#TechTalk",
    // "#Music",
    // "#Art",
    "Music",
    "Arts",
    "Sports",
    "Fashion",
    "Gaming",
    "Books",
    "Memes",
  ];
  int selectedTrending = 0;

  // Sample data for posts
  final List<Map<String, dynamic>> posts = [
    {
      'username': 'john_doe',
      'userImage': 'https://picsum.photos/40/40?random=10',
      'postImage': 'https://picsum.photos/400/400?random=20',
      'likes': 1234,
      'caption': 'Beautiful sunset today! 🌅 #nature #photography',
      'time': '2 hours ago',
      'reactions': {'👍': 2, '🔥': 1, '😂': 0, '😍': 3},
    },
    {
      'username': 'jane_smith',
      'userImage': 'https://picsum.photos/40/40?random=11',
      'postImage': 'https://picsum.photos/400/400?random=21',
      'likes': 856,
      'caption': 'Coffee and coding ☕️ #programming #flutter',
      'time': '4 hours ago',
      'reactions': {'👍': 1, '🔥': 2, '😂': 1, '😍': 0},
    },
    {
      'username': 'mike_wilson',
      'userImage': 'https://picsum.photos/40/40?random=12',
      'postImage': 'https://picsum.photos/400/400?random=22',
      'likes': 2341,
      'caption': 'Amazing architecture! 🏛️ #travel #architecture',
      'time': '6 hours ago',
      'reactions': {'👍': 0, '🔥': 1, '😂': 2, '��': 1},
    },
  ];

  @override
  void initState() {
    super.initState();
    _greetingController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF6F8FB),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6a11cb), Color(0xFF2575fc)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 18.0,
                vertical: 8,
              ),
              child: Row(
                children: [
                  Image.asset(
                    'assets/logo2.png', // Update with your logo's path
                    height: 50, // Adjust height as needed
                    width: 50, // Adjust width as needed
                    fit: BoxFit.contain,
                  ),

                  SizedBox(width: 12),
                  FadeTransition(
                    opacity: _greetingAnimation,
                    child: Text(
                      "$username",
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  Spacer(),
                  // Messenger Icon (custom asset)
                  IconButton(
                    icon: Image.asset(
                      'assets/messenger.png',
                      width: 26,
                      height: 26,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MessengerScreen(),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.search, color: Colors.white, size: 26),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SearchScreen()),
                      );
                    },
                  ),
                  // Three dot menu
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: Colors.white, size: 26),
                    onSelected: (value) {
                      if (value == 'settings') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SettingsScreen(),
                          ),
                        );
                      } else if (value == 'saved') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SavedScreen(),
                          ),
                        );
                      } else if (value == 'activity') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ActivityScreen(),
                          ),
                        );
                      } else if (value == 'logout') {
                        // You can add your logout logic here
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                LoginScreen(isFromRecovery: true),
                          ),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'settings',
                        child: Row(
                          children: [
                            Icon(Icons.settings, size: 20),
                            SizedBox(width: 8),
                            Text('Settings'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'saved',
                        child: Row(
                          children: [
                            Icon(Icons.bookmark, size: 20),
                            SizedBox(width: 8),
                            Text('Saved'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'activity',
                        child: Row(
                          children: [
                            Icon(Icons.notifications, size: 20),
                            SizedBox(width: 8),
                            Text('Activity'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout, size: 20),
                            SizedBox(width: 8),
                            Text('Logout'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(Duration(seconds: 1));
          setState(() {});
        },
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Status/Update Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile image outside the container, clickable
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ProfileView()),
                      );
                    },
                    child: CircleAvatar(
                      backgroundImage: NetworkImage(stories[0]['image']!),
                      radius: 22,
                      // Add a border for better visibility
                      backgroundColor: Colors.white,
                    ),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CameraScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.08),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: Color(0xFF6a11cb)),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "Share what's new...",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.emoji_emotions,
                              color: Color(0xFF2575fc),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.image, color: Color(0xFF2575fc)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Trending Topics
            Container(
              height: 44,
              margin: EdgeInsets.only(top: 2, bottom: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: trending.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedTrending = index;
                      });
                    },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      margin: EdgeInsets.only(right: 10),
                      padding: EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selectedTrending == index
                            ? Color(0xFF6a11cb)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Color(0xFF6a11cb), width: 1),
                      ),
                      child: Center(
                        child: Text(
                          trending[index],
                          style: TextStyle(
                            color: selectedTrending == index
                                ? Colors.white
                                : Color(0xFF6a11cb),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Animated Stories
            Container(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: stories.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StoryCreationScreen(),
                          ),
                        );
                      },
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 400),
                        margin: EdgeInsets.only(right: 14, top: 8, bottom: 8),
                        width: 70,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF6a11cb), Color(0xFF2575fc)],
                          ),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.15),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, color: Colors.white, size: 32),
                            SizedBox(height: 6),
                            Text(
                              "Add Story",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  final story = stories[index - 1];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StoryViewerScreen(),
                        ),
                      );
                    },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 400),
                      margin: EdgeInsets.only(right: 14, top: 8, bottom: 8),
                      width: 70,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.10),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                        border: Border.all(color: Color(0xFF6a11cb), width: 2),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              story['image']!,
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            story['name']!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6a11cb),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // // Who to follow
            // Container(
            //   margin: EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            //   padding: EdgeInsets.all(14),
            //   decoration: BoxDecoration(
            //     color: Colors.white,
            //     borderRadius: BorderRadius.circular(18),
            //     boxShadow: [
            //       BoxShadow(
            //         color: Colors.blue.withOpacity(0.07),
            //         blurRadius: 12,
            //         offset: Offset(0, 4),
            //       ),
            //     ],
            //   ),
            //   child: Row(
            //     children: [
            //       Icon(Icons.person_add_alt_1, color: Color(0xFF6a11cb)),
            //       SizedBox(width: 10),
            //       Expanded(
            //         child: Text(
            //           "Who to follow:",
            //           style: TextStyle(
            //             fontWeight: FontWeight.w600,
            //             color: Color(0xFF6a11cb),
            //           ),
            //         ),
            //       ),
            //       ...suggestions.map(
            //         (s) => Padding(
            //           padding: const EdgeInsets.symmetric(horizontal: 4),
            //           child: Column(
            //             children: [
            //               CircleAvatar(
            //                 backgroundImage: NetworkImage(s['image']!),
            //                 radius: 16,
            //               ),
            //               SizedBox(height: 2),
            //               Text(s['name']!, style: TextStyle(fontSize: 11)),
            //               TextButton(
            //                 onPressed: () {},
            //                 child: Text(
            //                   "Follow",
            //                   style: TextStyle(fontSize: 11),
            //                 ),
            //                 style: TextButton.styleFrom(
            //                   minimumSize: Size(40, 24),
            //                   padding: EdgeInsets.zero,
            //                 ),
            //               ),
            //             ],
            //           ),
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
            // Feed Section
            ...posts.map(
              (post) => FeedCard(
                post: post,
                trendingFilter: trending[selectedTrending],
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SearchScreen()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CameraScreen()),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => NotificationsScreen()),
            );
          } else {
            setState(() {
              _selectedIndex = index;
            });
            if (index == 4) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileView()),
              );
            }
          }
        },
        selectedItemColor: Color(0xFF6a11cb),
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: 'Add'),
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

class FeedCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final String trendingFilter;
  const FeedCard({super.key, required this.post, required this.trendingFilter});

  @override
  State<FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends State<FeedCard> {
  String? selectedReaction;
  bool showComments = false;
  List<Map<String, dynamic>> comments = [];
  final TextEditingController _commentController = TextEditingController();
  // For save section
  static const List<String> saveSections = [
    'Music',
    'Education',
    'Fun',
    'TV and Movies',
    'Sports',
  ];
  String? savedSection;

  @override
  void initState() {
    super.initState();
    selectedReaction = widget.post['selectedReaction'] ?? 'Like';
    comments = List<Map<String, dynamic>>.from(widget.post['comments'] ?? []);
  }

  void _handleAddComment() {
    final text = _commentController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        comments.add({'user': 'You', 'text': text, 'time': 'Just now'});
        _commentController.clear();
      });
    }
  }

  void _handleShare() {
    // Simulate sharing: add a copy of the post to your own feed (in real app, update provider/db)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Post shared to your profile!'),
        backgroundColor: Colors.blue,
      ),
    );
    // You can add logic to actually add the post to the user's feed
  }

  void _handleSave() async {
    final section = await showModalBottomSheet<String>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Save to...',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ...saveSections.map(
              (s) => ListTile(
                leading: Icon(Icons.folder),
                title: Text(s),
                onTap: () => Navigator.pop(context, s),
              ),
            ),
            SizedBox(height: 12),
          ],
        );
      },
    );
    if (section != null) {
      setState(() {
        savedSection = section;
        widget.post['isBookmarked'] = true;
        widget.post['savedSection'] = section;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved to $section'),
          backgroundColor: Colors.amber[800],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter by trending topic (simple hashtag match)
    if (!widget.post['caption'].contains(
          widget.trendingFilter.replaceAll('', ''),
        ) &&
        widget.trendingFilter != "Music") {
      return SizedBox.shrink();
    }
    return AnimatedContainer(
      duration: Duration(milliseconds: 400),
      margin: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.07),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage(widget.post['userImage']),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.post['username'],
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.more_horiz, size: 22),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          // Post Image
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PostDetailScreen(post: widget.post),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                widget.post['postImage'],
                width: double.infinity,
                height: 320,
                fit: BoxFit.cover,
              ),
            ),
          ),
          // New Custom Action Bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: PostActionBar(
              selectedReaction: selectedReaction ?? 'Like',
              isSaved: widget.post['isBookmarked'] ?? false,
              onReact: (reaction) {
                setState(() {
                  selectedReaction = reaction;
                  widget.post['selectedReaction'] = reaction;
                  if (widget.post['reactions'] != null &&
                      widget.post['reactions'] is Map) {
                    widget.post['reactions'][reaction] =
                        (widget.post['reactions'][reaction] ?? 0) + 1;
                  }
                });
              },
              onComment: () {
                setState(() {
                  showComments = !showComments;
                });
              },
              onShare: _handleShare,
              onSave: _handleSave,
            ),
          ),
          if (showComments) ...[
            Divider(height: 1, color: Colors.grey[300]),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...comments.map(
                    (c) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(radius: 14, child: Text(c['user'][0])),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c['user'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(c['text'], style: TextStyle(fontSize: 13)),
                                Text(
                                  c['time'],
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: 'Write a comment...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.send, color: Colors.blue),
                        onPressed: _handleAddComment,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          // Likes & Reactions
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Text(
                  '${widget.post['likes']} likes',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                SizedBox(width: 12),
                ...['Like', 'Love', 'Haha', 'Wow', 'Sad', 'Angry'].map((
                  reaction,
                ) {
                  int count =
                      widget.post['reactions'] != null &&
                          widget.post['reactions'][reaction] != null
                      ? widget.post['reactions'][reaction]
                      : 0;
                  if (count == 0) return SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Row(
                      children: [
                        Text(reaction, style: TextStyle(fontSize: 13)),
                        SizedBox(width: 2),
                        Text('$count', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          // Caption
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: RichText(
              text: TextSpan(
                style: TextStyle(color: Colors.black),
                children: [
                  TextSpan(
                    text: widget.post['username'],
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: ' '),
                  TextSpan(text: widget.post['caption']),
                ],
              ),
            ),
          ),
          // Time
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Text(
              widget.post['time'],
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }
}
