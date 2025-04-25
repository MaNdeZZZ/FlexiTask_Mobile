import 'package:flutter/material.dart';
import 'authregister.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/google_auth_service.dart';
import 'dashboard.dart';
import 'local_notification.dart'; // Add this import

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _verifyPasswordController = TextEditingController();

  // Add a variable to store the extracted username
  String _extractedUsername = "";

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _verifyPasswordController.dispose();
    super.dispose();
  }

  // New method to handle registration
  void _register() {
    // Validate form first (basic validation)
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _verifyPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    if (_passwordController.text != _verifyPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    // Validate password strength
    final passwordValidationResult =
        _validatePassword(_passwordController.text);
    if (passwordValidationResult.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(passwordValidationResult)));
      return;
    }

    // Extract username from email address before navigating
    final email = _emailController.text.trim();
    _extractedUsername = _extractUsernameFromEmail(email);

    // Save the username to SharedPreferences for later use
    _saveUsername(_extractedUsername);

    // Navigate to the confirmation screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegistrationConfirmationScreen(
          email: email,
          username:
              _extractedUsername, // Pass the username to confirmation screen
        ),
      ),
    );
  }

  // Helper method to extract username from email
  String _extractUsernameFromEmail(String email) {
    // Split the email at '@' and take the first part
    if (email.contains('@')) {
      return email.split('@')[0];
    }
    return email; // Fallback if email format is invalid
  }

  // Save username to SharedPreferences
  Future<void> _saveUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
  }

  // Method to handle Google Sign-Up
  Future<void> _handleGoogleSignUp() async {
    try {
      final user = await GoogleAuthService.signInWithGoogle();

      if (user != null) {
        // Initialize notifications when entering dashboard
        await LocalNotificationService.initialize();
        await LocalNotificationService.requestPermissions();

        // Navigate to dashboard
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
          (route) => false,
        );
      } else {
        // User cancelled the sign-up process
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google sign-up was cancelled')),
        );
      }
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Google sign-up failed: $e')));
    }
  }

  // Helper method to validate password strength
  String _validatePassword(String password) {
    // Check for at least one uppercase letter
    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));

    // Check for at least one digit
    bool hasDigit = password.contains(RegExp(r'[0-9]'));

    if (!hasUppercase && !hasDigit) {
      return 'Password must contain at least one uppercase letter and one number';
    } else if (!hasUppercase) {
      return 'Password must contain at least one uppercase letter';
    } else if (!hasDigit) {
      return 'Password must contain at least one number';
    }

    return ''; // Empty string means validation passed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sign Up',
          style: TextStyle(fontFamily: 'Lexend', fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              const Text(
                'Get Started',
                style: TextStyle(
                  fontSize: 28,
                  fontFamily: 'Lexend',
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Start making To-Do-List by Sign up!',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Lexend',
                  color: Colors.black54,
                ),
              ),

              // Add spacer to push form to center
              const Spacer(flex: 1),

              // Form fields - centered on screen
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter your email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelStyle: const TextStyle(fontFamily: 'Lexend'),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter your password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelStyle: const TextStyle(fontFamily: 'Lexend'),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _verifyPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  hintText: 'Verify your password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelStyle: const TextStyle(fontFamily: 'Lexend'),
                ),
              ),

              // Add spacer to push buttons toward bottom
              const Spacer(flex: 2),

              // Register button
              ElevatedButton(
                onPressed: _register, // Use the new method
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(
                    0xFFD9D9D9,
                  ), // Changed back to match signin_signup.dart
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  elevation: 5,
                  shadowColor: Colors.black45,
                ),
                child: const Text(
                  'Register',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black,
                    fontFamily: "Lexend",
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _handleGoogleSignUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(
                    0xFFF5F5F5,
                  ), // Slightly darker than white
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  elevation: 3,
                  shadowColor: Colors.black26,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/images/google_logo.png', height: 24),
                    const SizedBox(width: 12),
                    const Text(
                      'Sign up with Google',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        fontFamily: "Lexend",
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Bottom padding
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
