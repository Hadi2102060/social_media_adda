import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:adda2/views/profile/profile_view.dart';
import 'package:flutter/material.dart';
import 'package:adda2/views/social/chat_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:adda2/views/profile/profile_view_screen.dart'; // Profile screen import করুন

class DirectMessagesScreen extends StatefulWidget {
  const DirectMessagesScreen({super.key});

  @override
  State<DirectMessagesScreen> createState() => _DirectMessagesScreenState();
}

class _DirectMessagesScreenState extends State<DirectMessagesScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _backgroundController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _backgroundAnimation;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _conversations = [];
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  bool _isDarkMode = false;
  bool _isActiveStatus = true;
  StreamSubscription? _conversationsSubscription;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUsersAndConversations();
    _loadUserPreferences();
    _setupNotificationsListener();
  }

  void _initializeAnimations() {
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

  void _setupNotificationsListener() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // Real-time listener for conversations with unread messages
    _conversationsSubscription = _firestore
        .collection('conversations')
        .where('participants', arrayContains: currentUser.uid)
        .snapshots()
        .listen((snapshot) {
          _updateNotifications(snapshot);
        });
  }

  void _updateNotifications(QuerySnapshot snapshot) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    List<Map<String, dynamic>> notifications = [];

    for (var doc in snapshot.docs) {
      final conversationData = doc.data() as Map<String, dynamic>;
      final participants = List<String>.from(
        conversationData['participants'] ?? [],
      );
      final otherUserId = participants.firstWhere(
        (id) => id != currentUser.uid,
      );

      // Get user data for the other participant
      final userDoc = await _firestore
          .collection('users')
          .doc(otherUserId)
          .get();
      final userData = userDoc.data();

      if (userData != null) {
        final unreadCount =
            conversationData['unreadCount']?[currentUser.uid] ?? 0;
        if (unreadCount > 0) {
          notifications.add({
            'userId': otherUserId,
            'username': userData['username'] ?? 'Unknown User',
            'name': userData['name'] ?? '',
            'message':
                'sent you ${unreadCount > 1 ? '$unreadCount messages' : 'a message'}',
            'time': _formatTime(
              conversationData['lastMessageTime']?.toDate() ?? DateTime.now(),
            ),
            'userImage': _getProfileImage(userData),
            'conversationId': doc.id,
            'unreadCount': unreadCount,
          });
        }
      }
    }

    if (mounted) {
      setState(() {
        _notifications = notifications;
      });
    }
  }

  Future<void> _markConversationAsRead(String conversationId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      // Mark all messages as read in this conversation
      final messagesSnapshot = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .where('senderId', isNotEqualTo: currentUser.uid)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in messagesSnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      // Update conversation unread count to 0
      batch.update(_firestore.collection('conversations').doc(conversationId), {
        'unreadCount.${currentUser.uid}': 0,
      });

      await batch.commit();

      print('Successfully marked conversation $conversationId as read');
    } catch (e) {
      print('Error marking conversation as read: $e');
    }
  }

  Future<void> _loadUserPreferences() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      final userData = userDoc.data();

      if (userData != null) {
        setState(() {
          _isDarkMode = userData['darkMode'] ?? false;
          _isActiveStatus = userData['activeStatus'] ?? true;
        });
      }
    }
  }

  Future<void> _saveUserPreferences() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      await _firestore.collection('users').doc(currentUser.uid).update({
        'darkMode': _isDarkMode,
        'activeStatus': _isActiveStatus,
      });
    }
  }

  Future<void> _loadUsersAndConversations() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      print('Current User ID: ${currentUser.uid}');

      // Get all users from Firestore (excluding current user)
      final usersSnapshot = await _firestore.collection('users').get();
      print('Total users in database: ${usersSnapshot.docs.length}');

      // Convert to list of user maps
      List<Map<String, dynamic>> allUsers = [];

      for (var doc in usersSnapshot.docs) {
        if (doc.id != currentUser.uid) {
          final userData = doc.data();
          print('User Data for ${doc.id}: $userData');

          // Properly handle profile image
          String profileImage = _getProfileImage(userData);

          final userMap = {
            'uid': doc.id,
            'username': userData['username'] ?? 'Unknown User',
            'name': userData['name'] ?? '',
            'email': userData['email'] ?? '',
            'userImage': profileImage,
            'isOnline': userData['isOnline'] ?? false,
            'lastSeen': userData['lastSeen']?.toDate() ?? DateTime.now(),
            'phone': userData['phone'] ?? '',
          };

          allUsers.add(userMap);
        }
      }

      // Get current user's friends
      final currentUserDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      final currentUserData = currentUserDoc.data();

      List<Map<String, dynamic>> friends = [];
      if (currentUserData != null && currentUserData['friends'] != null) {
        final friendsList = List<String>.from(currentUserData['friends']);
        friends = allUsers
            .where((user) => friendsList.contains(user['uid']))
            .toList();
      }

      // Load existing conversations (temporary fix for index building)
      final conversationsSnapshot = await _firestore
          .collection('conversations')
          .where('participants', arrayContains: currentUser.uid)
          .get();

      List<Map<String, dynamic>> conversations = [];

      for (var doc in conversationsSnapshot.docs) {
        final conversationData = doc.data();
        final participants = List<String>.from(
          conversationData['participants'] ?? [],
        );
        final otherUserId = participants.firstWhere(
          (id) => id != currentUser.uid,
        );

        // Find user data for the other participant
        final otherUser = allUsers.firstWhere(
          (user) => user['uid'] == otherUserId,
          orElse: () => {
            'uid': otherUserId,
            'username': 'Unknown User',
            'userImage': _getDefaultProfileImage(otherUserId),
            'isOnline': false,
          },
        );

        final lastMessageTime = conversationData['lastMessageTime']?.toDate();
        final unreadCount =
            conversationData['unreadCount']?[currentUser.uid] ?? 0;

        conversations.add({
          'uid': otherUser['uid'],
          'username': otherUser['username'],
          'name': otherUser['name'],
          'userImage': otherUser['userImage'],
          'lastMessage':
              conversationData['lastMessage'] ?? 'Start a conversation',
          'time': _formatTime(lastMessageTime ?? DateTime.now()),
          'unreadCount': unreadCount,
          'isOnline': otherUser['isOnline'] ?? false,
          'isTyping': false,
          'conversationId': doc.id,
          'lastMessageTime': lastMessageTime, // For sorting
        });
      }

      // Sort conversations by last message time (client side)
      conversations.sort((a, b) {
        final timeA = a['lastMessageTime'] ?? DateTime(0);
        final timeB = b['lastMessageTime'] ?? DateTime(0);
        return timeB.compareTo(timeA); // Descending order
      });

      setState(() {
        _allUsers = allUsers;
        _friends = friends;
        _conversations = conversations;
        _isLoading = false;
      });

      print('Data loaded successfully:');
      print('- All users: ${_allUsers.length}');
      print('- Friends: ${_friends.length}');
      print('- Conversations: ${_conversations.length}');
      print('- Notifications: ${_notifications.length}');
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: _isDarkMode ? Colors.white : Colors.black,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Expanded(
                child: _notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_off,
                              size: 64,
                              color: _isDarkMode
                                  ? Colors.white38
                                  : Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No new notifications',
                              style: TextStyle(
                                color: _isDarkMode
                                    ? Colors.white70
                                    : Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'You\'re all caught up!',
                              style: TextStyle(
                                color: _isDarkMode
                                    ? Colors.white60
                                    : Colors.grey[500],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          final notification = _notifications[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(
                                notification['userImage'],
                              ),
                              radius: 24,
                            ),
                            title: Text(
                              '${notification['username']}',
                              style: TextStyle(
                                color: _isDarkMode
                                    ? Colors.white
                                    : Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notification['message'],
                                  style: TextStyle(
                                    color: _isDarkMode
                                        ? Colors.white70
                                        : Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  notification['time'],
                                  style: TextStyle(
                                    color: _isDarkMode
                                        ? Colors.white60
                                        : Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${notification['unreadCount']}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            onTap: () async {
                              // First mark as read
                              await _markConversationAsRead(
                                notification['conversationId'],
                              );

                              // Then close notification panel
                              Navigator.pop(context);

                              // Then open chat screen
                              _startChatWithUser({
                                'uid': notification['userId'],
                                'username': notification['username'],
                                'userImage': notification['userImage'],
                                'isOnline': true,
                              });
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _isDarkMode ? Colors.white30 : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Dark Mode Option
              ListTile(
                leading: Icon(
                  Icons.dark_mode,
                  color: _isDarkMode ? Colors.blue : Colors.grey[700],
                ),
                title: Text(
                  'Dark Mode',
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: Switch(
                  value: _isDarkMode,
                  onChanged: (value) {
                    setState(() {
                      _isDarkMode = value;
                    });
                    _saveUserPreferences();
                    Navigator.pop(context);
                    _showDarkModeDialog();
                  },
                  activeColor: Colors.blue,
                ),
                onTap: () {
                  setState(() {
                    _isDarkMode = !_isDarkMode;
                  });
                  _saveUserPreferences();
                  Navigator.pop(context);
                  _showDarkModeDialog();
                },
              ),

              // Active Status Option
              ListTile(
                leading: Icon(
                  Icons.online_prediction,
                  color: _isActiveStatus ? Colors.green : Colors.grey[700],
                ),
                title: Text(
                  'Active Status',
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: Switch(
                  value: _isActiveStatus,
                  onChanged: (value) {
                    setState(() {
                      _isActiveStatus = value;
                    });
                    _saveUserPreferences();
                    Navigator.pop(context);
                  },
                  activeColor: Colors.green,
                ),
              ),

              // Profile Option
              ListTile(
                leading: Icon(
                  Icons.person,
                  color: _isDarkMode ? Colors.white : Colors.black,
                ),
                title: Text(
                  'Profile',
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: _isDarkMode ? Colors.white70 : Colors.grey[600],
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfileView()),
                  );
                },
              ),

              // Help Option
              ListTile(
                leading: Icon(
                  Icons.help,
                  color: _isDarkMode ? Colors.white : Colors.black,
                ),
                title: Text(
                  'Help',
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: _isDarkMode ? Colors.white70 : Colors.grey[600],
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showHelpDialog();
                },
              ),

              // Legal & Policy Option
              ListTile(
                leading: Icon(
                  Icons.security,
                  color: _isDarkMode ? Colors.white : Colors.black,
                ),
                title: Text(
                  'Legal & Policy',
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: _isDarkMode ? Colors.white70 : Colors.grey[600],
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showLegalPolicyDialog();
                },
              ),

              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showDarkModeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
          title: Text(
            'Dark Mode',
            style: TextStyle(
              color: _isDarkMode ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            _isDarkMode
                ? 'Dark mode is now ON. The app interface will use dark colors.'
                : 'Dark mode is now OFF. The app interface will use light colors.',
            style: TextStyle(
              color: _isDarkMode ? Colors.white70 : Colors.grey[700],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK', style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
          title: Text(
            'Help & Support',
            style: TextStyle(
              color: _isDarkMode ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Text(
              'For any help or support:\n\n'
              '• Email: support@adda2.com\n'
              '• Phone: +880 XXXX-XXXXXX\n'
              '• Live Chat: Available 24/7\n\n'
              'Our support team is always ready to help you with any issues or questions.',
              style: TextStyle(
                color: _isDarkMode ? Colors.white70 : Colors.grey[700],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close', style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }

  void _showLegalPolicyDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
          title: Text(
            'Legal & Policy',
            style: TextStyle(
              color: _isDarkMode ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Text(
              'Terms of Service & Privacy Policy\n\n'
              '1. Data Protection: We protect your personal data and messages.\n'
              '2. Privacy: Your conversations are private and encrypted.\n'
              '3. Usage: This app is for personal communication only.\n'
              '4. Security: We use industry-standard security measures.\n'
              '5. Compliance: We comply with all applicable laws.\n\n'
              'By using this app, you agree to our terms and conditions.',
              style: TextStyle(
                color: _isDarkMode ? Colors.white70 : Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('I Understand', style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }

  String _getProfileImage(Map<String, dynamic> userData) {
    final profileImage = userData['profileImage'];

    // Check if profileImage exists and is valid
    if (profileImage == null || profileImage.toString().isEmpty) {
      return _getDefaultProfileImage(userData['username'] ?? 'user');
    }

    // Check if it's a base64 image
    if (profileImage.toString().contains('base64')) {
      return profileImage.toString();
    }

    // Check if it's a valid URL
    if (profileImage.toString().startsWith('http')) {
      return profileImage.toString();
    }

    // Check if it's a data:image URL
    if (profileImage.toString().startsWith('data:image')) {
      return profileImage.toString();
    }

    // Default fallback
    return _getDefaultProfileImage(userData['username'] ?? 'user');
  }

  String _getDefaultProfileImage(String identifier) {
    // Use a consistent default image based on user identifier
    return 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(identifier)}&background=random&color=fff&size=200';
  }

  Widget _buildProfileImage(
    String imageUrl,
    String username, {
    double radius = 28,
  }) {
    try {
      // Check if it's a base64 image
      if (imageUrl.contains('base64')) {
        return CircleAvatar(
          radius: radius,
          backgroundImage: MemoryImage(_base64ToImage(imageUrl)),
          child: imageUrl.contains('base64')
              ? null
              : Text(
                  username.isNotEmpty ? username[0].toUpperCase() : 'U',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: radius * 0.6,
                  ),
                ),
        );
      }

      // Check if it's a valid network image
      if (imageUrl.startsWith('http') || imageUrl.startsWith('data:image')) {
        return CircleAvatar(
          radius: radius,
          backgroundImage: NetworkImage(imageUrl),
          onBackgroundImageError: (exception, stackTrace) {
            print('Error loading image: $exception');
          },
          child: Text(
            username.isNotEmpty ? username[0].toUpperCase() : 'U',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: radius * 0.6,
            ),
          ),
        );
      }

      // Fallback to default avatar
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(_getDefaultProfileImage(username)),
        child: Text(
          username.isNotEmpty ? username[0].toUpperCase() : 'U',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: radius * 0.6,
          ),
        ),
      );
    } catch (e) {
      print('Error building profile image: $e');
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.blue,
        child: Text(
          username.isNotEmpty ? username[0].toUpperCase() : 'U',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: radius * 0.6,
          ),
        ),
      );
    }
  }

  Uint8List _base64ToImage(String base64String) {
    try {
      // Extract the base64 data from the string
      final parts = base64String.split(',');
      if (parts.length > 1) {
        base64String = parts[1];
      }

      // Decode base64 to bytes
      return base64.decode(base64String);
    } catch (e) {
      print('Error decoding base64 image: $e');
      // Return a simple placeholder image bytes
      return Uint8List(0);
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }

  List<Map<String, dynamic>> get filteredConversations {
    if (_searchQuery.isEmpty) {
      return _conversations;
    }
    return _conversations
        .where(
          (conversation) =>
              conversation['username'].toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              (conversation['name']?.toString().toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ??
                  false),
        )
        .toList();
  }

  List<Map<String, dynamic>> get filteredUsers {
    if (_searchQuery.isEmpty) {
      return [];
    }
    return _allUsers
        .where(
          (user) =>
              user['username'].toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              (user['name']?.toString().toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ??
                  false) ||
              (user['email']?.toString().toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ??
                  false),
        )
        .toList();
  }

  // Updated method to start chat with proper notification handling
  void _startChatWithUser(Map<String, dynamic> user) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      // Find the conversation ID for this user
      final participants = [currentUser.uid, user['uid']]..sort();
      final conversationId = participants.join('_');

      // Mark conversation as read before opening
      await _markConversationAsRead(conversationId);

      // Then navigate to chat screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            username: user['username'],
            userImage: user['userImage'],
            isOnline: user['isOnline'],
            userId: user['uid'],
          ),
        ),
      );
    } catch (e) {
      print('Error starting chat: $e');
      // If there's an error, still navigate to chat screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            username: user['username'],
            userImage: user['userImage'],
            isOnline: user['isOnline'],
            userId: user['uid'],
          ),
        ),
      );
    }
  }

  Future<void> _addFriend(String friendId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      await _firestore.collection('users').doc(currentUser.uid).update({
        'friends': FieldValue.arrayUnion([friendId]),
      });

      // Also add current user to the friend's friends list
      await _firestore.collection('users').doc(friendId).update({
        'friends': FieldValue.arrayUnion([currentUser.uid]),
      });

      // Refresh the data
      await _loadUsersAndConversations();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Friend added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add friend: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _conversationsSubscription?.cancel();
    _fadeController.dispose();
    _slideController.dispose();
    _backgroundController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDarkMode ? Colors.grey[900] : null,
      body: Stack(
        children: [
          // Animated Background (Dark mode হলে background change)
          if (!_isDarkMode)
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
                          Colors.pink.shade400,
                          Colors.pink.shade500,
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
                        Color.lerp(
                          Colors.indigo.shade400,
                          Colors.indigo.shade500,
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
                // App Bar - এখানে পরিবর্তন করা হয়েছে
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back,
                            color: _isDarkMode ? Colors.white : Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Spacer(),
                        Text(
                          'Messages',
                          style: TextStyle(
                            color: _isDarkMode ? Colors.white : Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Spacer(),
                        // Notification Icon
                        Stack(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.notifications,
                                color: _isDarkMode
                                    ? Colors.white
                                    : Colors.white,
                              ),
                              onPressed: _showNotifications,
                            ),
                            if (_notifications.isNotEmpty)
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  padding: EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${_notifications.length}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        // Three Dot Menu Icon
                        IconButton(
                          icon: Icon(
                            Icons.more_vert,
                            color: _isDarkMode ? Colors.white : Colors.white,
                          ),
                          onPressed: _showOptionsMenu,
                        ),
                      ],
                    ),
                  ),
                ),

                // Search Bar
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      margin: EdgeInsets.all(16),
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: _isDarkMode
                            ? Colors.grey[800]!
                            : Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: _isDarkMode
                              ? Colors.grey[600]!
                              : Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        style: TextStyle(
                          color: _isDarkMode ? Colors.white : Colors.white,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search users...',
                          hintStyle: TextStyle(
                            color: _isDarkMode
                                ? Colors.white70
                                : Colors.white.withOpacity(0.7),
                          ),
                          border: InputBorder.none,
                          icon: Icon(
                            Icons.search,
                            color: _isDarkMode ? Colors.white70 : Colors.white,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    color: _isDarkMode
                                        ? Colors.white70
                                        : Colors.white,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),

                // Conversations List or Search Results
                Expanded(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: _isDarkMode
                              ? Colors.grey[800]!
                              : Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: _isDarkMode
                              ? []
                              : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    spreadRadius: 5,
                                    blurRadius: 20,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                        ),
                        child: _isLoading
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 16),
                                    Text(
                                      'Loading conversations...',
                                      style: TextStyle(
                                        color: _isDarkMode
                                            ? Colors.white70
                                            : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : _searchQuery.isNotEmpty
                            ? _buildSearchResults()
                            : _buildConversationsList(),
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

  Widget _buildConversationsList() {
    if (_conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: _isDarkMode ? Colors.white38 : Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'No conversations yet',
              style: TextStyle(
                color: _isDarkMode ? Colors.white70 : Colors.grey[600],
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Start a chat with your friends!',
              style: TextStyle(
                color: _isDarkMode ? Colors.white60 : Colors.grey[500],
                fontSize: 14,
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _searchQuery = ' ';
                  _searchController.text = ' ';
                });
              },
              child: Text('Find Friends'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _conversations.length,
      itemBuilder: (context, index) {
        final conversation = _conversations[index];
        return Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: _isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                width: 0.5,
              ),
            ),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Stack(
              children: [
                _buildProfileImage(
                  conversation['userImage'],
                  conversation['username'],
                  radius: 28,
                ),
                if (conversation['isOnline'] && _isActiveStatus)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isDarkMode ? Colors.grey[800]! : Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    conversation['username'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: _isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                Text(
                  conversation['time'],
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white60 : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            subtitle: Row(
              children: [
                if (conversation['isTyping'])
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.keyboard, color: Colors.blue, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'typing...',
                          style: TextStyle(
                            color: Colors.blue,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Expanded(
                    child: Text(
                      conversation['lastMessage'],
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white60 : Colors.grey[600],
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (conversation['unreadCount'] > 0)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${conversation['unreadCount']}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            onTap: () async {
              // Mark as read when conversation is opened from main list
              if (conversation['unreadCount'] > 0) {
                await _markConversationAsRead(conversation['conversationId']);
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    username: conversation['username'],
                    userImage: conversation['userImage'],
                    isOnline: conversation['isOnline'],
                    userId: conversation['uid'],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSearchResults() {
    final results = filteredUsers;

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: _isDarkMode ? Colors.white38 : Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'No users found',
              style: TextStyle(
                color: _isDarkMode ? Colors.white70 : Colors.grey[600],
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try searching with different keywords',
              style: TextStyle(
                color: _isDarkMode ? Colors.white60 : Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final user = results[index];
        final isFriend = _friends.any((friend) => friend['uid'] == user['uid']);

        return Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: _isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                width: 0.5,
              ),
            ),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Stack(
              children: [
                _buildProfileImage(
                  user['userImage'],
                  user['username'],
                  radius: 28,
                ),
                if (user['isOnline'] && _isActiveStatus)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isDarkMode ? Colors.grey[800]! : Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            title: Text(
              user['username'],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: _isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            subtitle: Text(
              user['name']?.isNotEmpty == true ? user['name'] : user['email'],
              style: TextStyle(
                color: _isDarkMode ? Colors.white60 : Colors.grey[600],
                fontSize: 14,
              ),
            ),
            trailing: isFriend
                ? Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Friend',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  )
                : ElevatedButton(
                    onPressed: () {
                      _addFriend(user['uid']);
                    },
                    child: Text('Add Friend'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                    ),
                  ),
            onTap: () => _startChatWithUser(user),
          ),
        );
      },
    );
  }
}
