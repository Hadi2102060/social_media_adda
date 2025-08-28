// lib/views/content/camera_screen.dart
//
// Requirements (pubspec.yaml):
// dependencies:
//   camera: ^0.10.5+5
//   image_picker: ^1.0.7
//   video_player: ^2.8.6
//
// AndroidManifest.xml permissions (app/src/main/AndroidManifest.xml):
// <uses-permission android:name="android.permission.CAMERA"/>
// <uses-permission android:name="android.permission.RECORD_AUDIO"/>
// <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="28"/>
// <uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
// <uses-permission android:name="android.permission.READ_MEDIA_VIDEO"/>
// (older devices) <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
//
// iOS (ios/Runner/Info.plist):
// <key>NSCameraUsageDescription</key><string>We need camera access to take photos</string>
// <key>NSMicrophoneUsageDescription</key><string>We need microphone for video</string>
// <key>NSPhotoLibraryUsageDescription</key><string>We need photo library access to pick images</string>

import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import 'package:adda/views/content/editing_screen.dart';
import 'package:adda/views/geolocation/location_screen.dart';
import 'package:adda/views/stories/story_creation_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});
  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

enum CaptureMode { photo, video, story, live }

class _CameraScreenState extends State<CameraScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _backgroundController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _backgroundAnimation;

  final ImagePicker _picker = ImagePicker();

  // Camera
  CameraController? _camCtrl;
  List<CameraDescription> _cameras = [];
  bool _isFront = false;
  bool _isFlashOn = false;
  bool _initializing = true;
  bool _isRecording = false;

  // UI
  bool _isLoadingShot = false;
  String? _selectedLocation;
  CaptureMode _mode = CaptureMode.photo;

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
      duration: const Duration(seconds: 5),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _backgroundAnimation = CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    );

    _fadeController.forward();
    _slideController.forward();
    _backgroundController.repeat(reverse: true);

    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      setState(() => _initializing = true);
      _cameras = await availableCameras();
      // pick lens
      CameraDescription? cam;
      if (_cameras.isEmpty) {
        cam = null;
      } else {
        final lens = _isFront
            ? CameraLensDirection.front
            : CameraLensDirection.back;
        cam = _cameras.firstWhere(
          (c) => c.lensDirection == lens,
          orElse: () => _cameras.first,
        );
      }

      await _camCtrl?.dispose();
      if (cam != null) {
        _camCtrl = CameraController(
          cam,
          _mode == CaptureMode.video
              ? ResolutionPreset.high
              : ResolutionPreset.medium,
          enableAudio: _mode == CaptureMode.video || _mode == CaptureMode.live,
        );
        await _camCtrl!.initialize();
        await _camCtrl!.setFlashMode(
          _isFlashOn ? FlashMode.torch : FlashMode.off,
        );
      } else {
        _camCtrl = null;
      }
    } catch (e) {
      // show placeholder silently
      _camCtrl = null;
    } finally {
      if (mounted) setState(() => _initializing = false);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _backgroundController.dispose();
    _camCtrl?.dispose();
    super.dispose();
  }

  Future<void> _toggleFlash() async {
    if (_camCtrl == null || !_camCtrl!.value.isInitialized) return;
    try {
      _isFlashOn = !_isFlashOn;
      await _camCtrl!.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off,
      );
      if (mounted) setState(() {});
    } catch (e) {
      _isFlashOn = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Flash not supported on this device')),
        );
        setState(() {});
      }
    }
  }

  Future<void> _switchCamera() async {
    _isFront = !_isFront;
    await _initCamera();
    setState(() {});
  }

  // --------- Capture / Pick ----------
  Future<void> _capturePhoto() async {
    if (_camCtrl == null || !_camCtrl!.value.isInitialized) {
      // fallback to system camera via image_picker
      final x = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 95,
      );
      if (x == null) return;
      _goToEditing(x.path);
      return;
    }
    try {
      setState(() => _isLoadingShot = true);
      final x = await _camCtrl!.takePicture();
      _goToEditing(x.path);
    } catch (_) {
      // fallback
      final x = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 95,
      );
      if (x != null) _goToEditing(x.path);
    } finally {
      if (mounted) setState(() => _isLoadingShot = false);
    }
  }

  Future<void> _pickFromGallery() async {
    if (_mode == CaptureMode.video) {
      final x = await _picker.pickVideo(source: ImageSource.gallery);
      if (x == null) return;
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _VideoPreviewScreen(filePath: x.path),
        ),
      );
      return;
    }
    final x = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 95,
    );
    if (x == null) return;
    _goToEditing(x.path);
  }

  Future<void> _recordVideoToggle() async {
    if (_camCtrl == null || !_camCtrl!.value.isInitialized) {
      // fallback to picker camera video
      if (!_isRecording) {
        final x = await _picker.pickVideo(source: ImageSource.camera);
        if (x != null && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => _VideoPreviewScreen(filePath: x.path),
            ),
          );
        }
      }
      return;
    }

    if (_isRecording) {
      try {
        final file = await _camCtrl!.stopVideoRecording();
        setState(() => _isRecording = false);
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _VideoPreviewScreen(filePath: file.path),
          ),
        );
      } catch (e) {
        setState(() => _isRecording = false);
      }
    } else {
      try {
        await _camCtrl!.startVideoRecording();
        setState(() => _isRecording = true);
      } catch (e) {
        setState(() => _isRecording = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to start recording')),
        );
      }
    }
  }

  void _goToEditing(String path) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditingScreen(
          selectedImage: path, // local file path
          selectedLocation: _selectedLocation,
        ),
      ),
    );
  }

  // --------- UI ----------
  @override
  Widget build(BuildContext context) {
    final bg = _buildAnimatedBackground();

    return Scaffold(
      body: Stack(
        children: [
          bg,
          SafeArea(
            child: Column(
              children: [
                // Top controls
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(
                            _isFlashOn ? Icons.flash_on : Icons.flash_off,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: _toggleFlash,
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.settings,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: () =>
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Camera settings coming soon!'),
                                ),
                              ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Camera preview
                Expanded(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (_initializing)
                                const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                )
                              else if (_camCtrl != null &&
                                  _camCtrl!.value.isInitialized)
                                CameraPreview(_camCtrl!)
                              else
                                _buildPreviewFallback(),
                              // Grid overlay
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: CameraGridPainter(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom Controls
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Row: Gallery • Location • Capture • Switch
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Gallery
                              _roundButton(
                                onTap: _pickFromGallery,
                                size: 58,
                                child: const Icon(
                                  Icons.photo_library,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),

                              // Location
                              _roundButton(
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => LocationScreen(
                                        onLocationSelected: (loc) => setState(
                                          () => _selectedLocation = loc,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                size: 58,
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),

                              // Capture / Record
                              GestureDetector(
                                onTap: () async {
                                  if (_mode == CaptureMode.video) {
                                    await _recordVideoToggle();
                                  } else if (_mode == CaptureMode.story) {
                                    if (!mounted) return;
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => StoryCreationScreen(),
                                      ),
                                    );
                                  } else if (_mode == CaptureMode.live) {
                                    if (!mounted) return;
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => _LivePreviewScreen(
                                          camCtrl: _camCtrl,
                                        ),
                                      ),
                                    );
                                  } else {
                                    // photo
                                    await _capturePhoto();
                                  }
                                },
                                child: Container(
                                  width: 84,
                                  height: 84,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 4,
                                    ),
                                  ),
                                  child: _isLoadingShot
                                      ? const Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 3,
                                          ),
                                        )
                                      : Container(
                                          margin: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: _mode == CaptureMode.video
                                                ? (_isRecording
                                                      ? Colors.red
                                                      : Colors.white
                                                            .withOpacity(0.25))
                                                : Colors.white.withOpacity(
                                                    0.25,
                                                  ),
                                          ),
                                        ),
                                ),
                              ),

                              // Switch camera
                              _roundButton(
                                onTap: _switchCamera,
                                size: 58,
                                child: const Icon(
                                  Icons.flip_camera_ios,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ],
                          ),

                          if (_selectedLocation != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _selectedLocation!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => setState(
                                      () => _selectedLocation = null,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 10),

                          // Mode selector: Photo | Video | Story | Live
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _modeButton(
                                'Photo',
                                Icons.camera_alt,
                                _mode == CaptureMode.photo,
                                () async {
                                  setState(() => _mode = CaptureMode.photo);
                                  await _initCamera();
                                },
                              ),
                              _modeButton(
                                'Video',
                                Icons.videocam,
                                _mode == CaptureMode.video,
                                () async {
                                  setState(() => _mode = CaptureMode.video);
                                  await _initCamera();
                                },
                              ),
                              _modeButton(
                                'Story',
                                Icons.auto_stories,
                                _mode == CaptureMode.story,
                                () {
                                  setState(() => _mode = CaptureMode.story);
                                },
                              ),
                              _modeButton(
                                'Live',
                                Icons.live_tv,
                                _mode == CaptureMode.live,
                                () async {
                                  setState(() => _mode = CaptureMode.live);
                                  await _initCamera();
                                },
                              ),
                            ],
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

  // ---------- UI helpers ----------
  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _backgroundAnimation,
      builder: (_, __) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(
                  Colors.black,
                  Colors.grey.shade900,
                  _backgroundAnimation.value,
                )!,
                Color.lerp(
                  Colors.grey.shade800,
                  Colors.grey.shade700,
                  _backgroundAnimation.value,
                )!,
                Color.lerp(
                  Colors.grey.shade700,
                  Colors.grey.shade600,
                  _backgroundAnimation.value,
                )!,
                Color.lerp(
                  Colors.grey.shade600,
                  Colors.grey.shade500,
                  _backgroundAnimation.value,
                )!,
              ],
              stops: const [0.0, 0.3, 0.7, 1.0],
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [Colors.white.withOpacity(0.05), Colors.transparent],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreviewFallback() {
    return Container(
      color: Colors.black12,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.camera_alt, size: 80, color: Colors.white70),
            SizedBox(height: 10),
            Text(
              'Camera not available',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roundButton({
    required VoidCallback onTap,
    required double size,
    required Widget child,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size / 5),
          border: Border.all(color: Colors.white, width: 2),
          color: Colors.white.withOpacity(0.1),
        ),
        child: Center(child: child),
      ),
    );
  }

  Widget _modeButton(
    String label,
    IconData icon,
    bool selected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? Colors.white : Colors.white.withOpacity(0.2),
            ),
            child: Icon(
              icon,
              color: selected ? Colors.black : Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.white70,
              fontSize: 12,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class CameraGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..strokeWidth = 1;

    // Vertical
    canvas.drawLine(
      Offset(size.width / 3, 0),
      Offset(size.width / 3, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(2 * size.width / 3, 0),
      Offset(2 * size.width / 3, size.height),
      paint,
    );
    // Horizontal
    canvas.drawLine(
      Offset(0, size.height / 3),
      Offset(size.width, size.height / 3),
      paint,
    );
    canvas.drawLine(
      Offset(0, 2 * size.height / 3),
      Offset(size.width, 2 * size.height / 3),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Simple video preview (plays the recorded/selected video)
class _VideoPreviewScreen extends StatefulWidget {
  final String filePath;
  const _VideoPreviewScreen({required this.filePath});
  @override
  State<_VideoPreviewScreen> createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<_VideoPreviewScreen> {
  late VideoPlayerController _vc;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _vc = VideoPlayerController.file(File(widget.filePath))
      ..initialize().then((_) {
        _vc.setLooping(true);
        _vc.play();
        if (mounted) setState(() => _ready = true);
      });
  }

  @override
  void dispose() {
    _vc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video Preview')),
      body: Center(
        child: _ready
            ? AspectRatio(
                aspectRatio: _vc.value.aspectRatio,
                child: VideoPlayer(_vc),
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}

/// Live preview (no real streaming; shows camera with mic enabled)
class _LivePreviewScreen extends StatelessWidget {
  final CameraController? camCtrl;
  const _LivePreviewScreen({required this.camCtrl});

  @override
  Widget build(BuildContext context) {
    final ctrl = camCtrl;
    return Scaffold(
      appBar: AppBar(title: const Text('Live Preview')),
      body: ctrl != null && ctrl.value.isInitialized
          ? Stack(
              children: [
                Positioned.fill(child: CameraPreview(ctrl)),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Live streaming coming soon'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.wifi_tethering),
                      label: const Text('Go Live'),
                    ),
                  ),
                ),
              ],
            )
          : const Center(child: Text('Camera not available')),
    );
  }
}
