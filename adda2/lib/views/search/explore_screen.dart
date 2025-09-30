import 'package:flutter/material.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _backgroundController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _backgroundAnimation;

  int _selectedCategory = 0;
  bool _isLoading = false;

  final List<String> categories = [
    'Trending',
    'Travel',
    'Food',
    'Fashion',
    'Sports',
    'Art',
    'Technology',
    'Nature',
  ];

  // Sample trending content
  final List<Map<String, dynamic>> trendingContent = [
    {
      'title': 'Amazing Sunset in Bali',
      'author': 'travel_lover',
      'image': 'https://picsum.photos/300/300?random=1',
      'likes': '2.5K',
      'category': 'Travel',
      'isLiked': false,
    },
    {
      'title': 'Delicious Homemade Pizza',
      'author': 'food_blogger',
      'image': 'https://picsum.photos/300/300?random=2',
      'likes': '1.8K',
      'category': 'Food',
      'isLiked': false,
    },
    {
      'title': 'Street Fashion in Paris',
      'author': 'fashion_ista',
      'image': 'https://picsum.photos/300/300?random=3',
      'likes': '3.2K',
      'category': 'Fashion',
      'isLiked': false,
    },
    {
      'title': 'Mountain Adventure',
      'author': 'adventure_seeker',
      'image': 'https://picsum.photos/300/300?random=4',
      'likes': '4.1K',
      'category': 'Travel',
      'isLiked': false,
    },
    {
      'title': 'Abstract Art Collection',
      'author': 'art_gallery',
      'image': 'https://picsum.photos/300/300?random=5',
      'likes': '1.5K',
      'category': 'Art',
      'isLiked': false,
    },
    {
      'title': 'Tech Gadgets Review',
      'author': 'tech_reviewer',
      'image': 'https://picsum.photos/300/300?random=6',
      'likes': '2.8K',
      'category': 'Technology',
      'isLiked': false,
    },
    {
      'title': 'Wildlife Photography',
      'author': 'nature_photographer',
      'image': 'https://picsum.photos/300/300?random=7',
      'likes': '5.2K',
      'category': 'Nature',
      'isLiked': false,
    },
    {
      'title': 'Fitness Motivation',
      'author': 'fitness_coach',
      'image': 'https://picsum.photos/300/300?random=8',
      'likes': '3.7K',
      'category': 'Sports',
      'isLiked': false,
    },
  ];

  // Featured stories
  final List<Map<String, dynamic>> featuredStories = [
    {
      'title': 'Weekend Getaway',
      'image': 'https://picsum.photos/200/300?random=10',
      'author': 'travel_lover',
    },
    {
      'title': 'Cooking Masterclass',
      'image': 'https://picsum.photos/200/300?random=11',
      'author': 'food_blogger',
    },
    {
      'title': 'Fashion Week',
      'image': 'https://picsum.photos/200/300?random=12',
      'author': 'fashion_ista',
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
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get filteredContent {
    if (_selectedCategory == 0) {
      return trendingContent;
    }
    return trendingContent.where((content) => 
      content['category'] == categories[_selectedCategory]
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
                      Color.lerp(Colors.deepPurple.shade400, Colors.deepPurple.shade500, _backgroundAnimation.value)!,
                      Color.lerp(Colors.purple.shade400, Colors.purple.shade500, _backgroundAnimation.value)!,
                      Color.lerp(Colors.pink.shade400, Colors.pink.shade500, _backgroundAnimation.value)!,
                      Color.lerp(Colors.red.shade400, Colors.red.shade500, _backgroundAnimation.value)!,
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
                          'Explore',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Spacer(),
                        IconButton(
                          icon: Icon(Icons.tune, color: Colors.white),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Filter options coming soon!'),
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
                                    color: isSelected ? Colors.deepPurple : Colors.white,
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

                // Featured Stories
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: featuredStories.length,
                        itemBuilder: (context, index) {
                          final story = featuredStories[index];
                          return Container(
                            width: 120,
                            margin: EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                image: NetworkImage(story['image']),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.7),
                                  ],
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(8),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      story['title'],
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      story['author'],
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
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

                // Trending Content
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
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Text(
                                    'Trending Now',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Spacer(),
                                  Icon(Icons.trending_up, color: Colors.orange),
                                ],
                              ),
                            ),
                            Expanded(
                              child: GridView.builder(
                                padding: EdgeInsets.all(16),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 0.8,
                                ),
                                itemCount: filteredContent.length,
                                itemBuilder: (context, index) {
                                  final content = filteredContent[index];
                                  return _buildContentCard(content);
                                },
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

  Widget _buildContentCard(Map<String, dynamic> content) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Image
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(content['image']),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            
            // Content Info
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      content['title'],
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          content['author'],
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 10,
                          ),
                        ),
                        Spacer(),
                        Row(
                          children: [
                            Icon(
                              content['isLiked'] ? Icons.favorite : Icons.favorite_border,
                              color: content['isLiked'] ? Colors.red : Colors.white,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              content['likes'],
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Like Button
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    content['isLiked'] = !content['isLiked'];
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    content['isLiked'] ? Icons.favorite : Icons.favorite_border,
                    color: content['isLiked'] ? Colors.red : Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 