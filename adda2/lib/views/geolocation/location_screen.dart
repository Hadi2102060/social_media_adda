import 'package:flutter/material.dart';

class LocationScreen extends StatefulWidget {
  final Function(String)? onLocationSelected;
  
  const LocationScreen({super.key, this.onLocationSelected});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _backgroundController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _backgroundAnimation;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedLocation;
  bool _isLoading = false;

  // Sample popular locations
  final List<Map<String, dynamic>> popularLocations = [
    {
      'name': 'Eiffel Tower',
      'address': 'Champ de Mars, 5 Avenue Anatole France, 75007 Paris, France',
      'category': 'Landmark',
      'rating': 4.7,
      'distance': '2.3 km',
      'image': 'https://picsum.photos/80/80?random=1',
      'coordinates': {'lat': 48.8584, 'lng': 2.2945},
    },
    {
      'name': 'Central Park',
      'address': 'New York, NY 10024, United States',
      'category': 'Park',
      'rating': 4.8,
      'distance': '1.1 km',
      'image': 'https://picsum.photos/80/80?random=2',
      'coordinates': {'lat': 40.7829, 'lng': -73.9654},
    },
    {
      'name': 'Times Square',
      'address': 'Manhattan, NY 10036, United States',
      'category': 'Tourist Attraction',
      'rating': 4.5,
      'distance': '0.8 km',
      'image': 'https://picsum.photos/80/80?random=3',
      'coordinates': {'lat': 40.7580, 'lng': -73.9855},
    },
    {
      'name': 'Golden Gate Bridge',
      'address': 'San Francisco, CA 94129, United States',
      'category': 'Landmark',
      'rating': 4.9,
      'distance': '5.2 km',
      'image': 'https://picsum.photos/80/80?random=4',
      'coordinates': {'lat': 37.8199, 'lng': -122.4783},
    },
    {
      'name': 'Shibuya Crossing',
      'address': 'Shibuya City, Tokyo 150-0002, Japan',
      'category': 'Tourist Attraction',
      'rating': 4.6,
      'distance': '3.7 km',
      'image': 'https://picsum.photos/80/80?random=5',
      'coordinates': {'lat': 35.6595, 'lng': 139.7004},
    },
  ];

  // Sample nearby locations
  final List<Map<String, dynamic>> nearbyLocations = [
    {
      'name': 'Coffee Shop',
      'address': '123 Main St, Downtown',
      'category': 'Cafe',
      'rating': 4.3,
      'distance': '0.2 km',
      'image': 'https://picsum.photos/80/80?random=6',
      'coordinates': {'lat': 40.7128, 'lng': -74.0060},
    },
    {
      'name': 'City Library',
      'address': '456 Oak Ave, Downtown',
      'category': 'Library',
      'rating': 4.1,
      'distance': '0.5 km',
      'image': 'https://picsum.photos/80/80?random=7',
      'coordinates': {'lat': 40.7129, 'lng': -74.0061},
    },
    {
      'name': 'Shopping Mall',
      'address': '789 Pine St, Downtown',
      'category': 'Shopping',
      'rating': 4.4,
      'distance': '0.8 km',
      'image': 'https://picsum.photos/80/80?random=8',
      'coordinates': {'lat': 40.7130, 'lng': -74.0062},
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
      duration: Duration(seconds: 7),
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
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get filteredLocations {
    if (_searchQuery.isEmpty) {
      return [...popularLocations, ...nearbyLocations];
    }
    return [...popularLocations, ...nearbyLocations].where((location) =>
      location['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
      location['address'].toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  void _selectLocation(Map<String, dynamic> location) {
    setState(() {
      _selectedLocation = location['name'];
    });
    
    widget.onLocationSelected?.call(location['name']);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Location "${location['name']}" selected!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 1),
      ),
    );
    
    Navigator.pop(context);
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
                      Color.lerp(Colors.brown.shade400, Colors.brown.shade500, _backgroundAnimation.value)!,
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
                          'Add Location',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Spacer(),
                        IconButton(
                          icon: Icon(Icons.my_location, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                            });
                            
                            Future.delayed(Duration(seconds: 1), () {
                              setState(() {
                                _isLoading = false;
                              });
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Current location detected!'),
                                  backgroundColor: Colors.blue,
                                ),
                              );
                            });
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
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search for a location...',
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          border: InputBorder.none,
                          icon: Icon(Icons.search, color: Colors.grey[600]),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear, color: Colors.grey[600]),
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

                // Location Categories
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: ['All', 'Nearby', 'Popular', 'Landmarks', 'Food', 'Shopping'].length,
                        itemBuilder: (context, index) {
                          final categories = ['All', 'Nearby', 'Popular', 'Landmarks', 'Food', 'Shopping'];
                          final isSelected = index == 0; // Default to 'All'
                          
                          return Container(
                            margin: EdgeInsets.only(right: 12),
                            child: GestureDetector(
                              onTap: () {
                                // Handle category selection
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
                                    color: isSelected ? Colors.brown : Colors.white,
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

                // Locations List
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
                            // Section Headers
                            if (_searchQuery.isEmpty) ...[
                              _buildSectionHeader('Popular Locations'),
                              Expanded(
                                child: ListView.builder(
                                  padding: EdgeInsets.all(16),
                                  itemCount: popularLocations.length,
                                  itemBuilder: (context, index) {
                                    return _buildLocationItem(popularLocations[index]);
                                  },
                                ),
                              ),
                              _buildSectionHeader('Nearby'),
                              Expanded(
                                child: ListView.builder(
                                  padding: EdgeInsets.all(16),
                                  itemCount: nearbyLocations.length,
                                  itemBuilder: (context, index) {
                                    return _buildLocationItem(nearbyLocations[index]);
                                  },
                                ),
                              ),
                            ] else ...[
                              Expanded(
                                child: ListView.builder(
                                  padding: EdgeInsets.all(16),
                                  itemCount: filteredLocations.length,
                                  itemBuilder: (context, index) {
                                    return _buildLocationItem(filteredLocations[index]);
                                  },
                                ),
                              ),
                            ],
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

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.brown[700],
            ),
          ),
          Spacer(),
          Icon(Icons.location_on, color: Colors.brown[400], size: 20),
        ],
      ),
    );
  }

  Widget _buildLocationItem(Map<String, dynamic> location) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(12),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: NetworkImage(location['image']),
              fit: BoxFit.cover,
            ),
          ),
        ),
        title: Text(
          location['name'],
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              location['address'],
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 14),
                SizedBox(width: 4),
                Text(
                  '${location['rating']}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  location['distance'],
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.brown[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    location['category'],
                    style: TextStyle(
                      color: Colors.brown[700],
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.add_location, color: Colors.brown),
          onPressed: () => _selectLocation(location),
        ),
        onTap: () => _selectLocation(location),
      ),
    );
  }
} 