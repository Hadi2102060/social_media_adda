import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/messaging_provider.dart';

class ChatScreen extends StatefulWidget {
  final String username;
  final String userImage;
  final bool isOnline;
  
  const ChatScreen({
    super.key,
    required this.username,
    required this.userImage,
    required this.isOnline,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _backgroundController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _backgroundAnimation;

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  // Sample messages data
  final List<Map<String, dynamic>> messages = [
    {
      'text': 'Hey! How are you doing?',
      'isMe': false,
      'time': '10:30 AM',
      'isRead': true,
    },
    {
      'text': 'I\'m doing great! How about you?',
      'isMe': true,
      'time': '10:32 AM',
      'isRead': true,
    },
    {
      'text': 'Pretty good! Just finished my workout 💪',
      'isMe': false,
      'time': '10:35 AM',
      'isRead': true,
    },
    {
      'text': 'That\'s awesome! What exercises did you do?',
      'isMe': true,
      'time': '10:37 AM',
      'isRead': true,
    },
    {
      'text': 'Cardio and some strength training. Feeling energized!',
      'isMe': false,
      'time': '10:40 AM',
      'isRead': true,
    },
    {
      'text': 'Nice! I should start working out too 😅',
      'isMe': true,
      'time': '10:42 AM',
      'isRead': false,
    },
    {
      'text': 'You definitely should! It\'s so worth it',
      'isMe': false,
      'time': '10:45 AM',
      'isRead': false,
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
      duration: Duration(seconds: 5),
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

    // Auto-scroll to bottom after animation
    Future.delayed(Duration(milliseconds: 500), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _backgroundController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      setState(() {
        messages.add({
          'text': _messageController.text.trim(),
          'isMe': true,
          'time': _getCurrentTime(),
          'isRead': false,
        });
      });
      _messageController.clear();
      
      // Auto-scroll to bottom
      Future.delayed(Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });

      // Simulate reply after 2 seconds
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            messages.add({
              'text': _getRandomReply(),
              'isMe': false,
              'time': _getCurrentTime(),
              'isRead': false,
            });
          });
          
          // Auto-scroll to bottom
          Future.delayed(Duration(milliseconds: 100), () {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        }
      });
    }
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  String _getRandomReply() {
    final replies = [
      'That\'s interesting! 🤔',
      'I totally agree! 👍',
      'Thanks for sharing! 😊',
      'That sounds great! 🌟',
      'I\'m glad to hear that! 😄',
      'That\'s awesome! 🎉',
      'I understand what you mean! 💭',
      'That\'s a good point! 👌',
    ];
    return replies[DateTime.now().millisecond % replies.length];
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
                      Color.lerp(Colors.green.shade400, Colors.green.shade500, _backgroundAnimation.value)!,
                      Color.lerp(Colors.teal.shade400, Colors.teal.shade500, _backgroundAnimation.value)!,
                      Color.lerp(Colors.cyan.shade400, Colors.cyan.shade500, _backgroundAnimation.value)!,
                      Color.lerp(Colors.blue.shade400, Colors.blue.shade500, _backgroundAnimation.value)!,
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
                                      color: widget.isOnline ? Colors.green : Colors.grey,
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
                                content: Text('Video call feature coming soon!'),
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
                                content: Text('Voice call feature coming soon!'),
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
                              child: ListView.builder(
                                controller: _scrollController,
                                padding: EdgeInsets.all(16),
                                itemCount: messages.length,
                                itemBuilder: (context, index) {
                                  final message = messages[index];
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
                                            backgroundImage: NetworkImage(widget.userImage),
                                          ),
                                        SizedBox(width: 8),
                                        Flexible(
                                          child: Container(
                                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                            decoration: BoxDecoration(
                                              color: message['isMe'] 
                                                  ? Colors.blue 
                                                  : Colors.grey[200],
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: message['isMe'] 
                                                  ? CrossAxisAlignment.end 
                                                  : CrossAxisAlignment.start,
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
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      message['time'],
                                                      style: TextStyle(
                                                        color: message['isMe'] 
                                                            ? Colors.white.withOpacity(0.7) 
                                                            : Colors.grey[600],
                                                        fontSize: 10,
                                                      ),
                                                    ),
                                                    if (message['isMe']) ...[
                                                      SizedBox(width: 4),
                                                      Icon(
                                                        message['isRead'] 
                                                            ? Icons.done_all 
                                                            : Icons.done,
                                                        color: message['isRead'] 
                                                            ? Colors.blue 
                                                            : Colors.white.withOpacity(0.7),
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
                                            backgroundImage: NetworkImage('https://picsum.photos/40/40?random=1'),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),

                            // Typing Indicator
                            if (_isTyping)
                              Container(
                                padding: EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundImage: NetworkImage(widget.userImage),
                                    ),
                                    SizedBox(width: 8),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            'typing',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                          ),
                                          SizedBox(width: 4),
                                          SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[600]!),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
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
                                    icon: Icon(Icons.attach_file, color: Colors.grey[600]),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('File attachment coming soon!'),
                                          backgroundColor: Colors.blue,
                                        ),
                                      );
                                    },
                                  ),
                                  Expanded(
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 16),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      child: TextField(
                                        controller: _messageController,
                                        decoration: InputDecoration(
                                          hintText: 'Type a message...',
                                          border: InputBorder.none,
                                          hintStyle: TextStyle(color: Colors.grey[600]),
                                        ),
                                        onChanged: (value) {
                                          setState(() {
                                            _isTyping = value.isNotEmpty;
                                          });
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