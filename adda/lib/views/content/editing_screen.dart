import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:adda/views/content/post_preview_screen.dart';

class EditingScreen extends StatefulWidget {
  final String selectedImage; // http(s) URL or local file path
  final String? selectedLocation;

  const EditingScreen({
    super.key,
    required this.selectedImage,
    this.selectedLocation,
  });

  @override
  State<EditingScreen> createState() => _EditingScreenState();
}

class _EditingScreenState extends State<EditingScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _backgroundController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _backgroundAnimation;

  final _captionController = TextEditingController();
  final _tagsController = TextEditingController();

  String _selectedFilter = 'Normal';
  double _brightness = 0.0; // [-1..1]
  double _contrast = 0.0; // [-1..1]
  double _saturation = 0.0; // [-1..1]

  // প্রতিবার আপডেটে টোকেন বাড়াই → URL/key আলাদা হবে → cache বাইপাস
  int _reloadToken = DateTime.now().millisecondsSinceEpoch;

  // Local file হলে bytes কেশে ধরে রাখি
  Uint8List? _localBytesCache;

  final List<Map<String, dynamic>> filters = const [
    {'name': 'Normal', 'icon': Icons.filter_none},
    {'name': 'Vintage', 'icon': Icons.filter_1},
    {'name': 'Black & White', 'icon': Icons.filter_2},
    {'name': 'Warm', 'icon': Icons.filter_3},
    {'name': 'Cool', 'icon': Icons.filter_4},
    {'name': 'Dramatic', 'icon': Icons.filter_5},
    {'name': 'Bright', 'icon': Icons.filter_6},
    {'name': 'Moody', 'icon': Icons.filter_7},
  ];

  bool get _isNetwork =>
      widget.selectedImage.startsWith('http://') ||
      widget.selectedImage.startsWith('https://');

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _backgroundAnimation = CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    );

    _fadeController.forward();
    _slideController.forward();
    _backgroundController.repeat(reverse: true);

    _primeLocalBytesIfNeeded();
  }

  // parent থেকে আবার এলে/props বদলালে hard refresh + cache evict
  @override
  void didUpdateWidget(covariant EditingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // সবক্ষেত্রেই নতুন টোকেন
    _bumpReloadToken();

    // Network হলে: পুরোনো URL evict করে দেই
    if (_isNetwork) {
      _evictNetworkImage(oldWidget.selectedImage);
    }

    // Local path বদলালে bytes আবার পড়ি
    if (widget.selectedImage != oldWidget.selectedImage && !_isNetwork) {
      _localBytesCache = null;
      _primeLocalBytesIfNeeded();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _backgroundController.dispose();
    _captionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  // ---------------- Color Matrix Utilities ----------------
  List<double> _identity() => <double>[
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];

  List<double> _mul(List<double> a, List<double> b) {
    final out = List<double>.filled(20, 0.0);
    for (int row = 0; row < 4; row++) {
      for (int col = 0; col < 4; col++) {
        out[row * 5 + col] =
            b[row * 5 + 0] * a[0 * 5 + col] +
            b[row * 5 + 1] * a[1 * 5 + col] +
            b[row * 5 + 2] * a[2 * 5 + col] +
            b[row * 5 + 3] * a[3 * 5 + col];
      }
      out[row * 5 + 4] =
          b[row * 5 + 0] * a[4] +
          b[row * 5 + 1] * a[9] +
          b[row * 5 + 2] * a[14] +
          b[row * 5 + 3] * a[19] +
          b[row * 5 + 4];
    }
    return out;
  }

  List<double> _saturationMatrix(double factor) {
    const rL = 0.2126, gL = 0.7152, bL = 0.0722;
    final inv = 1 - factor;
    return <double>[
      rL * inv + factor,
      gL * inv,
      bL * inv,
      0,
      0,
      rL * inv,
      gL * inv + factor,
      bL * inv,
      0,
      0,
      rL * inv,
      gL * inv,
      bL * inv + factor,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ];
  }

  List<double> _contrastBrightnessMatrix(double c, double b) {
    final f = 1.0 + c;
    final t = 128.0 * (1.0 - f);
    final off = t + b * 255.0;
    return <double>[
      f,
      0,
      0,
      0,
      off,
      0,
      f,
      0,
      0,
      off,
      0,
      0,
      f,
      0,
      off,
      0,
      0,
      0,
      1,
      0,
    ];
  }

  List<double> _toneMatrix({double r = 1, double g = 1, double b = 1}) {
    return <double>[r, 0, 0, 0, 0, 0, g, 0, 0, 0, 0, 0, b, 0, 0, 0, 0, 0, 1, 0];
  }

  List<double> _sepiaMatrix([double strength = 1.0]) {
    final base = <double>[
      0.393,
      0.769,
      0.189,
      0,
      0,
      0.349,
      0.686,
      0.168,
      0,
      0,
      0.272,
      0.534,
      0.131,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ];
    final id = _identity();
    final out = List<double>.filled(20, 0);
    for (int i = 0; i < 20; i++) {
      out[i] = id[i] * (1 - strength) + base[i] * strength;
    }
    return out;
  }

  List<double> _presetMatrix(String name) {
    switch (name) {
      case 'Vintage':
        return _sepiaMatrix(0.85);
      case 'Black & White':
        return _saturationMatrix(0.0);
      case 'Warm':
        return _toneMatrix(r: 1.10, g: 1.0, b: 0.92);
      case 'Cool':
        return _toneMatrix(r: 0.92, g: 1.0, b: 1.10);
      case 'Dramatic':
        final s = _saturationMatrix(0.85);
        final c = _contrastBrightnessMatrix(0.28, 0.0);
        return _mul(s, c);
      case 'Bright':
        final c = _contrastBrightnessMatrix(0.0, 0.20);
        final s = _saturationMatrix(1.08);
        return _mul(c, s);
      case 'Moody':
        final c = _contrastBrightnessMatrix(0.22, -0.12);
        final s = _saturationMatrix(0.90);
        return _mul(s, c);
      case 'Normal':
      default:
        return _identity();
    }
  }

  List<double> _finalMatrix() {
    final preset = _presetMatrix(_selectedFilter);
    final satFactor = math.max(0.0, 1.0 + _saturation);
    final mSat = _saturationMatrix(satFactor);
    final mCB = _contrastBrightnessMatrix(_contrast, _brightness);
    var m = _mul(preset, mSat);
    m = _mul(m, mCB);
    return m;
  }

  void _selectFilter(String name) {
    setState(() => _selectedFilter = name);
    _bumpReloadToken();
  }

  // --------- refresh / cache helpers ----------
  void _bumpReloadToken() {
    setState(() => _reloadToken = DateTime.now().millisecondsSinceEpoch);
  }

  // পুরোনো নেটওয়ার্ক ইমেজকে cache থেকে সরিয়ে দেই
  void _evictNetworkImage(String url) {
    try {
      final provider = NetworkImage(url);
      provider.evict().then((_) {
        // নিরাপদে global cache-ও একটু ক্লিন করি (optional)
        SchedulerBinding.instance.addPostFrameCallback((_) {
          PaintingBinding.instance.imageCache.clearLiveImages();
          PaintingBinding.instance.imageCache.clear();
        });
      });
    } catch (_) {
      /* ignore */
    }
  }

  String _withCacheBust(String url) {
    final u = Uri.parse(url);
    final qp = Map<String, String>.from(u.queryParameters);
    qp['v'] = _reloadToken.toString();
    return u.replace(queryParameters: qp).toString();
  }

  Future<void> _primeLocalBytesIfNeeded() async {
    if (!_isNetwork) {
      final f = File(widget.selectedImage);
      if (await f.exists()) {
        try {
          final bytes = await f.readAsBytes();
          if (mounted) {
            setState(() => _localBytesCache = bytes);
          }
        } catch (_) {
          // ignore
        }
      }
    }
  }

  Future<void> _refreshLocalBytes() async {
    if (!_isNetwork) {
      _bumpReloadToken();
      await _primeLocalBytesIfNeeded();
    }
  }

  Widget _buildImage() {
    final matrix = _finalMatrix();
    final keySalt = '${widget.selectedImage}|${matrix.hashCode}|$_reloadToken';

    if (_isNetwork) {
      final busted = _withCacheBust(widget.selectedImage);
      return ColorFiltered(
        colorFilter: ColorFilter.matrix(matrix),
        child: Image.network(
          busted,
          key: ValueKey(keySalt),
          fit: BoxFit.contain,
          gaplessPlayback: true,
        ),
      );
    } else {
      // Local file → bytes দিয়ে দেখাই (same path overwrite হলেও নতুন bytes)
      if (_localBytesCache == null) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      }
      return ColorFiltered(
        colorFilter: ColorFilter.matrix(matrix),
        child: Image.memory(
          _localBytesCache!,
          key: ValueKey(keySalt),
          fit: BoxFit.contain,
          gaplessPlayback: true,
        ),
      );
    }
  }

  void _goPreview() async {
    // Preview-এ যাওয়ার আগে hard refresh নিশ্চিত করি
    if (_isNetwork) {
      _evictNetworkImage(widget.selectedImage);
    } else {
      await _refreshLocalBytes();
    }
    _bumpReloadToken();

    final forwarded = _isNetwork
        ? _withCacheBust(widget.selectedImage)
        : widget.selectedImage;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostPreviewScreen(
          image: forwarded,
          caption: _captionController.text,
          tags: _tagsController.text,
          filter: _selectedFilter,
          location: widget.selectedLocation,
          brightness: _brightness,
          contrast: _contrast,
          saturation: _saturation,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final h = mq.size.height;
    final w = mq.size.width;

    final keyboardOpen = mq.viewInsets.bottom > 0;
    final topImageHeight = keyboardOpen ? h * 0.30 : h * 0.52;

    return Scaffold(
      resizeToAvoidBottomInset: true,
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
                      Color.lerp(
                        Colors.purple.shade400,
                        Colors.purple.shade500,
                        _backgroundAnimation.value,
                      )!,
                      Color.lerp(
                        Colors.pink.shade400,
                        Colors.pink.shade500,
                        _backgroundAnimation.value,
                      )!,
                      Color.lerp(
                        Colors.red.shade400,
                        Colors.red.shade500,
                        _backgroundAnimation.value,
                      )!,
                      Color.lerp(
                        Colors.orange.shade400,
                        Colors.orange.shade500,
                        _backgroundAnimation.value,
                      )!,
                    ],
                    stops: const [0.0, 0.3, 0.7, 1.0],
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.bottomLeft,
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

          SafeArea(
            child: Column(
              children: [
                // App Bar
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                        const Text(
                          'Edit Photo',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.white),
                          onPressed: _goPreview,
                        ),
                      ],
                    ),
                  ),
                ),

                // Top Image
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      width: w,
                      height: topImageHeight,
                      margin: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.30),
                            spreadRadius: 5,
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          color: Colors.black,
                          alignment: Alignment.center,
                          child: _buildImage(),
                        ),
                      ),
                    ),
                  ),
                ),

                // Controls (scrollable)
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(
                      16,
                      0,
                      16,
                      20 + mq.viewInsets.bottom,
                    ),
                    child: Column(
                      children: [
                        // Filters
                        SizedBox(
                          height: 90,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: filters.length,
                            itemBuilder: (context, index) {
                              final filter = filters[index];
                              final name = filter['name'] as String;
                              final isSelected = name == _selectedFilter;
                              return GestureDetector(
                                onTap: () => _selectFilter(name),
                                child: Container(
                                  width: 80,
                                  margin: const EdgeInsets.only(right: 12),
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.white.withOpacity(0.2),
                                          border: isSelected
                                              ? Border.all(
                                                  color: Colors.white,
                                                  width: 2,
                                                )
                                              : null,
                                        ),
                                        child: Icon(
                                          filter['icon'] as IconData,
                                          color: isSelected
                                              ? Colors.purple
                                              : Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        name,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.white.withOpacity(0.8),
                                          fontSize: 12,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Adjustments
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              _buildSlider(
                                'Brightness',
                                _brightness,
                                Icons.wb_sunny,
                                onChanged: (v) {
                                  setState(() => _brightness = v);
                                  _bumpReloadToken();
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildSlider(
                                'Contrast',
                                _contrast,
                                Icons.tonality,
                                onChanged: (v) {
                                  setState(() => _contrast = v);
                                  _bumpReloadToken();
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildSlider(
                                'Saturation',
                                _saturation,
                                Icons.color_lens,
                                onChanged: (v) {
                                  setState(() => _saturation = v);
                                  _bumpReloadToken();
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Caption & Tags
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              TextField(
                                controller: _captionController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'Write a caption...',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                  ),
                                  focusedBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white),
                                  ),
                                ),
                                maxLines: 3,
                                textInputAction: TextInputAction.newline,
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _tagsController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText:
                                      'Add tags (e.g., #photography #travel)',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                  ),
                                  focusedBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white),
                                  ),
                                ),
                                textInputAction: TextInputAction.done,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Next Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _goPreview,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.purple,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Next',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
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

  Widget _buildSlider(
    String label,
    double value,
    IconData icon, {
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    value.toStringAsFixed(2),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
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
