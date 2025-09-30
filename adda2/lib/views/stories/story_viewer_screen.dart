import 'package:flutter/material.dart';

class StoryViewerScreen extends StatefulWidget {
  const StoryViewerScreen({super.key});

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _backgroundController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _backgroundAnimation;

  int _currentStoryIndex = 0;
  double _progress = 0.0;
  bool _isPaused = false;

  // Sample stories data
  final List<Map<String, dynamic>> stories = [
    {
      'username': 'john_doe',
      'userImage': 'https://picsum.photos/40/40?random=1',
      'storyImage': 'https://picsum.photos/400/700?random=10',
      'time': '2 hours ago',
      'isViewed': false,
    },
    {
      'username': 'jane_smith',
      'userImage': 'https://picsum.photos/40/40?random=2',
      'storyImage': 'https://picsum.photos/400/700?random=11',
      'time': '1 hour ago',
      'isViewed': false,
    },
    {
      'username': 'mike_wilson',
      'userImage': 'https://picsum.photos/40/40?random=3',
      'storyImage': 'https://picsum.photos/400/700?random=12',
      'time': '30 min ago',
      'isViewed': false,
    },
    {
      'username': 'sarah_jones',
      'userImage': 'https://picsum.photos/40/40?random=4',
      'storyImage': 'https://picsum.photos/400/700?random=13',
      'time': '15 min ago',
      'isViewed': false,
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
      duration: Duration(seconds: 4),
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

    // Start story progress
    _startStoryProgress();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  void _startStoryProgress() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted && !_isPaused) {
        setState(() {
          _progress += 0.01;
        });
        
        if (_progress >= 1.0) {
          _nextStory();
        } else {
          _startStoryProgress();
        }
      }
    });
  }

  void _nextStory() {
    if (_currentStoryIndex < stories.length - 1) {
      setState(() {
        _currentStoryIndex++;
        _progress = 0.0;
      });
      _startStoryProgress();
    } else {
      Navigator.pop(context);
    }
  }

  void _previousStory() {
    if (_currentStoryIndex > 0) {
      setState(() {
        _currentStoryIndex--;
        _progress = 0.0;
      });
      _startStoryProgress();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStory = stories[_currentStoryIndex];
    
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
                      Color.lerp(Colors.deepOrange.shade400, Colors.deepOrange.shade500, _backgroundAnimation.value)!,
                      Color.lerp(Colors.orange.shade400, Colors.orange.shade500, _backgroundAnimation.value)!,
                      Color.lerp(Colors.amber.shade400, Colors.amber.shade500, _backgroundAnimation.value)!,
                      Color.lerp(Colors.yellow.shade400, Colors.yellow.shade500, _backgroundAnimation.value)!,
                    ],
                    stops: [0.0, 0.3, 0.7, 1.0],
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topLeft,
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

          // Story Content
          SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(currentStory['storyImage']),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.5),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Story Header
          SafeArea(
            child: Column(
              children: [
                // Progress Bar
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: List.generate(stories.length, (index) {
                      return Expanded(
                        child: Container(
                          height: 3,
                          margin: EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: index == _currentStoryIndex
                              ? FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: _progress,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    color: index < _currentStoryIndex ? Colors.white : Colors.white.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                        ),
                      );
                    }),
                  ),
                ),

                // User Info
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage(currentStory['userImage']),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentStory['username'],
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              currentStory['time'],
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.more_vert, color: Colors.white),
                        onPressed: () {
                          _showStoryOptions();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Story Actions
          Positioned(
            bottom: 100,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.reply,
                  label: 'Reply',
                  onTap: () {
                    _showReplyDialog();
                  },
                ),
                _buildActionButton(
                  icon: Icons.favorite_border,
                  label: 'Like',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Liked story!'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
                _buildActionButton(
                  icon: Icons.send,
                  label: 'Share',
                  onTap: () {
                    _showShareDialog();
                  },
                ),
              ],
            ),
          ),

          // Navigation Buttons
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            right: 0,
            child: Row(
              children: [
                // Previous Story
                Expanded(
                  child: GestureDetector(
                    onTap: _previousStory,
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                ),
                // Next Story
                Expanded(
                  child: GestureDetector(
                    onTap: _nextStory,
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Pause/Resume Button
          Positioned(
            top: 100,
            right: 16,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isPaused = !_isPaused;
                });
                if (!_isPaused) {
                  _startStoryProgress();
                }
              },
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isPaused ? Icons.play_arrow : Icons.pause,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStoryOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(Icons.report),
              title: Text('Report'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Story reported')),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.block),
              title: Text('Block User'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('User blocked')),
                );
              },
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showReplyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reply to Story'),
        content: TextField(
          decoration: InputDecoration(
            hintText: 'Type your reply...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Reply sent!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showShareDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Share Story'),
        content: Text('Share this story to other platforms?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Story shared!'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: Text('Share'),
          ),
        ],
      ),
    );
  }
} 