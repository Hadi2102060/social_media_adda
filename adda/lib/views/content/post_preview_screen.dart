import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PostPreviewScreen extends StatefulWidget {
  final String image; // http(s) url or local file path
  final String caption;
  final String tags;
  final String filter;
  final String? location;

  // optional tone controls (defaults 0.0)
  final double brightness; // [-1..1]
  final double contrast; // [-1..1]
  final double saturation; // [-1..1]

  const PostPreviewScreen({
    super.key,
    required this.image,
    required this.caption,
    required this.tags,
    required this.filter,
    this.location,
    this.brightness = 0.0,
    this.contrast = 0.0,
    this.saturation = 0.0,
  });

  @override
  State<PostPreviewScreen> createState() => _PostPreviewScreenState();
}

class _PostPreviewScreenState extends State<PostPreviewScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _backgroundController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _backgroundAnimation;

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseDatabase.instance;
  final _storage = FirebaseStorage.instance;

  bool _isLoading = false;
  bool _addToStory = false;
  bool _shareToFacebook = false;
  bool _shareToTwitter = false;

  String _displayName = '';
  String _username = '';
  String? _avatarBase64;

  bool get _isNetwork =>
      widget.image.startsWith('http://') || widget.image.startsWith('https://');

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
      duration: const Duration(seconds: 4),
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

    _loadCurrentUser();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final u = _auth.currentUser;
    if (u == null) return;
    try {
      final snap = await _db.ref('users/${u.uid}').get();
      final data = snap.value as Map<dynamic, dynamic>?;
      if (!mounted) return;
      setState(() {
        _displayName = (data?['name'] ?? u.displayName ?? '') as String;
        _username =
            (data?['username'] ??
                    (u.email != null ? u.email!.split('@').first : 'user'))
                as String;
        _avatarBase64 = data?['photoBase64'] as String?;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _displayName = _auth.currentUser?.displayName ?? '';
        _username = _auth.currentUser?.email?.split('@').first ?? 'user';
      });
    }
  }

  // ---------- Color Matrix ----------
  List<double> _identity() => const <double>[
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
    final preset = _presetMatrix(widget.filter);
    final satFactor = math.max(0.0, 1.0 + widget.saturation);
    final mSat = _saturationMatrix(satFactor);
    final mCB = _contrastBrightnessMatrix(widget.contrast, widget.brightness);
    var m = _mul(preset, mSat);
    m = _mul(m, mCB);
    return m;
  }

  Widget _buildEditedImage() {
    final img = _isNetwork
        ? Image.network(widget.image, fit: BoxFit.cover, gaplessPlayback: true)
        : Image.file(
            File(widget.image),
            fit: BoxFit.cover,
            gaplessPlayback: true,
          );
    return ColorFiltered(
      colorFilter: ColorFilter.matrix(_finalMatrix()),
      child: img,
    );
  }

  // -------- read & render edited PNG --------
  Future<Uint8List> _readImageBytes() async {
    if (_isNetwork) {
      final res = await http
          .get(Uri.parse(widget.image))
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) return res.bodyBytes;
      throw Exception('Failed to fetch image: ${res.statusCode}');
    } else {
      return await File(widget.image).readAsBytes();
    }
  }

  Future<Uint8List> _renderEditedPngBytes() async {
    final srcBytes = await _readImageBytes();

    // decode
    var codec = await ui.instantiateImageCodec(srcBytes);
    var frame = await codec.getNextFrame();
    int w = frame.image.width;
    int h = frame.image.height;

    // downscale (perf)
    const int maxDim = 1536;
    if (w > maxDim || h > maxDim) {
      final scale = (w > h) ? maxDim / w : maxDim / h;
      final tw = (w * scale).round();
      final th = (h * scale).round();
      codec = await ui.instantiateImageCodec(
        srcBytes,
        targetWidth: tw,
        targetHeight: th,
      );
      frame = await codec.getNextFrame();
      w = frame.image.width;
      h = frame.image.height;
    }

    final ui.Image src = frame.image;

    final recorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(recorder);
    final paint = Paint()..colorFilter = ColorFilter.matrix(_finalMatrix());

    final srcRect = Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble());
    canvas.drawImageRect(src, srcRect, srcRect, paint);

    final picture = recorder.endRecording();
    final ui.Image outImg = await picture.toImage(w, h);

    final byteData = await outImg.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw Exception('Failed to encode edited image');
    }
    return byteData.buffer.asUint8List();
  }

  // -------- Upload to Firebase Storage (returns URL or null on failure) --------
  Future<String?> _uploadEditedToStorage(Uint8List bytes) async {
    try {
      final u = _auth.currentUser!;
      final ts = DateTime.now().microsecondsSinceEpoch;
      final rnd = math.Random().nextInt(0x7fffffff);
      final ref = _storage.ref().child('posts/${u.uid}/$ts-$rnd.png');

      final meta = SettableMetadata(
        contentType: 'image/png',
        cacheControl: 'public, max-age=31536000',
      );

      final TaskSnapshot snap = await ref.putData(
        bytes,
        meta,
      ); // await real result
      if (snap.state != TaskState.success) {
        debugPrint('⚠️ Upload state: ${snap.state}');
        return null;
      }
      final url = await snap.ref.getDownloadURL();
      return url;
    } on FirebaseException catch (e) {
      debugPrint('❌ Storage upload error: ${e.code} ${e.message}');
      return null; // fallback to base64
    } catch (e) {
      debugPrint('❌ Upload error: $e');
      return null;
    }
  }

  // -------- Main: share post --------
  Future<void> _sharePost() async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('You are not logged in')));
      return;
    }
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      // 1) Edited bytes
      final editedPng = await _renderEditedPngBytes();

      // 2) Try Storage first
      String? imageUrl = await _uploadEditedToStorage(editedPng);

      // 3) Prepare payload (fallback to base64 if url is null)
      final postsRef = _db.ref('posts').push();
      final postId = postsRef.key!;
      final now = ServerValue.timestamp;

      final payload = <String, dynamic>{
        'id': postId,
        'authorId': user.uid,
        'authorName': _displayName,
        'authorUsername': _username,
        'caption': widget.caption.trim(),
        'tags': widget.tags.trim(),
        'location': widget.location,
        'filter': widget.filter,
        'brightness': widget.brightness,
        'contrast': widget.contrast,
        'saturation': widget.saturation,
        'imageUrl': imageUrl ?? '', // prefer URL
        'imageBase64':
            imageUrl ==
                null // fallback
            ? base64Encode(editedPng)
            : null,
        'likesCount': 0,
        'commentsCount': 0,
        'sharesCount': 0,
        'createdAt': now,
        'updatedAt': now,
      };

      final updates = <String, Object?>{
        '/posts/$postId': payload,
        '/user_posts/${user.uid}/$postId': true,
        '/feeds/${user.uid}/$postId': true,
      };
      await _db.ref().update(updates);

      if (!mounted) return;
      _showShareDialog();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to share: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showShareDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 20),
              const Text(
                'Post Shared!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Your post has been successfully shared.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text('Done', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------- UI --------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _backgroundAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.lerp(
                        Colors.blue.shade400,
                        Colors.blue.shade500,
                        _backgroundAnimation.value,
                      )!,
                      Color.lerp(
                        Colors.indigo.shade400,
                        Colors.indigo.shade500,
                        _backgroundAnimation.value,
                      )!,
                      Color.lerp(
                        Colors.purple.shade400,
                        Colors.purple.shade500,
                        _backgroundAnimation.value,
                      )!,
                      Color.lerp(
                        Colors.deepPurple.shade400,
                        Colors.deepPurple.shade500,
                        _backgroundAnimation.value,
                      )!,
                    ],
                    stops: const [0.0, 0.3, 0.7, 1.0],
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topRight,
                      radius: 1.5,
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
                          'Preview & Share',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.share, color: Colors.white),
                          onPressed: _isLoading ? null : _sharePost,
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.95),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    spreadRadius: 5,
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                    child: AspectRatio(
                                      aspectRatio: 1,
                                      child: _buildEditedImage(),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 16,
                                              backgroundImage:
                                                  _avatarBase64 != null
                                                  ? MemoryImage(
                                                      base64Decode(
                                                        _avatarBase64!.contains(
                                                              'base64,',
                                                            )
                                                            ? _avatarBase64!
                                                                  .split(
                                                                    'base64,',
                                                                  )
                                                                  .last
                                                            : _avatarBase64!,
                                                      ),
                                                    )
                                                  : const NetworkImage(
                                                          'https://i.pravatar.cc/100?img=65',
                                                        )
                                                        as ImageProvider,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              _username.isNotEmpty
                                                  ? _username
                                                  : 'you',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              'now',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        if (widget.caption.isNotEmpty)
                                          Text(
                                            widget.caption,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              height: 1.4,
                                            ),
                                          ),
                                        if (widget.tags.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            widget.tags,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.blue,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.filter,
                                              size: 16,
                                              color: Colors.grey[600],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Filter: ${widget.filter}',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (widget.location != null) ...[
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.location_on,
                                                size: 16,
                                                color: Colors.grey[600],
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                widget.location!,
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Share Options',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildShareOption(
                                    'Add to Story',
                                    _addToStory,
                                    (v) => setState(() => _addToStory = v),
                                    Icons.auto_stories,
                                  ),
                                  _buildShareOption(
                                    'Share to Facebook',
                                    _shareToFacebook,
                                    (v) => setState(() => _shareToFacebook = v),
                                    Icons.facebook,
                                  ),
                                  _buildShareOption(
                                    'Share to Twitter',
                                    _shareToTwitter,
                                    (v) => setState(() => _shareToTwitter = v),
                                    Icons.flutter_dash,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _sharePost,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.blue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.blue,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'Share Post',
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareOption(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeColor: Colors.white),
        ],
      ),
    );
  }
}
