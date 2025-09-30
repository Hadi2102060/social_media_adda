import 'package:flutter/material.dart';

class PostDetailScreen extends StatefulWidget {
  final Map<String, dynamic> post;
  
  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _backgroundController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _backgroundAnimation;

  final TextEditingController _commentController = TextEditingController();
  bool _isLiked = false;
  bool _isSaved = false;
  bool _isFollowing = false;

  // Sample comments data
  final List<Map<String, dynamic>> comments = [
    {
      'username': 'jane_smith',
      'userImage': 'https://picsum.photos/40/40?random=11',
      'comment': 'Amazing photo! Love the composition 😍',
      'time': '2 hours ago',
      'likes': 12,
      'isLiked': false,
    },
    {
      'username': 'mike_wilson',
      'userImage': 'https://picsum.photos/40/40?random=12',
      'comment': 'Where was this taken? Beautiful location!',
      'time': '3 hours ago',
      'likes': 8,
      'isLiked': false,
    },
    {
      'username': 'sarah_jones',
      'userImage': 'https://picsum.photos/40/40?random=13',
      'comment': 'The lighting is perfect! Great shot 📸',
      'time': '4 hours ago',
      'likes': 15,
      'isLiked': false,
    },
    {
      'username': 'alex_brown',
      'userImage': 'https://picsum.photos/40/40?random=14',
      'comment': 'This reminds me of my trip to Paris!',
      'time': '5 hours ago',
      'likes': 6,
      'isLiked': false,
    },
    {
      'username': 'emma_davis',
      'userImage': 'https://picsum.photos/40/40?random=15',
      'comment': 'Can you share the camera settings?',
      'time': '6 hours ago',
      'likes': 9,
      'isLiked': false,
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
    _commentController.dispose();
    super.dispose();
  }

  void _addComment() {
    if (_commentController.text.trim().isNotEmpty) {
      setState(() {
        comments.insert(0, {
          'username': 'you',
          'userImage': 'https://picsum.photos/40/40?random=1',
          'comment': _commentController.text.trim(),
          'time': 'now',
          'likes': 0,
          'isLiked': false,
        });
      });
      _commentController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Comment added!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
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
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      Color.lerp(Colors.teal.shade400, Colors.teal.shade500, _backgroundAnimation.value)!,
                      Color.lerp(Colors.cyan.shade400, Colors.cyan.shade500, _backgroundAnimation.value)!,
                      Color.lerp(Colors.blue.shade400, Colors.blue.shade500, _backgroundAnimation.value)!,
                      Color.lerp(Colors.indigo.shade400, Colors.indigo.shade500, _backgroundAnimation.value)!,
                    ],
                    stops: [0.0, 0.3, 0.7, 1.0],
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.bottomLeft,
                      radius: 1.8,
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
                          'Post Details',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Spacer(),
                        IconButton(
                          icon: Icon(Icons.more_vert, color: Colors.white),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('More options coming soon!'),
                                backgroundColor: Colors.blue,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Post Content
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
                            // Post Header
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundImage: NetworkImage(widget.post['userImage']),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.post['username'],
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          widget.post['time'],
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isFollowing = !_isFollowing;
                                      });
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: _isFollowing ? Colors.grey[300] : Colors.blue,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        _isFollowing ? 'Following' : 'Follow',
                                        style: TextStyle(
                                          color: _isFollowing ? Colors.black : Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Post Image
                            Container(
                              width: double.infinity,
                              height: 300,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                  image: NetworkImage(widget.post['postImage']),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),

                            // Action Buttons
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isLiked = !_isLiked;
                                      });
                                    },
                                    child: Icon(
                                      _isLiked ? Icons.favorite : Icons.favorite_border,
                                      color: _isLiked ? Colors.red : Colors.black,
                                      size: 28,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Icon(Icons.chat_bubble_outline, size: 28),
                                  SizedBox(width: 16),
                                  Icon(Icons.send_outlined, size: 28),
                                  Spacer(),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isSaved = !_isSaved;
                                      });
                                    },
                                    child: Icon(
                                      _isSaved ? Icons.bookmark : Icons.bookmark_border,
                                      size: 28,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Likes Count
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  Text(
                                    '${widget.post['likes']} likes',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Caption
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      style: TextStyle(color: Colors.black),
                                      children: [
                                        TextSpan(
                                          text: widget.post['username'],
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        TextSpan(text: ' '),
                                        TextSpan(text: widget.post['caption']),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'View all ${comments.length} comments',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Comments Section
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: ListView.builder(
                                  itemCount: comments.length,
                                  itemBuilder: (context, index) {
                                    final comment = comments[index];
                                    return Container(
                                      margin: EdgeInsets.only(bottom: 12),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          CircleAvatar(
                                            radius: 16,
                                            backgroundImage: NetworkImage(comment['userImage']),
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                RichText(
                                                  text: TextSpan(
                                                    style: TextStyle(color: Colors.black),
                                                    children: [
                                                      TextSpan(
                                                        text: comment['username'],
                                                        style: TextStyle(fontWeight: FontWeight.bold),
                                                      ),
                                                      TextSpan(text: ' '),
                                                      TextSpan(text: comment['comment']),
                                                    ],
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Text(
                                                      comment['time'],
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    SizedBox(width: 16),
                                                    Text(
                                                      'Reply',
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                    SizedBox(width: 16),
                                                    Text(
                                                      '${comment['likes']} likes',
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                comment['isLiked'] = !comment['isLiked'];
                                                if (comment['isLiked']) {
                                                  comment['likes']++;
                                                } else {
                                                  comment['likes']--;
                                                }
                                              });
                                            },
                                            child: Icon(
                                              comment['isLiked'] ? Icons.favorite : Icons.favorite_border,
                                              color: comment['isLiked'] ? Colors.red : Colors.grey,
                                              size: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),

                            // Comment Input
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: Colors.grey[300]!),
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundImage: NetworkImage('https://picsum.photos/40/40?random=1'),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: TextField(
                                      controller: _commentController,
                                      decoration: InputDecoration(
                                        hintText: 'Add a comment...',
                                        border: InputBorder.none,
                                        hintStyle: TextStyle(color: Colors.grey[600]),
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _addComment,
                                    child: Text(
                                      'Post',
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
} 