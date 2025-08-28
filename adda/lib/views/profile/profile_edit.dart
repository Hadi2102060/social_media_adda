// lib/views/profile/profile_edit.dart
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';

class ProfileEdit extends StatefulWidget {
  const ProfileEdit({super.key});

  @override
  State<ProfileEdit> createState() => _ProfileEditState();
}

class _ProfileEditState extends State<ProfileEdit>
    with TickerProviderStateMixin {
  // Animations
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _backgroundController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _backgroundAnimation;

  // Form & Controllers
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: '');
  final _usernameController = TextEditingController(text: '');
  final _bioController = TextEditingController(text: '');
  final _emailController = TextEditingController(text: '');
  final _phoneController = TextEditingController(text: '');
  final _locationController = TextEditingController(text: '');
  final _websiteController = TextEditingController(text: '');

  bool _isLoading = false;
  bool _initialLoading = true;
  bool _isPrivateAccount = false;
  bool _showEmail = true;
  bool _showPhone = true;

  // Firebase
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseDatabase.instance;
  DatabaseReference? _userRef;
  StreamSubscription<DatabaseEvent>? _userSub;

  // Photo (no Firebase Storage)
  // live-picked sources
  File? _localImageFile; // camera/gallery path
  Uint8List? _localImageBytes; // drive/files bytes
  String? _pickedExt; // jpg/png/webp/heic
  // saved on server (Realtime DB)
  String? _photoBase64; // <- আমরা এটা DB তে রাখবো

  // base64 size guard (ইচ্ছামতো ছোটাও)
  static const int _maxBase64Bytes = 300 * 1024; // ~300KB target

  @override
  void initState() {
    super.initState();

    // Animations
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

    _attachUserStream();
  }

  void _attachUserStream() {
    final user = _auth.currentUser;
    if (user == null) {
      Future.microtask(() {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Not logged in')));
        Navigator.pop(context);
      });
      return;
    }

    _userRef = _db.ref('users/${user.uid}');
    _userSub = _userRef!.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        if (_initialLoading) {
          _nameController.text = (data['name'] ?? '') as String;
          _usernameController.text = (data['username'] ?? '') as String;
          _bioController.text = (data['bio'] ?? '') as String;
          _emailController.text = (data['email'] ?? '') as String;
          _phoneController.text = (data['phone'] ?? '') as String;
          _locationController.text = (data['location'] ?? '') as String;
          _websiteController.text = (data['website'] ?? '') as String;

          _isPrivateAccount = (data['isPrivateAccount'] ?? false) as bool;
          _showEmail = (data['showEmail'] ?? true) as bool;
          _showPhone = (data['showPhone'] ?? true) as bool;

          _photoBase64 = (data['photoBase64'] ?? null) as String?;

          setState(() => _initialLoading = false);
        } else {
          _photoBase64 = (data['photoBase64'] ?? _photoBase64) as String?;
          setState(() {});
        }
      } else {
        setState(() => _initialLoading = false);
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _backgroundController.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _websiteController.dispose();
    _userSub?.cancel();
    super.dispose();
  }

  // ===== Image picking =====
  Future<void> _pickImageBottomSheet() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Camera'),
              onTap: () async {
                Navigator.pop(ctx);
                await _pickFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () async {
                Navigator.pop(ctx);
                await _pickFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.cloud_upload_outlined),
              title: const Text('Drive / Files'),
              subtitle: const Text(
                'Pick from file provider (Google Drive supported)',
              ),
              onTap: () async {
                Navigator.pop(ctx);
                await _pickFromFiles();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromCamera() async {
    final x = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (x != null) {
      setState(() {
        _localImageFile = File(x.path);
        _localImageBytes = null;
        _pickedExt = _extFromPath(x.path);
      });
    }
  }

  Future<void> _pickFromGallery() async {
    final x = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (x != null) {
      setState(() {
        _localImageFile = File(x.path);
        _localImageBytes = null;
        _pickedExt = _extFromPath(x.path);
      });
    }
  }

  Future<void> _pickFromFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true, // Drive case: bytes আসে
    );
    if (result != null) {
      final f = result.files.single;
      setState(() {
        _localImageFile = null;
        _localImageBytes = f.bytes;
        _pickedExt = _extFromPath(f.name);
      });
    }
  }

  String _extFromPath(String pathOrName) {
    final p = pathOrName.toLowerCase();
    if (p.endsWith('.jpeg')) return 'jpeg';
    if (p.endsWith('.jpg')) return 'jpg';
    if (p.endsWith('.png')) return 'png';
    if (p.endsWith('.webp')) return 'webp';
    if (p.endsWith('.heic')) return 'heic';
    return 'jpg';
  }

  ImageProvider _avatarProvider() {
    if (_localImageBytes != null) return MemoryImage(_localImageBytes!);
    if (_localImageFile != null) return FileImage(_localImageFile!);
    if (_photoBase64 != null && _photoBase64!.isNotEmpty) {
      try {
        return MemoryImage(base64Decode(_photoBase64!));
      } catch (_) {}
    }
    return const NetworkImage('https://i.pravatar.cc/100?img=65');
  }

  // ===== base64 encode (no Firebase Storage) =====
  Future<String?> _encodePickedPhotoToBase64() async {
    // নতুন ছবি পিক না করলে null
    if (_localImageFile == null && _localImageBytes == null) return null;

    Uint8List bytes;
    if (_localImageBytes != null) {
      bytes = _localImageBytes!;
    } else {
      bytes = await _localImageFile!.readAsBytes();
    }

    // লিমিট (approx) – চাইলে UI-তে কমিয়ে নিও (imageQuality আরো কম)
    if (bytes.length > _maxBase64Bytes) {
      // 300KB এর বেশি হলে ওয়ার্নিং
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Image too large (~${(bytes.length / 1024).toStringAsFixed(0)} KB). Try a smaller image.',
          ),
        ),
      );
      // তবু চাইলে সেভ করতে দাও:
      // return base64Encode(bytes);
      return null;
    }

    return base64Encode(bytes);
  }

  Future<void> _saveProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final b64 = await _encodePickedPhotoToBase64();

      final payload = <String, dynamic>{
        'name': _nameController.text.trim(),
        'username': _usernameController.text.trim(),
        'bio': _bioController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'location': _locationController.text.trim(),
        'website': _websiteController.text.trim(),
        'isPrivateAccount': _isPrivateAccount,
        'showEmail': _showEmail,
        'showPhone': _showPhone,
        'updatedAt': ServerValue.timestamp,
      };

      if (b64 != null && b64.isNotEmpty) {
        payload['photoBase64'] = b64;
      }

      await _userRef!.update(payload);

      setState(() {
        if (b64 != null && b64.isNotEmpty) {
          _photoBase64 = b64;
          // লোকাল প্রিভিউ ক্লিয়ার (ইচ্ছা হলে রেখে দাও)
          // _localImageBytes = null; _localImageFile = null;
        }
        _isLoading = false;
      });

      _showSuccessDialog();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
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
                'Profile Updated!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                'Your profile has been successfully updated.',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // dialog
                  Navigator.pop(context); // back
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
                child: const Text('Continue', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== UI =====
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated background
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
                        Colors.teal.shade400,
                        Colors.teal.shade500,
                        _backgroundAnimation.value,
                      )!,
                      Color.lerp(
                        Colors.cyan.shade400,
                        Colors.cyan.shade500,
                        _backgroundAnimation.value,
                      )!,
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
            child: _initialLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // App Bar
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: Row(
                              children: const [
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Edit Profile',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Avatar
                          SlideTransition(
                            position: _slideAnimation,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: Container(
                                padding: const EdgeInsets.all(20),
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
                                  children: [
                                    Stack(
                                      children: [
                                        Container(
                                          width: 100,
                                          height: 100,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            image: DecorationImage(
                                              image: _avatarProvider(),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Container(
                                            decoration: const BoxDecoration(
                                              color: Colors.blue,
                                              shape: BoxShape.circle,
                                            ),
                                            child: IconButton(
                                              icon: const Icon(
                                                Icons.camera_alt,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                              onPressed: _pickImageBottomSheet,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    TextButton(
                                      onPressed: _pickImageBottomSheet,
                                      child: const Text(
                                        'Change Profile Photo',
                                        style: TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Form fields
                          SlideTransition(
                            position: _slideAnimation,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: Container(
                                padding: const EdgeInsets.all(20),
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
                                  children: [
                                    _field(
                                      _nameController,
                                      'Full Name',
                                      Icons.person_outline,
                                      validator: (v) => (v == null || v.isEmpty)
                                          ? 'Please enter your name'
                                          : null,
                                    ),
                                    const SizedBox(height: 16),
                                    _field(
                                      _usernameController,
                                      'Username',
                                      Icons.alternate_email,
                                      validator: (v) => (v == null || v.isEmpty)
                                          ? 'Please enter a username'
                                          : null,
                                    ),
                                    const SizedBox(height: 16),
                                    _field(
                                      _bioController,
                                      'Bio',
                                      Icons.description_outlined,
                                      maxLines: 3,
                                    ),
                                    const SizedBox(height: 16),
                                    _field(
                                      _emailController,
                                      'Email',
                                      Icons.email_outlined,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (v) => (v == null || v.isEmpty)
                                          ? 'Please enter your email'
                                          : null,
                                    ),
                                    const SizedBox(height: 16),
                                    _field(
                                      _phoneController,
                                      'Phone',
                                      Icons.phone_outlined,
                                      keyboardType: TextInputType.phone,
                                    ),
                                    const SizedBox(height: 16),
                                    _field(
                                      _locationController,
                                      'Location',
                                      Icons.location_on_outlined,
                                    ),
                                    const SizedBox(height: 16),
                                    _field(
                                      _websiteController,
                                      'Website',
                                      Icons.link,
                                      keyboardType: TextInputType.url,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Privacy
                          SlideTransition(
                            position: _slideAnimation,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: Container(
                                padding: const EdgeInsets.all(20),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Privacy Settings',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _switch(
                                      'Private Account',
                                      'Only approved followers can see your posts',
                                      _isPrivateAccount,
                                      (v) =>
                                          setState(() => _isPrivateAccount = v),
                                      Icons.lock_outline,
                                    ),
                                    const SizedBox(height: 8),
                                    _switch(
                                      'Show Email',
                                      'Allow others to see your email',
                                      _showEmail,
                                      (v) => setState(() => _showEmail = v),
                                      Icons.email_outlined,
                                    ),
                                    const SizedBox(height: 8),
                                    _switch(
                                      'Show Phone',
                                      'Allow others to see your phone number',
                                      _showPhone,
                                      (v) => setState(() => _showPhone = v),
                                      Icons.phone_outlined,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),

                          // Save
                          SlideTransition(
                            position: _slideAnimation,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _saveProfile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          'Save Changes',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // helpers (UI)
  Widget _field(
    TextEditingController c,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: c,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Colors.blue, width: 2),
          ),
          errorBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Colors.red),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _switch(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeColor: Colors.blue),
        ],
      ),
    );
  }
}
