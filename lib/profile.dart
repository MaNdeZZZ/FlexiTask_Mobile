import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'signin_signup.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'resetpassword.dart';
import 'services/google_auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isEditing = false;
  String? _profileImagePath;
  File? _profileImageFile;
  String? _profileImageUrl;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _checkFirebaseInitialization();
    _loadProfileData();
  }

  Future<void> _checkFirebaseInitialization() async {
    try {
      await Firebase.initializeApp();
      debugPrint('Firebase initialized successfully');
    } catch (e) {
      debugPrint('Firebase initialization error: $e');
    }
  }

  Future<void> _loadProfileData() async {
    final googleUser = await GoogleAuthService.getCurrentUser();
    final user = FirebaseAuth.instance.currentUser;
    String? name;

    if (user != null) {
      debugPrint('Loading profile for user: ${user.uid}, email: ${user.email}');
      try {
        final doc = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('profile')
            .doc('user')
            .get();
        if (doc.exists) {
          name = doc['name'] as String?;
          debugPrint('Loaded name from Firestore: $name');
        } else {
          debugPrint(
              'No profile document found in Firestore for user: ${user.uid}');
        }
      } catch (e, stackTrace) {
        debugPrint('Error loading name from Firestore: $e');
        debugPrint('Stack trace: $stackTrace');
      }
    } else {
      debugPrint('No authenticated user found');
    }

    setState(() {
      _nameController.text = name ??
          (googleUser != null
              ? googleUser['displayName'] ?? 'John Doe'
              : user?.displayName ?? 'John Doe');
      _emailController.text = googleUser != null
          ? googleUser['email'] ?? 'john.doe@example.com'
          : user?.email ?? 'john.doe@example.com';
      _profileImageUrl =
          googleUser != null ? googleUser['photoURL'] : user?.photoURL;
      debugPrint(
          'Set name: ${_nameController.text}, email: ${_emailController.text}');
    });

    if (_profileImageUrl == null) {
      _loadProfileImage();
    }
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString('profileImagePath');
    if (savedPath != null && savedPath.isNotEmpty) {
      setState(() {
        _profileImagePath = savedPath;
      });
      debugPrint('Loaded profile image path: $savedPath');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text(
                  'Take a photo',
                  style: TextStyle(fontFamily: 'Lexend'),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text(
                  'Choose from gallery',
                  style: TextStyle(fontFamily: 'Lexend'),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _profileImageFile = File(pickedFile.path);
          _profileImagePath = pickedFile.path;
        });
        _saveProfileImage(pickedFile.path);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Error accessing image. Please check your permissions.'),
        ),
      );
    }
  }

  void _saveProfileImage(String imagePath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profileImagePath', imagePath);
    setState(() {
      _profileImagePath = imagePath;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile picture updated')),
    );
    debugPrint('Saved profile image path: $imagePath');
  }

  Future<void> _saveName(String name) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user is signed in')),
      );
      debugPrint('Cannot save name: No authenticated user');
      return;
    }
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty')),
      );
      debugPrint('Cannot save name: Name is empty');
      return;
    }
    debugPrint(
        'Saving name: $name for user: ${user.uid}, email: ${user.email}');
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('profile')
          .doc('user')
          .set({'name': name.trim()}, SetOptions(merge: true));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name updated successfully')),
      );
      debugPrint('Name saved successfully to Firestore');

      // Fallback: Update Firebase Auth displayName
      try {
        await user.updateDisplayName(name.trim());
        debugPrint('Updated Firebase Auth displayName: $name');
      } catch (e) {
        debugPrint('Error updating Firebase Auth displayName: $e');
      }
    } catch (e, stackTrace) {
      debugPrint('Error saving name to Firestore: $e');
      debugPrint('Stack trace: $stackTrace');
      String errorMessage;
      if (e.toString().contains('PERMISSION_DENIED')) {
        errorMessage = 'Permission denied. Check Firestore rules.';
      } else if (e.toString().contains('UNAUTHENTICATED')) {
        errorMessage = 'User not authenticated. Please sign in again.';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network error. Check your connection.';
      } else {
        errorMessage = 'Error updating name: $e';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );

      // Fallback: Update Firebase Auth displayName even if Firestore fails
      try {
        await user.updateDisplayName(name.trim());
        debugPrint('Fallback: Updated Firebase Auth displayName: $name');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Name updated in Firebase Auth as fallback')),
        );
      } catch (fallbackError) {
        debugPrint('Error in fallback Firebase Auth update: $fallbackError');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          color: Colors.black,
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(color: Colors.white),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Profile',
                              style: TextStyle(
                                fontFamily: 'Lexend',
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Column(
                                  children: [
                                    Stack(
                                      children: [
                                        Container(
                                          width: 120,
                                          height: 120,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.grey[200],
                                          ),
                                          child: ClipOval(
                                            child: _buildProfileImage(),
                                          ),
                                        ),
                                        Positioned(
                                          right: 0,
                                          bottom: 0,
                                          child: GestureDetector(
                                            onTap: _showImageSourceOptions,
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFD9D9D9),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 2,
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.camera_alt,
                                                size: 20,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Personal Information',
                                    style: TextStyle(
                                      fontFamily: 'Lexend',
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        if (_isEditing) {
                                          _saveName(_nameController.text);
                                        }
                                        _isEditing = !_isEditing;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFD9D9D9),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.edit,
                                        size: 16,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                label: 'Name',
                                controller: _nameController,
                                icon: Icons.person,
                                enabled: _isEditing,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                label: 'Email (Non-editable)',
                                controller: _emailController,
                                icon: Icons.email,
                                keyboardType: TextInputType.emailAddress,
                                enabled: false,
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'Account',
                                style: TextStyle(
                                  fontFamily: 'Lexend',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildActionButton(
                                title: 'Change Password',
                                icon: Icons.lock,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ResetPasswordScreen(),
                                    ),
                                  );
                                },
                              ),
                              _buildActionButton(
                                title: 'Log Out',
                                icon: Icons.logout,
                                isDestructive: true,
                                onTap: () async {
                                  await GoogleAuthService.signOut();
                                  _clearRememberMeCredentials();
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SignInSignUpScreen(),
                                    ),
                                    (route) => false,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? Colors.white : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          labelStyle: const TextStyle(fontFamily: 'Lexend'),
        ),
        style: const TextStyle(fontFamily: 'Lexend'),
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ListTile(
        leading: Icon(icon, color: isDestructive ? Colors.red : null),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'Lexend',
            color: isDestructive ? Colors.red : null,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  void _clearRememberMeCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rememberMe', false);
    await prefs.remove('email');
    await prefs.remove('password');
    await prefs.remove('rememberMeExpiry');
    debugPrint("Logout: Remember me credentials cleared");
  }

  Widget _buildProfileImage() {
    if (_profileImageUrl != null) {
      return Image.network(
        _profileImageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset('assets/images/logo.png', fit: BoxFit.cover);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
      );
    } else if (_profileImagePath != null) {
      if (_profileImagePath!.startsWith('/') ||
          _profileImagePath!.startsWith('file:')) {
        return Image.file(
          File(_profileImagePath!),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Image.asset('assets/images/logo.png', fit: BoxFit.cover);
          },
        );
      } else {
        return Image.asset(_profileImagePath!, fit: BoxFit.cover);
      }
    } else {
      return Image.asset('assets/images/logo.png', fit: BoxFit.cover);
    }
  }
}
