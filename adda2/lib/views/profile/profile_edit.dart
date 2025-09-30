import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileEdit extends StatefulWidget {
  const ProfileEdit({super.key});

  @override
  State<ProfileEdit> createState() => _ProfileEditState();
}

class _ProfileEditState extends State<ProfileEdit>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _backgroundController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _backgroundAnimation;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _websiteController = TextEditingController();

  bool _isLoading = false;
  bool _isPrivateAccount = false;
  bool _showEmail = true;
  bool _showPhone = true;

  String? _profileImageUrl;
  File? _selectedImage;
  bool _isUploadingImage = false;

  final ImagePicker _picker = ImagePicker();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );
    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
    _slideController.forward();
    _backgroundController.repeat(reverse: true);

    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!mounted) return;

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _nameController.text = data['name'] ?? '';
          _usernameController.text = data['username'] ?? '';
          _bioController.text = data['bio'] ?? '';
          _emailController.text = data['email'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _locationController.text = data['location'] ?? '';
          _websiteController.text = data['website'] ?? '';
          _profileImageUrl = data['profileImage'];
          _isPrivateAccount = data['isPrivateAccount'] ?? false;
          _showEmail = data['showEmail'] ?? true;
          _showPhone = data['showPhone'] ?? true;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading profile data')));
      }
    }
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
    super.dispose();
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Choose from gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_camera),
              title: Text('Take a photo'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text(
                  'Remove current photo',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _removeProfileImage();
                },
              ),
            ListTile(
              leading: Icon(Icons.close),
              title: Text('Cancel'),
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeProfileImage() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      setState(() {
        _isUploadingImage = true;
      });

      // Delete from Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'profileImage': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _profileImageUrl = null;
        _isUploadingImage = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile image removed successfully')),
        );
      }
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove image: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        await _convertAndSaveImage(File(pickedFile.path));
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _convertAndSaveImage(File imageFile) async {
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('User not logged in')));
      }
      return;
    }

    setState(() {
      _isUploadingImage = true;
      _selectedImage = imageFile;
    });

    try {
      // Convert image to base64 string
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      // Create data URL for displaying
      String imageDataUrl = 'data:image/jpeg;base64,$base64Image';

      print('Image converted to base64, length: ${base64Image.length}');

      // Update Firestore with base64 image data
      await _updateProfileImageInFirestore(imageDataUrl);

      setState(() {
        _profileImageUrl = imageDataUrl;
        _selectedImage = null;
        _isUploadingImage = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile image updated successfully!')),
        );
      }
    } catch (e) {
      print('Error converting image: $e');
      setState(() {
        _isUploadingImage = false;
        _selectedImage = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update image: ${e.toString()}'),
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _updateProfileImageInFirestore(String imageDataUrl) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Update ONLY Firestore with base64 image data
      // Removed Firebase Auth update to avoid photoURL too long error
      await _firestore.collection('users').doc(user.uid).update({
        'profileImage': imageDataUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('Firestore updated successfully with base64 image');
    } catch (e) {
      print('Error updating Firestore: $e');
      throw e;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final user = _auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('User not logged in')));
      }
      return;
    }

    try {
      final userData = {
        'name': _nameController.text.trim(),
        'username': _usernameController.text.trim().toLowerCase(),
        'bio': _bioController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'location': _locationController.text.trim(),
        'website': _websiteController.text.trim(),
        'isPrivateAccount': _isPrivateAccount,
        'showEmail': _showEmail,
        'showPhone': _showPhone,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Only add profileImage if it exists
      if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
        userData['profileImage'] = _profileImageUrl as Object;
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userData, SetOptions(merge: true));

      setState(() => _isLoading = false);
      _showSuccessDialog();
    } catch (e) {
      print('Error saving profile: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: ${e.toString()}')),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check, color: Colors.white, size: 40),
              ),
              SizedBox(height: 20),
              Text(
                'Profile Updated!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'Your profile has been successfully updated.',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text('Continue', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
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
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: labelText,
          prefixIcon: Icon(icon, color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
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

  Widget _buildProfileImage() {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: _isUploadingImage
                ? Container(
                    color: Colors.grey[200],
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Colors.blue,
                        strokeWidth: 3,
                      ),
                    ),
                  )
                : _selectedImage != null
                ? Image.file(
                    _selectedImage!,
                    fit: BoxFit.cover,
                    width: 100,
                    height: 100,
                  )
                : _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                ? _profileImageUrl!.startsWith('data:image/')
                      ? Image.memory(
                          base64Decode(_profileImageUrl!.split(',').last),
                          fit: BoxFit.cover,
                          width: 100,
                          height: 100,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.grey[400],
                              ),
                            );
                          },
                        )
                      : Image.network(
                          _profileImageUrl!,
                          fit: BoxFit.cover,
                          width: 100,
                          height: 100,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey[200],
                              child: Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: Colors.blue,
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.grey[400],
                              ),
                            );
                          },
                        )
                : Container(
                    color: Colors.grey[200],
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.grey[400],
                    ),
                  ),
          ),
        ),
        if (_isUploadingImage)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.6),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
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
                    stops: [0.0, 0.3, 0.7, 1.0],
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
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Spacer(),
                          Text(
                            'Edit Profile',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Spacer(),
                          SizedBox(width: 48),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          padding: EdgeInsets.all(20),
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
                              Stack(
                                children: [
                                  _buildProfileImage(),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.3,
                                            ),
                                            blurRadius: 6,
                                            offset: Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: IconButton(
                                        icon: Icon(
                                          Icons.camera_alt,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        onPressed: _isUploadingImage
                                            ? null
                                            : _showImageSourceSheet,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              Text(
                                _isUploadingImage
                                    ? 'Uploading...'
                                    : 'Change Profile Photo',
                                style: TextStyle(
                                  color: _isUploadingImage
                                      ? Colors.grey
                                      : Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          padding: EdgeInsets.all(20),
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
                              _buildTextField(
                                controller: _nameController,
                                labelText: 'Full Name',
                                icon: Icons.person_outline,
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Please enter your name'
                                    : null,
                              ),
                              SizedBox(height: 16),
                              _buildTextField(
                                controller: _usernameController,
                                labelText: 'Username',
                                icon: Icons.alternate_email,
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Please enter a username'
                                    : null,
                              ),
                              SizedBox(height: 16),
                              _buildTextField(
                                controller: _bioController,
                                labelText: 'Bio',
                                icon: Icons.description_outlined,
                                maxLines: 3,
                              ),
                              SizedBox(height: 16),
                              _buildTextField(
                                controller: _emailController,
                                labelText: 'Email',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Please enter your email'
                                    : null,
                              ),
                              SizedBox(height: 16),
                              _buildTextField(
                                controller: _phoneController,
                                labelText: 'Phone',
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                              ),
                              SizedBox(height: 16),
                              _buildTextField(
                                controller: _locationController,
                                labelText: 'Location',
                                icon: Icons.location_on_outlined,
                              ),
                              SizedBox(height: 16),
                              _buildTextField(
                                controller: _websiteController,
                                labelText: 'Website',
                                icon: Icons.link,
                                keyboardType: TextInputType.url,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          padding: EdgeInsets.all(20),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Privacy Settings',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 16),
                              _buildSwitchTile(
                                'Private Account',
                                'Only approved followers can see your posts',
                                _isPrivateAccount,
                                (v) => setState(() => _isPrivateAccount = v),
                                Icons.lock_outline,
                              ),
                              SizedBox(height: 8),
                              _buildSwitchTile(
                                'Show Email',
                                'Allow others to see your email',
                                _showEmail,
                                (v) => setState(() => _showEmail = v),
                                Icons.email_outlined,
                              ),
                              SizedBox(height: 8),
                              _buildSwitchTile(
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
                    SizedBox(height: 30),
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: (_isLoading || _isUploadingImage)
                                ? null
                                : _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
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
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
