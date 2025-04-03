import 'package:flutter/material.dart';
import 'signin_signup.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Controllers for text fields
  final TextEditingController _nameController =
      TextEditingController(text: "John Doe");
  final TextEditingController _emailController =
      TextEditingController(text: "john.doe@example.com");

  // Settings toggles - removed dark mode, kept notifications
  bool _notifications = true;

  // Selected profile picture
  String? _profileImagePath;

  // Edit mode state
  bool _isEditing = false;

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
                  _showImageSelectionSuccess();
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
                  _showImageSelectionSuccess();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Show a success message after selecting an image
  void _showImageSelectionSuccess() {
    setState(() {
      // In a real app, this would be the actual image path
      _profileImagePath = 'assets/images/logo.png';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile picture updated')),
    );
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
                  decoration: const BoxDecoration(
                    color: Colors.white,
                  ),
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
                            // Edit/Save button
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  if (_isEditing) {
                                    // Save changes here in a real app
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Profile updated')),
                                    );
                                  }
                                  _isEditing = !_isEditing;
                                });
                              },
                              child: Text(
                                _isEditing ? 'Save' : 'Edit',
                                style: const TextStyle(
                                  fontFamily: 'Lexend',
                                  color: Colors.blue,
                                ),
                              ),
                            ),
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
                              // Profile picture section - Enhanced with selection
                              Center(
                                child: Column(
                                  children: [
                                    InkWell(
                                      onTap: _isEditing
                                          ? _showImageSourceOptions
                                          : null,
                                      child: Stack(
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

                                          // Edit icon on profile picture
                                          if (_isEditing)
                                            Positioned(
                                              right: 0,
                                              bottom: 0,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFFD9D9D9),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                      color: Colors.white,
                                                      width: 2),
                                                ),
                                                child: const Icon(
                                                  Icons.camera_alt,
                                                  size: 20,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (_isEditing)
                                      const Padding(
                                        padding: EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          'Tap to change profile picture',
                                          style: TextStyle(
                                            fontFamily: 'Lexend',
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              ),

                              // User details section
                              const Text(
                                'Personal Information',
                                style: TextStyle(
                                  fontFamily: 'Lexend',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
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

                              // Settings section
                              const Text(
                                'Settings',
                                style: TextStyle(
                                  fontFamily: 'Lexend',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Notifications switch (only toggle, dark mode removed)
                              _buildSettingToggle(
                                title: 'Notifications',
                                icon: Icons.notifications,
                                value: _notifications,
                                onChanged: (value) {
                                  setState(() {
                                    _notifications = value;
                                  });
                                },
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
                                  // Add change password functionality
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Change password functionality')),
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
                                        builder: (context) =>
                                            const SignInSignUpScreen()),
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
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          labelStyle: const TextStyle(fontFamily: 'Lexend'),
        ),
        style: const TextStyle(fontFamily: 'Lexend'),
      ),
    );
  }

  // Helper method to build setting toggles
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
        title: Text(
          title,
          style: const TextStyle(fontFamily: 'Lexend'),
        ),
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
        leading: Icon(
          icon,
          color: isDestructive ? Colors.red : null,
        ),
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
}
