import 'package:flutter/material.dart';
import 'dart:math' as math;

class BlockReportScreen extends StatefulWidget {
  const BlockReportScreen({Key? key}) : super(key: key);

  @override
  State<BlockReportScreen> createState() => _BlockReportScreenState();
}

class _BlockReportScreenState extends State<BlockReportScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _pulseController;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _pulseAnimation;

  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _blockedUsers = [];
  List<Map<String, dynamic>> _reportedUsers = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _backgroundAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_backgroundController);

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Sample data
    _blockedUsers = [
      {
        'username': 'john_doe',
        'fullName': 'John Doe',
        'avatar': 'https://via.placeholder.com/50',
        'blockedDate': '2024-01-15',
        'reason': 'Harassment',
      },
      {
        'username': 'spam_user',
        'fullName': 'Spam User',
        'avatar': 'https://via.placeholder.com/50',
        'blockedDate': '2024-01-10',
        'reason': 'Spam',
      },
    ];

    _reportedUsers = [
      {
        'username': 'inappropriate_user',
        'fullName': 'Inappropriate User',
        'avatar': 'https://via.placeholder.com/50',
        'reportedDate': '2024-01-20',
        'reason': 'Inappropriate content',
        'status': 'Under review',
      },
    ];
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _pulseController.dispose();
    _searchController.dispose();
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
              return CustomPaint(
                painter: AnimatedBackgroundPainter(
                  animation: _backgroundAnimation.value,
                  pulse: _pulseAnimation.value,
                ),
                size: Size.infinite,
              );
            },
          ),
          
          // Content
          SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Privacy & Safety',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Search Bar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _isSearching = value.isNotEmpty;
                      });
                    },
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search users to block or report...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                      prefixIcon: const Icon(Icons.search, color: Colors.white70),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Tabs
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildTabButton('Blocked Users', true),
                      ),
                      Expanded(
                        child: _buildTabButton('Reported Users', false),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Content
                Expanded(
                  child: _isSearching ? _buildSearchResults() : _buildUserLists(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          // Toggle between tabs
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search Results',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: 3,
              itemBuilder: (context, index) {
                return _buildSearchResultItem(
                  'user_${index + 1}',
                  'User ${index + 1}',
                  'https://via.placeholder.com/50',
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserLists() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Blocked Users (${_blockedUsers.length})',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _blockedUsers.length,
              itemBuilder: (context, index) {
                final user = _blockedUsers[index];
                return _buildBlockedUserItem(user);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultItem(String username, String fullName, String avatar) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundImage: NetworkImage(avatar),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '@$username',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _buildActionButton(
                'Block',
                Icons.block,
                Colors.red,
                () => _showBlockDialog(username, fullName),
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                'Report',
                Icons.report,
                Colors.orange,
                () => _showReportDialog(username, fullName),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedUserItem(Map<String, dynamic> user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundImage: NetworkImage(user['avatar']),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['fullName'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '@${user['username']}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                Text(
                  'Blocked: ${user['blockedDate']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          _buildActionButton(
            'Unblock',
            Icons.block,
            Colors.green,
            () => _showUnblockDialog(user['username']),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBlockDialog(String username, String fullName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('Block @$username?', style: const TextStyle(color: Colors.white)),
        content: Text(
          '$fullName won\'t be able to see your posts, stories, or profile. They won\'t know you blocked them.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _blockUser(username, fullName);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(String username, String fullName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('Report @$username?', style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Why are you reporting this account?',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            _buildReportOption('Spam'),
            _buildReportOption('Harassment'),
            _buildReportOption('Inappropriate content'),
            _buildReportOption('Fake account'),
            _buildReportOption('Other'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _reportUser(username, fullName);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  Widget _buildReportOption(String option) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Radio<String>(
            value: option,
            groupValue: null,
            onChanged: (value) {},
            activeColor: Colors.orange,
          ),
          Text(
            option,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  void _showUnblockDialog(String username) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('Unblock @$username?', style: const TextStyle(color: Colors.white)),
        content: const Text(
          'They\'ll be able to see your posts and profile again.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _unblockUser(username);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Unblock'),
          ),
        ],
      ),
    );
  }

  void _blockUser(String username, String fullName) {
    setState(() {
      _blockedUsers.add({
        'username': username,
        'fullName': fullName,
        'avatar': 'https://via.placeholder.com/50',
        'blockedDate': DateTime.now().toString().split(' ')[0],
        'reason': 'User blocked',
      });
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('@$username has been blocked'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _reportUser(String username, String fullName) {
    setState(() {
      _reportedUsers.add({
        'username': username,
        'fullName': fullName,
        'avatar': 'https://via.placeholder.com/50',
        'reportedDate': DateTime.now().toString().split(' ')[0],
        'reason': 'User reported',
        'status': 'Under review',
      });
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('@$username has been reported'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _unblockUser(String username) {
    setState(() {
      _blockedUsers.removeWhere((user) => user['username'] == username);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('@$username has been unblocked'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class AnimatedBackgroundPainter extends CustomPainter {
  final double animation;
  final double pulse;

  AnimatedBackgroundPainter({required this.animation, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.red.withOpacity(0.2),
          Colors.orange.withOpacity(0.2),
          Colors.purple.withOpacity(0.2),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Animated circles
    for (int i = 0; i < 5; i++) {
      final x = size.width * 0.5 + math.cos(animation + i) * size.width * 0.3;
      final y = size.height * 0.5 + math.sin(animation + i) * size.height * 0.3;
      final radius = 50 * pulse;

      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()
          ..color = Colors.white.withOpacity(0.1)
          ..style = PaintingStyle.fill,
      );
    }

    // Background gradient
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 