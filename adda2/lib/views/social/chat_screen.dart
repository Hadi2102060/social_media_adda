import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatScreen extends StatefulWidget {
  final String username;
  final String userImage;
  final bool isOnline;
  final String userId;

  const ChatScreen({
    super.key,
    required this.username,
    required this.userImage,
    required this.isOnline,
    required this.userId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _backgroundController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _backgroundAnimation;

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _currentUserId;
  String? _conversationId;
  List<Map<String, dynamic>> _messages = [];
  StreamSubscription? _messagesSubscription;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeChat();
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
      duration: Duration(seconds: 5),
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

  void _initializeChat() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    _currentUserId = currentUser.uid;

    // Get or create conversation ID
    _conversationId = await _getOrCreateConversationId();

    // Listen for real-time messages
    _setupMessageListener();
  }

  Future<String> _getOrCreateConversationId() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return '';

    // Create a unique conversation ID based on user IDs
    final participants = [currentUser.uid, widget.userId]..sort();
    final conversationId = participants.join('_');

    // Check if conversation exists
    final conversationDoc = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .get();

    if (!conversationDoc.exists) {
      // Create new conversation
      await _firestore.collection('conversations').doc(conversationId).set({
        'participants': participants,
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSender': '',
        'unreadCount': {currentUser.uid: 0, widget.userId: 0},
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return conversationId;
  }

  void _setupMessageListener() {
    if (_conversationId == null) return;

    _messagesSubscription = _firestore
        .collection('conversations')
        .doc(_conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .listen((snapshot) {
          if (mounted) {
            setState(() {
              _messages = snapshot.docs.map((doc) {
                final data = doc.data();
                return {
                  'id': doc.id,
                  'text': data['text'] ?? '',
                  'isMe': data['senderId'] == _currentUserId,
                  'time': _formatTime(
                    data['timestamp']?.toDate() ?? DateTime.now(),
                  ),
                  'isRead': data['isRead'] ?? false,
                  'timestamp': data['timestamp']?.toDate() ?? DateTime.now(),
                  'senderId': data['senderId'],
                };
              }).toList();
            });

            // Auto-scroll to bottom when new message arrives
            Future.delayed(Duration(milliseconds: 100), () {
              if (_scrollController.hasClients) {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            });

            // Mark messages as read
            _markMessagesAsRead();
          }
        });
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }

  void _markMessagesAsRead() async {
    if (_conversationId == null || _currentUserId == null) return;

    final unreadMessages = _messages
        .where((message) => !message['isMe'] && !message['isRead'])
        .toList();

    for (var message in unreadMessages) {
      await _firestore
          .collection('conversations')
          .doc(_conversationId)
          .collection('messages')
          .doc(message['id'])
          .update({'isRead': true});
    }

    // Update conversation unread count
    if (unreadMessages.isNotEmpty) {
      await _firestore.collection('conversations').doc(_conversationId).update({
        'unreadCount.$_currentUserId': 0,
      });
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty ||
        _conversationId == null ||
        _currentUserId == null) {
      return;
    }

    final messageText = _messageController.text.trim();
    _messageController.clear();

    try {
      // Add message to Firestore
      final messageData = {
        'text': messageText,
        'senderId': _currentUserId,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      };

      await _firestore
          .collection('conversations')
          .doc(_conversationId)
          .collection('messages')
          .add(messageData);

      // Update conversation last message
      await _firestore.collection('conversations').doc(_conversationId).update({
        'lastMessage': messageText,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSender': _currentUserId,
        'unreadCount.${widget.userId}': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _fadeController.dispose();
    _slideController.dispose();
    _backgroundController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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
                      Color.lerp(
                        Colors.green.shade400,
                        Colors.green.shade500,
                        _backgroundAnimation.value,
                      )!,
                      Color.lerp(
                        Colors.teal.shade400,
                        Colors.teal.shade500,
                        _backgroundAnimation.value,
                      )!,
                      Color.lerp(
                        Colors.cyan.shade400,
                        Colors.cyan.shade500,
                        _backgroundAnimation.value,
                      )!,
                      Color.lerp(
                        Colors.blue.shade400,
                        Colors.blue.shade500,
                        _backgroundAnimation.value,
                      )!,
                    ],
                    stops: [0.0, 0.3, 0.7, 1.0],
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.4,
                      colors: [
                        Colors.white.withOpacity(0.08),
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
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: NetworkImage(widget.userImage),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.username,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: widget.isOnline
                                          ? Colors.green
                                          : Colors.grey,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    widget.isOnline ? 'Online' : 'Offline',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.video_call, color: Colors.white),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Video call feature coming soon!',
                                ),
                                backgroundColor: Colors.blue,
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.call, color: Colors.white),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Voice call feature coming soon!',
                                ),
                                backgroundColor: Colors.blue,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Messages
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
                        child: Column(
                          children: [
                            // Messages List
                            Expanded(
                              child: _messages.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.chat_bubble_outline,
                                            size: 64,
                                            color: Colors.grey[400],
                                          ),
                                          SizedBox(height: 16),
                                          Text(
                                            'No messages yet',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 16,
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'Start a conversation!',
                                            style: TextStyle(
                                              color: Colors.grey[500],
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.builder(
                                      controller: _scrollController,
                                      padding: EdgeInsets.all(16),
                                      itemCount: _messages.length,
                                      itemBuilder: (context, index) {
                                        final message = _messages[index];
                                        return Container(
                                          margin: EdgeInsets.only(bottom: 12),
                                          child: Row(
                                            mainAxisAlignment: message['isMe']
                                                ? MainAxisAlignment.end
                                                : MainAxisAlignment.start,
                                            children: [
                                              if (!message['isMe'])
                                                CircleAvatar(
                                                  radius: 16,
                                                  backgroundImage: NetworkImage(
                                                    widget.userImage,
                                                  ),
                                                ),
                                              SizedBox(width: 8),
                                              Flexible(
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 10,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: message['isMe']
                                                        ? Colors.blue
                                                        : Colors.grey[200],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        message['isMe']
                                                        ? CrossAxisAlignment.end
                                                        : CrossAxisAlignment
                                                              .start,
                                                    children: [
                                                      Text(
                                                        message['text'],
                                                        style: TextStyle(
                                                          color: message['isMe']
                                                              ? Colors.white
                                                              : Colors.black,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                      SizedBox(height: 4),
                                                      Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Text(
                                                            message['time'],
                                                            style: TextStyle(
                                                              color:
                                                                  message['isMe']
                                                                  ? Colors.white
                                                                        .withOpacity(
                                                                          0.7,
                                                                        )
                                                                  : Colors
                                                                        .grey[600],
                                                              fontSize: 10,
                                                            ),
                                                          ),
                                                          if (message['isMe']) ...[
                                                            SizedBox(width: 4),
                                                            Icon(
                                                              message['isRead']
                                                                  ? Icons
                                                                        .done_all
                                                                  : Icons.done,
                                                              color:
                                                                  message['isRead']
                                                                  ? Colors
                                                                        .lightBlueAccent
                                                                  : Colors.white
                                                                        .withOpacity(
                                                                          0.7,
                                                                        ),
                                                              size: 14,
                                                            ),
                                                          ],
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              if (message['isMe'])
                                                CircleAvatar(
                                                  radius: 16,
                                                  backgroundImage: NetworkImage(
                                                    _auth
                                                            .currentUser
                                                            ?.photoURL ??
                                                        'https://picsum.photos/40/40?random=1',
                                                  ),
                                                ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                            ),

                            // Message Input
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: Colors.grey[300]!),
                                ),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.attach_file,
                                      color: Colors.grey[600],
                                    ),
                                    onPressed: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'File attachment coming soon!',
                                          ),
                                          backgroundColor: Colors.blue,
                                        ),
                                      );
                                    },
                                  ),
                                  Expanded(
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      child: TextField(
                                        controller: _messageController,
                                        decoration: InputDecoration(
                                          hintText: 'Type a message...',
                                          border: InputBorder.none,
                                          hintStyle: TextStyle(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        onSubmitted: (value) {
                                          _sendMessage();
                                        },
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: _sendMessage,
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.send,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
}
