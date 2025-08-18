import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _backgroundController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _backgroundAnimation;

  int _selectedTab = 0;
  bool _isLoading = false;

  final List<String> notificationTabs = ['All', 'Follows', 'Likes', 'Comments', 'Mentions'];

  // Sample notifications data
  final List<Map<String, dynamic>> allNotifications = [
    {
      'type': 'follow',
      'username': 'jane_smith',
      'userImage': 'https://picsum.photos/50/50?random=1',
      'action': 'started following you',
      'time': '2 minutes ago',
      'isRead': false,
      'isVerified': false,
    },
    {
      'type': 'like',
      'username': 'mike_wilson',
      'userImage': 'https://picsum.photos/50/50?random=2',
      'action': 'liked your post',
      'time': '5 minutes ago',
      'isRead': false,
      'postImage': 'https://picsum.photos/60/60?random=10',
    },
    {
      'type': 'comment',
      'username': 'sarah_jones',
      'userImage': 'https://picsum.photos/50/50?random=3',
      'action': 'commented: "Amazing photo! 😍"',
      'time': '10 minutes ago',
      'isRead': false,
      'postImage': 'https://picsum.photos/60/60?random=11',
    },
    {
      'type': 'mention',
      'username': 'alex_brown',
      'userImage': 'https://picsum.photos/50/50?random=4',
      'action': 'mentioned you in a comment',
      'time': '15 minutes ago',
      'isRead': false,
      'postImage': 'https://picsum.photos/60/60?random=12',
    },
    {
      'type': 'follow',
      'username': 'emma_davis',
      'userImage': 'https://picsum.photos/50/50?random=5',
      'action': 'started following you',
      'time': '1 hour ago',
      'isRead': true,
      'isVerified': true,
    },
    {
      'type': 'like',
      'username': 'david_miller',
      'userImage': 'https://picsum.photos/50/50?random=6',
      'action': 'liked your story',
      'time': '2 hours ago',
      'isRead': true,
    },
    {
      'type': 'comment',
      'username': 'lisa_wang',
      'userImage': 'https://picsum.photos/50/50?random=7',
      'action': 'commented: "Love this! ❤️"',
      'time': '3 hours ago',
      'isRead': true,
      'postImage': 'https://picsum.photos/60/60?random=13',
    },
    {
      'type': 'mention',
      'username': 'john_doe',
      'userImage': 'https://picsum.photos/50/50?random=8',
      'action': 'tagged you in a post',
      'time': '5 hours ago',
      'isRead': true,
      'postImage': 'https://picsum.photos/60/60?random=14',
    },
  ];

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
      duration: Duration(seconds: 6),
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

  List<Map<String, dynamic>> get filteredNotifications {
    if (_selectedTab == 0) {
      return allNotifications;
    }
    
    String filterType = '';
    switch (_selectedTab) {
      case 1:
        filterType = 'follow';
        break;
      case 2:
        filterType = 'like';
        break;
      case 3:
        filterType = 'comment';
        break;
      case 4:
        filterType = 'mention';
        break;
    }
    
    return allNotifications.where((notification) => 
      notification['type'] == filterType
    ).toList();
  }

  void _markAsRead(int index) {
    setState(() {
      filteredNotifications[index]['isRead'] = true;
    });
  }

  void _followUser(int index) {
    setState(() {
      // Simulate follow action
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Started following ${filteredNotifications[index]['username']}'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 1),
        ),
      );
    });
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
                      Color.lerp(Colors.lime.shade400, Colors.lime.shade500, _backgroundAnimation.value)!,
                      Color.lerp(Colors.green.shade400, Colors.green.shade500, _backgroundAnimation.value)!,
                      Color.lerp(Colors.teal.shade400, Colors.teal.shade500, _backgroundAnimation.value)!,
                      Color.lerp(Colors.cyan.shade400, Colors.cyan.shade500, _backgroundAnimation.value)!,
                    ],
                    stops: [0.0, 0.3, 0.7, 1.0],
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.bottomRight,
                      radius: 1.6,
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
                          'Notifications',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Spacer(),
                        IconButton(
                          icon: Icon(Icons.settings, color: Colors.white),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Notification settings coming soon!'),
                                backgroundColor: Colors.blue,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Notification Tabs
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: notificationTabs.length,
                        itemBuilder: (context, index) {
                          final isSelected = index == _selectedTab;
                          return Container(
                            margin: EdgeInsets.only(right: 12),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedTab = index;
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(25),
                                  border: isSelected ? null : Border.all(color: Colors.white.withOpacity(0.5)),
                                ),
                                child: Text(
                                  notificationTabs[index],
                                  style: TextStyle(
                                    color: isSelected ? Colors.lime : Colors.white,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // Notifications List
                Expanded(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 16),
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
                        child: ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: filteredNotifications.length,
                          itemBuilder: (context, index) {
                            final notification = filteredNotifications[index];
                            return _buildNotificationItem(notification, index);
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: notification['isRead'] ? Colors.grey[50] : Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification['isRead'] ? Colors.grey[200]! : Colors.blue[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // User Avatar
          Stack(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundImage: NetworkImage(notification['userImage']),
              ),
              if (notification['isVerified'] == true)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(
                      Icons.verified,
                      color: Colors.white,
                      size: 10,
                    ),
                  ),
                ),
            ],
          ),
          
          SizedBox(width: 12),
          
          // Notification Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                    ),
                    children: [
                      TextSpan(
                        text: notification['username'],
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: ' '),
                      TextSpan(text: notification['action']),
                    ],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  notification['time'],
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Action Buttons
          Column(
            children: [
              // Post Image (if available)
              if (notification['postImage'] != null)
                Container(
                  width: 50,
                  height: 50,
                  margin: EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(notification['postImage']),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              
              // Action Button
              if (notification['type'] == 'follow')
                GestureDetector(
                  onTap: () => _followUser(index),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      'Follow',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
} 