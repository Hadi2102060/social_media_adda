import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'post_action_bar.dart';
import '../../providers/feed_provider.dart';

class NewsFeedScreen extends StatefulWidget {
  const NewsFeedScreen({super.key});

  @override
  State<NewsFeedScreen> createState() => _NewsFeedScreenState();
}

class _NewsFeedScreenState extends State<NewsFeedScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _backgroundController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _backgroundAnimation;

  final ScrollController _scrollController = ScrollController();
  bool _isRefreshing = false;
  int _selectedCategory = 0;

  final List<String> categories = [
    'All',
    'Technology',
    'Sports',
    'Entertainment',
    'Business',
    'Health',
  ];

  final List<Map<String, dynamic>> newsPosts = [
    {
      'title': 'Flutter 3.0 Released with Major Performance Improvements',
      'summary': 'Google has announced the release of Flutter 3.0, bringing significant performance enhancements and new features for cross-platform development.',
      'author': 'Tech News',
      'time': '2 hours ago',
      'image': 'https://picsum.photos/400/250?random=1',
      'category': 'Technology',
      'likes': 1247,
      'comments': 89,
      'shares': 156,
      'isBookmarked': false,
      'isLiked': false,
      'selectedReaction': 'Like',
    },
    {
      'title': 'World Cup 2024: Exciting Matches Ahead',
      'summary': 'The upcoming World Cup tournament promises to be the most exciting yet, with top teams competing for the ultimate prize.',
      'author': 'Sports Daily',
      'time': '4 hours ago',
      'image': 'https://picsum.photos/400/250?random=2',
      'category': 'Sports',
      'likes': 2156,
      'comments': 234,
      'shares': 445,
      'isBookmarked': false,
      'isLiked': false,
      'selectedReaction': 'Like',
    },
    {
      'title': 'New AI Breakthrough in Medical Diagnosis',
      'summary': 'Researchers have developed an AI system that can diagnose diseases with 95% accuracy, revolutionizing healthcare.',
      'author': 'Health Tech',
      'time': '6 hours ago',
      'image': 'https://picsum.photos/400/250?random=3',
      'category': 'Health',
      'likes': 1892,
      'comments': 167,
      'shares': 298,
      'isBookmarked': false,
      'isLiked': false,
      'selectedReaction': 'Like',
    },
    {
      'title': 'Stock Market Reaches New Heights',
      'summary': 'Global markets have reached unprecedented levels, driven by strong economic indicators and investor confidence.',
      'author': 'Business Insider',
      'time': '8 hours ago',
      'image': 'https://picsum.photos/400/250?random=4',
      'category': 'Business',
      'likes': 987,
      'comments': 76,
      'shares': 134,
      'isBookmarked': false,
      'isLiked': false,
      'selectedReaction': 'Like',
    },
    {
      'title': 'New Movie Breaks Box Office Records',
      'summary': 'The latest blockbuster has shattered previous records, becoming the highest-grossing film of the year.',
      'author': 'Entertainment Weekly',
      'time': '10 hours ago',
      'image': 'https://picsum.photos/400/250?random=5',
      'category': 'Entertainment',
      'likes': 3456,
      'comments': 456,
      'shares': 789,
      'isBookmarked': false,
      'isLiked': false,
      'selectedReaction': 'Like',
    },
    {
      'title': 'SpaceX Launches New Satellite Constellation',
      'summary': 'SpaceX successfully launched another batch of satellites, expanding their global internet coverage.',
      'author': 'Space News',
      'time': '12 hours ago',
      'image': 'https://picsum.photos/400/250?random=6',
      'category': 'Technology',
      'likes': 2765,
      'comments': 198,
      'shares': 345,
      'isBookmarked': false,
      'isLiked': false,
      'selectedReaction': 'Like',
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
      duration: Duration(seconds: 8),
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

    // Example: Fetch feed in initState or on button press
    // Provider.of<FeedProvider>(context, listen: false).fetchFeed(token);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _backgroundController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshFeed() async {
    setState(() {
      _isRefreshing = true;
    });
    
    // Simulate refresh
    await Future.delayed(Duration(seconds: 2));
    
    setState(() {
      _isRefreshing = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Feed refreshed!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 1),
      ),
    );
  }

  List<Map<String, dynamic>> get filteredPosts {
    if (_selectedCategory == 0) {
      return newsPosts;
    }
    return newsPosts.where((post) => 
      post['category'] == categories[_selectedCategory]
    ).toList();
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
                      Color.lerp(Colors.orange.shade400, Colors.orange.shade500, _backgroundAnimation.value)!,
                      Color.lerp(Colors.red.shade400, Colors.red.shade500, _backgroundAnimation.value)!,
                      Color.lerp(Colors.pink.shade400, Colors.pink.shade500, _backgroundAnimation.value)!,
                      Color.lerp(Colors.purple.shade400, Colors.purple.shade500, _backgroundAnimation.value)!,
                    ],
                    stops: [0.0, 0.3, 0.7, 1.0],
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.5,
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
                        Spacer(),
                        Text(
                          'News Feed',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Spacer(),
                        IconButton(
                          icon: Icon(Icons.search, color: Colors.white),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Search feature coming soon!'),
                                backgroundColor: Colors.blue,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Category Filter
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final isSelected = index == _selectedCategory;
                          return Container(
                            margin: EdgeInsets.only(right: 12),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedCategory = index;
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
                                  categories[index],
                                  style: TextStyle(
                                    color: isSelected ? Colors.orange : Colors.white,
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

                // News Feed
                Expanded(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: RefreshIndicator(
                        onRefresh: _refreshFeed,
                        color: Colors.white,
                        backgroundColor: Colors.orange,
                        child: Consumer<FeedProvider>(
                          builder: (context, feedProvider, child) {
                            if (feedProvider.loading) return Center(child: CircularProgressIndicator());
                            if (feedProvider.error != null) return Center(child: Text(feedProvider.error!));
                            return ListView.builder(
                              controller: _scrollController,
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              itemCount: feedProvider.feed.length,
                              itemBuilder: (context, index) {
                                final post = feedProvider.feed[index];
                                return NewsPostCard(
                                  post: post,
                                  onReact: (reaction) {
                                    setState(() {
                                      post['selectedReaction'] = reaction;
                                    });
                                  },
                                  onBookmark: () {
                                    setState(() {
                                      post['isBookmarked'] = !post['isBookmarked'];
                                    });
                                  },
                                  onShare: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Sharing ${post['title']}'),
                                        backgroundColor: Colors.blue,
                                      ),
                                    );
                                  },
                                  onComment: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Comments feature coming soon!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          },
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

class NewsPostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final Function(String) onReact;
  final VoidCallback onBookmark;
  final VoidCallback onShare;
  final VoidCallback onComment;

  const NewsPostCard({
    super.key,
    required this.post,
    required this.onReact,
    required this.onBookmark,
    required this.onShare,
    required this.onComment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Header
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.article,
                    color: Colors.orange.shade600,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post['author'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        post['time'],
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    post['category'],
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Post Image
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              image: DecorationImage(
                image: NetworkImage(post['image']),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Post Content
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post['title'],
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  post['summary'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 16),

                // New Custom Action Bar
                PostActionBar(
                  selectedReaction: post['selectedReaction'] ?? 'Like',
                  isSaved: post['isBookmarked'] ?? false,
                  onReact: onReact,
                  onComment: onComment,
                  onShare: onShare,
                  onSave: onBookmark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 