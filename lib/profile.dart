import 'package:flutter/material.dart';
import 'signin_signup.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Add this import
import 'resetpassword.dart'; // Add this import

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

  // Selected profile picture
  String? _profileImagePath;

  @override
  void initState() {
    super.initState();
    // Load profile picture if available
    _loadProfileImage();
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

  // Show dialog to select profile picture source
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
                  // In a real app, you would implement camera functionality
                  Navigator.pop(context);
                  // For demo purposes, use a sample image path
                  _saveProfileImage('assets/images/profile1.png');
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text(
                  'Choose from gallery',
                  style: TextStyle(fontFamily: 'Lexend'),
                ),
                onTap: () {
                  // In a real app, you would implement gallery selection
                  Navigator.pop(context);
                  // For demo purposes, we'll simulate picking from a few sample images
                  _showSampleImagePicker();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Show image picker with sample images for demo purposes
  void _showSampleImagePicker() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text(
              "Select Sample Image",
              style: TextStyle(fontFamily: 'Lexend'),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                children: [
                  _buildSampleImageOption('assets/images/logo.png'),
                  _buildSampleImageOption('assets/images/profile1.png'),
                  _buildSampleImageOption('assets/images/profile2.png'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  // Build sample image selection item
  Widget _buildSampleImageOption(String imagePath) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        _saveProfileImage(imagePath);
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Image.asset(imagePath, fit: BoxFit.cover),
      ),
    );
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
                                        // Profile picture
                                        Container(
                                          width: 120,
                                          height: 120,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.grey[200],
                                            image: DecorationImage(
                                              image: AssetImage(
                                                _profileImagePath ??
                                                    'assets/images/logo.png',
                                              ),
                                              fit: BoxFit.cover,
                                            ),
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
                                      builder:
                                          (context) =>
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
                                onTap: () {
                                  // Navigate to sign in/sign up screen
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
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
        onTap: () {
          if (title == 'Log Out') {
            // Clear remember me credentials on logout
            _clearRememberMeCredentials();
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
}
