import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _backgroundController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _backgroundAnimation;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  bool _isSearching = false;
  int _selectedTab = 0;

  final List<String> searchTabs = ['Top', 'Accounts', 'Tags', 'Places'];

  // Sample search results
  final List<Map<String, dynamic>> topResults = [
    {
      'type': 'account',
      'username': 'john_doe',
      'fullName': 'John Doe',
      'image': 'https://picsum.photos/60/60?random=1',
      'isVerified': true,
      'followers': '1.2M',
      'isFollowing': false,
    },
    {
      'type': 'account',
      'username': 'jane_smith',
      'fullName': 'Jane Smith',
      'image': 'https://picsum.photos/60/60?random=2',
      'isVerified': false,
      'followers': '856K',
      'isFollowing': true,
    },
    {
      'type': 'tag',
      'name': '#photography',
      'posts': '2.1M',
      'image': 'https://picsum.photos/60/60?random=3',
    },
    {
      'type': 'place',
      'name': 'Paris, France',
      'category': 'City',
      'image': 'https://picsum.photos/60/60?random=4',
    },
  ];

  final List<Map<String, dynamic>> accountResults = [
    {
      'username': 'photographer_pro',
      'fullName': 'Professional Photographer',
      'image': 'https://picsum.photos/60/60?random=5',
      'isVerified': true,
      'followers': '500K',
      'isFollowing': false,
    },
    {
      'username': 'travel_lover',
      'fullName': 'Travel Enthusiast',
      'image': 'https://picsum.photos/60/60?random=6',
      'isVerified': false,
      'followers': '320K',
      'isFollowing': false,
    },
    {
      'username': 'food_blogger',
      'fullName': 'Food & Lifestyle',
      'image': 'https://picsum.photos/60/60?random=7',
      'isVerified': true,
      'followers': '890K',
      'isFollowing': true,
    },
  ];

  final List<Map<String, dynamic>> tagResults = [
    {
      'name': '#photography',
      'posts': '2.1M',
      'image': 'https://picsum.photos/60/60?random=8',
    },
    {
      'name': '#travel',
      'posts': '1.8M',
      'image': 'https://picsum.photos/60/60?random=9',
    },
    {
      'name': '#food',
      'posts': '3.2M',
      'image': 'https://picsum.photos/60/60?random=10',
    },
    {
      'name': '#fitness',
      'posts': '1.5M',
      'image': 'https://picsum.photos/60/60?random=11',
    },
  ];

  final List<Map<String, dynamic>> placeResults = [
    {
      'name': 'Paris, France',
      'category': 'City',
      'image': 'https://picsum.photos/60/60?random=12',
    },
    {
      'name': 'Tokyo, Japan',
      'category': 'City',
      'image': 'https://picsum.photos/60/60?random=13',
    },
    {
      'name': 'New York, USA',
      'category': 'City',
      'image': 'https://picsum.photos/60/60?random=14',
    },
    {
      'name': 'London, UK',
      'category': 'City',
      'image': 'https://picsum.photos/60/60?random=15',
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

    // Auto-focus search field
    Future.delayed(Duration(milliseconds: 500), () {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _backgroundController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query;
      _isSearching = query.isNotEmpty;
    });
  }

  List<Map<String, dynamic>> get currentResults {
    switch (_selectedTab) {
      case 0:
        return topResults;
      case 1:
        return accountResults;
      case 2:
        return tagResults;
      case 3:
        return placeResults;
      default:
        return topResults;
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
                      Color.lerp(Colors.amber.shade400, Colors.amber.shade500, _backgroundAnimation.value)!,
                      Color.lerp(Colors.orange.shade400, Colors.orange.shade500, _backgroundAnimation.value)!,
                      Color.lerp(Colors.red.shade400, Colors.red.shade500, _backgroundAnimation.value)!,
                      Color.lerp(Colors.pink.shade400, Colors.pink.shade500, _backgroundAnimation.value)!,
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
                          'Search',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Spacer(),
                        IconButton(
                          icon: Icon(Icons.qr_code_scanner, color: Colors.white),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('QR Scanner coming soon!'),
                                backgroundColor: Colors.blue,
                              ),
                            );
                          },
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
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        onChanged: _performSearch,
                        decoration: InputDecoration(
                          hintText: 'Search',
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          border: InputBorder.none,
                          icon: Icon(Icons.search, color: Colors.grey[600]),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear, color: Colors.grey[600]),
                                  onPressed: () {
                                    _searchController.clear();
                                    _performSearch('');
                                  },
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),

                // Search Tabs
                if (_isSearching)
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        height: 50,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          itemCount: searchTabs.length,
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
                                    searchTabs[index],
                                    style: TextStyle(
                                      color: isSelected ? Colors.amber : Colors.white,
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

                // Search Results
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
                        child: _isSearching
                            ? _buildSearchResults()
                            : _buildRecentSearches(),
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

  Widget _buildSearchResults() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: currentResults.length,
      itemBuilder: (context, index) {
        final result = currentResults[index];
        
        switch (_selectedTab) {
          case 0: // Top
            return _buildTopResult(result);
          case 1: // Accounts
            return _buildAccountResult(result);
          case 2: // Tags
            return _buildTagResult(result);
          case 3: // Places
            return _buildPlaceResult(result);
          default:
            return _buildTopResult(result);
        }
      },
    );
  }

  Widget _buildTopResult(Map<String, dynamic> result) {
    if (result['type'] == 'account') {
      return _buildAccountResult(result);
    } else if (result['type'] == 'tag') {
      return _buildTagResult(result);
    } else {
      return _buildPlaceResult(result);
    }
  }

  Widget _buildAccountResult(Map<String, dynamic> result) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundImage: NetworkImage(result['image']),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      result['username'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (result['isVerified'] == true) ...[
                      SizedBox(width: 4),
                      Icon(Icons.verified, color: Colors.blue, size: 16),
                    ],
                  ],
                ),
                Text(
                  result['fullName'],
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                Text(
                  '${result['followers']} followers',
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
                result['isFollowing'] = !result['isFollowing'];
              });
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: result['isFollowing'] ? Colors.grey[300] : Colors.blue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                result['isFollowing'] ? 'Following' : 'Follow',
                style: TextStyle(
                  color: result['isFollowing'] ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagResult(Map<String, dynamic> result) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(result['image']),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result['name'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${result['posts']} posts',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceResult(Map<String, dynamic> result) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(result['image']),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result['name'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  result['category'],
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSearches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Recent Searches',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: ListView(
            children: [
              _buildRecentSearchItem('photography', 'https://picsum.photos/40/40?random=20'),
              _buildRecentSearchItem('travel', 'https://picsum.photos/40/40?random=21'),
              _buildRecentSearchItem('food', 'https://picsum.photos/40/40?random=22'),
              _buildRecentSearchItem('fitness', 'https://picsum.photos/40/40?random=23'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentSearchItem(String query, String image) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(image),
        ),
        title: Text(query),
        trailing: Icon(Icons.search, color: Colors.grey[600]),
        onTap: () {
          _searchController.text = query;
          _performSearch(query);
        },
      ),
    );
  }
} 