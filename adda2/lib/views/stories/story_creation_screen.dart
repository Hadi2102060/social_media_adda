import 'package:flutter/material.dart';
import 'package:adda2/views/stories/story_viewer_screen.dart';

class StoryCreationScreen extends StatefulWidget {
  const StoryCreationScreen({super.key});

  @override
  State<StoryCreationScreen> createState() => _StoryCreationScreenState();
}

class _StoryCreationScreenState extends State<StoryCreationScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _backgroundController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _backgroundAnimation;

  final TextEditingController _textController = TextEditingController();
  String _selectedFilter = 'Normal';
  double _brightness = 0.0;
  double _saturation = 0.0;
  double _contrast = 0.0;
  bool _isRecording = false;
  bool _isLoading = false;

  final List<Map<String, dynamic>> filters = [
    {'name': 'Normal', 'icon': Icons.filter_none, 'color': Colors.transparent},
    {'name': 'Vintage', 'icon': Icons.filter_1, 'color': Colors.orange},
    {'name': 'Black & White', 'icon': Icons.filter_2, 'color': Colors.grey},
    {'name': 'Warm', 'icon': Icons.filter_3, 'color': Colors.amber},
    {'name': 'Cool', 'icon': Icons.filter_4, 'color': Colors.blue},
    {'name': 'Dramatic', 'icon': Icons.filter_5, 'color': Colors.purple},
    {'name': 'Bright', 'icon': Icons.filter_6, 'color': Colors.yellow},
    {'name': 'Moody', 'icon': Icons.filter_7, 'color': Colors.indigo},
  ];

  final List<Map<String, dynamic>> stickers = [
    {'emoji': '😍', 'name': 'Love'},
    {'emoji': '🎉', 'name': 'Party'},
    {'emoji': '🔥', 'name': 'Fire'},
    {'emoji': '💯', 'name': 'Perfect'},
    {'emoji': '✨', 'name': 'Sparkle'},
    {'emoji': '🌟', 'name': 'Star'},
    {'emoji': '💖', 'name': 'Heart'},
    {'emoji': '🎵', 'name': 'Music'},
  ];

  final List<Map<String, dynamic>> backgrounds = [
    {'color': Colors.red, 'name': 'Red'},
    {'color': Colors.blue, 'name': 'Blue'},
    {'color': Colors.green, 'name': 'Green'},
    {'color': Colors.purple, 'name': 'Purple'},
    {'color': Colors.orange, 'name': 'Orange'},
    {'color': Colors.pink, 'name': 'Pink'},
    {'color': Colors.teal, 'name': 'Teal'},
    {'color': Colors.indigo, 'name': 'Indigo'},
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
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _backgroundController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _showStickerPicker() {
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
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Add Stickers',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              height: 120,
              child: GridView.builder(
                padding: EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: stickers.length,
                itemBuilder: (context, index) {
                  final sticker = stickers[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Added ${sticker['emoji']} to story'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          sticker['emoji'],
                          style: TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
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
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.lerp(Colors.cyan.shade400, Colors.cyan.shade500, _backgroundAnimation.value)!,
                      Color.lerp(Colors.blue.shade400, Colors.blue.shade500, _backgroundAnimation.value)!,
                      Color.lerp(Colors.indigo.shade400, Colors.indigo.shade500, _backgroundAnimation.value)!,
                      Color.lerp(Colors.purple.shade400, Colors.purple.shade500, _backgroundAnimation.value)!,
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
                          icon: Icon(Icons.close, color: Colors.white, size: 30),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Spacer(),
                        Text(
                          'Create Story',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Spacer(),
                        IconButton(
                          icon: Icon(Icons.check, color: Colors.white, size: 30),
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                            });
                            
                            Future.delayed(Duration(seconds: 1), () {
                              setState(() {
                                _isLoading = false;
                              });
                              
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StoryViewerScreen(),
                                ),
                              );
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Story Preview
                Expanded(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        margin: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.grey.shade300,
                                  Colors.grey.shade400,
                                ],
                              ),
                            ),
                            child: Stack(
                              children: [
                                // Camera Preview (simulated)
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.camera_alt,
                                        size: 80,
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'Story Preview',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Tap to capture',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Text Overlay
                                if (_textController.text.isNotEmpty)
                                  Positioned(
                                    top: 50,
                                    left: 20,
                                    right: 20,
                                    child: Container(
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _textController.text,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Editing Controls
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Text Input
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: _textController,
                              style: TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Add text to your story...',
                                hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                                border: InputBorder.none,
                                suffixIcon: IconButton(
                                  icon: Icon(Icons.text_fields, color: Colors.white),
                                  onPressed: () {
                                    // Text formatting options
                                  },
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: 16),

                          // Filters
                          Container(
                            height: 80,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: filters.length,
                              itemBuilder: (context, index) {
                                final filter = filters[index];
                                final isSelected = filter['name'] == _selectedFilter;
                                
                                return Container(
                                  margin: EdgeInsets.only(right: 12),
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
                                          border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
                                        ),
                                        child: Icon(
                                          filter['icon'],
                                          color: isSelected ? Colors.cyan : Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        filter['name'],
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                                          fontSize: 12,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),

                          SizedBox(height: 16),

                          // Adjustments
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                _buildSlider('Brightness', _brightness, (value) {
                                  setState(() => _brightness = value);
                                }, Icons.wb_sunny),
                                SizedBox(height: 12),
                                _buildSlider('Saturation', _saturation, (value) {
                                  setState(() => _saturation = value);
                                }, Icons.color_lens),
                                SizedBox(height: 12),
                                _buildSlider('Contrast', _contrast, (value) {
                                  setState(() => _contrast = value);
                                }, Icons.contrast),
                              ],
                            ),
                          ),

                          SizedBox(height: 16),

                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _showStickerPicker,
                                  icon: Icon(Icons.emoji_emotions),
                                  label: Text('Stickers'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white.withOpacity(0.2),
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _isRecording = !_isRecording;
                                    });
                                  },
                                  icon: Icon(_isRecording ? Icons.stop : Icons.fiber_manual_record),
                                  label: Text(_isRecording ? 'Stop' : 'Record'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isRecording ? Colors.red : Colors.white.withOpacity(0.2),
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 16),

                          // Share Button
                          Container(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : () {
                                setState(() {
                                  _isLoading = true;
                                });
                                
                                Future.delayed(Duration(seconds: 1), () {
                                  setState(() {
                                    _isLoading = false;
                                  });
                                  
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => StoryViewerScreen(),
                                    ),
                                  );
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.cyan,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.cyan,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'Share Story',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
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

  Widget _buildSlider(String label, double value, ValueChanged<double> onChanged, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Slider(
                value: value,
                onChanged: onChanged,
                activeColor: Colors.white,
                inactiveColor: Colors.white.withOpacity(0.3),
                min: -1.0,
                max: 1.0,
              ),
            ],
          ),
        ),
      ],
    );
  }
} 