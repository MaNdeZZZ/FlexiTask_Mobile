import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'signin_signup.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'resetpassword.dart';
import 'services/google_auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Controllers for text fields
  final TextEditingController _nameController = TextEditingController(
    text: "John Doe",
  );
  final TextEditingController _emailController = TextEditingController(
    text: "john.doe@example.com",
  );

  // Edit mode state
  bool _isEditing = false;

  // Updated to handle real file paths
  String? _profileImagePath;
  File? _profileImageFile;

  // URL for profile image from Google
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    // Load profile image and user data
    _loadProfileData();
  }

  // Load profile data including Google account info
  Future<void> _loadProfileData() async {
    // Try to get Google user data first
    final googleUser = await GoogleAuthService.getCurrentUser();

    if (googleUser != null) {
      setState(() {
        _nameController.text = googleUser['displayName'] ?? 'Google User';
        _emailController.text = googleUser['email'] ?? '';
        _profileImageUrl = googleUser['photoURL'];
      });
    } else {
      // Fall back to saved profile image if no Google data
      _loadProfileImage();
    }
  }

  // Load profile image from SharedPreferences
  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString('profileImagePath');
    if (savedPath != null && savedPath.isNotEmpty) {
      setState(() {
        _profileImagePath = savedPath;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // Show dialog to select profile picture source with permission checks
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

  // Simplified image picking function
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

        // Save the profile image path
        _saveProfileImage(pickedFile.path);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Error accessing image. Please check your permissions.')),
      );
    }
  }

  // Save the selected profile image path to SharedPreferences
  void _saveProfileImage(String imagePath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profileImagePath', imagePath);

    setState(() {
      _profileImagePath = imagePath;
    });

    _showImageSelectionSuccess();
  }

  // Show a success message after selecting an image
  void _showImageSelectionSuccess() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile picture updated')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          color: Colors.black,
          child: Column(
            children: [
              // Main content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(color: Colors.white),
                  child: Column(
                    children: [
                      // Logo and back button
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
                            // Back button
                            IconButton(
                              icon: const Icon(Icons.arrow_back),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const SizedBox(width: 12),
                            // Title
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

                      // Profile content - scrollable
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Profile picture section - Always showing edit button
                              Center(
                                child: Column(
                                  children: [
                                    Stack(
                                      children: [
                                        // Profile picture - display image based on its source
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

                                        // Edit icon on profile picture - Always visible
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

                              // User details section - Edit icon moved to far right
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
                                  // Edit icon moved to far right
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isEditing = !_isEditing;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFD9D9D9),
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

                              // Name field
                              _buildTextField(
                                label: 'Name',
                                controller: _nameController,
                                icon: Icons.person,
                                enabled: _isEditing,
                              ),
                              const SizedBox(height: 16),

                              // Email field - Always disabled (non-editable)
                              _buildTextField(
                                label: 'Email (Non-editable)',
                                controller: _emailController,
                                icon: Icons.email,
                                keyboardType: TextInputType.emailAddress,
                                enabled: false, // Email is always non-editable
                              ),
                              const SizedBox(height: 24),

                              // Account actions
                              const Text(
                                'Account',
                                style: TextStyle(
                                  fontFamily: 'Lexend',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Change password button
                              _buildActionButton(
                                title: 'Change Password',
                                icon: Icons.lock,
                                onTap: () {
                                  // Navigate to the Reset Password screen
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ResetPasswordScreen(),
                                    ),
                                  );
                                },
                              ),

                              // Logout button
                              _buildActionButton(
                                title: 'Log Out',
                                icon: Icons.logout,
                                isDestructive: true,
                                onTap: () async {
                                  // Sign out from Google
                                  await GoogleAuthService.signOut();

                                  // Navigate to sign in screen
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

  // Helper method to build text fields
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

  // Helper method to build setting toggles - This is still needed for potential future settings
  Widget _buildSettingToggle({
    required String title,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontFamily: 'Lexend')),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFFD9D9D9),
        ),
      ),
    );
  }

  // Helper method to build action buttons
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
        onTap: () async {
          if (title == 'Log Out') {
            // Clear remember me credentials on logout
            _clearRememberMeCredentials();

            // Also sign out from Google if user was signed in with Google
            await GoogleAuthService.signOut();
          }
          onTap();
        },
      ),
    );
  }

  // Add method to clear remember me credentials
  void _clearRememberMeCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rememberMe', false);
    await prefs.remove('email');
    await prefs.remove('password');
    await prefs.remove('rememberMeExpiry');

    print("Logout: Remember me credentials cleared"); // Debug output
  }

  // Helper method to build profile image from various sources
  Widget _buildProfileImage() {
    // 1. If we have a Google profile image URL, use that
    if (_profileImageUrl != null) {
      return Image.network(
        _profileImageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Fall back to default image on error
          return Image.asset('assets/images/logo.png', fit: BoxFit.cover);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
      );
    }
    // 2. If we have a local file path (from camera/gallery)
    else if (_profileImagePath != null) {
      // Check if it's a file path (starts with /) or asset path
      if (_profileImagePath!.startsWith('/') ||
          _profileImagePath!.startsWith('file:')) {
        return Image.file(
          File(_profileImagePath!),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fall back to default image on error
            return Image.asset('assets/images/logo.png', fit: BoxFit.cover);
          },
        );
      } else {
        // It's an asset path
        return Image.asset(_profileImagePath!, fit: BoxFit.cover);
      }
    }
    // 3. Default fallback image
    else {
      return Image.asset('assets/images/logo.png', fit: BoxFit.cover);
    }
  }
}
