import 'package:flutter/material.dart';
import './forgotpass.dart';
import 'dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/google_auth_service.dart';
import 'local_notification.dart'; // Add this import
import 'transitions.dart'; // Add this import

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _rememberMe = false;
  bool _isLoading = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Check if user is remembered
    _checkRememberedUser();
  }

  // Check if user credentials are stored
  void _checkRememberedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('rememberMe') ?? false;

    if (rememberMe) {
      final email = prefs.getString('email') ?? '';
      final password = prefs.getString('password') ?? '';

      if (email.isNotEmpty && password.isNotEmpty) {
        // Pre-fill the form fields with saved credentials
        setState(() {
          _emailController.text = email;
          _passwordController.text = password;
          _rememberMe = true;
        });

        // Auto navigate to dashboard if user is remembered
        // Add a small delay to allow the screen to build
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            // Use pushReplacement instead of push to prevent going back to login
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
            );
          }
        });
      }
    }
  }

  // Save user credentials if "Remember Me" is checked
  void _saveUserCredentials() async {
    if (_rememberMe) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('rememberMe', true);
      await prefs.setString('email', _emailController.text);
      await prefs.setString('password', _passwordController.text);

      // Add expiration timestamp (30 days from now)
      final expiryTime =
          DateTime.now().add(const Duration(days: 30)).millisecondsSinceEpoch;
      await prefs.setInt('rememberMeExpiry', expiryTime);

      print("Credentials saved. Expiry time: $expiryTime"); // Debug output
    } else {
      // Clear any previously saved credentials if Remember Me is not checked
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('rememberMe', false);
      await prefs.remove('email');
      await prefs.remove('password');
      await prefs.remove('rememberMeExpiry');

      print("Remember me not checked, credentials cleared"); // Debug output
    }
  }

  // Handle login with smooth transition
  void _handleLogin() {
    // Validate inputs
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    // Save user credentials if "Remember Me" is checked
    _saveUserCredentials();

    // Initialize notifications when entering dashboard
    LocalNotificationService.initialize();
    LocalNotificationService.requestPermissions();

    // Navigate to dashboard with smooth transition
    AppTransitions.pushAndRemoveUntil(
      context,
      const DashboardScreen(),
    );
  }

  // Method to handle Google Sign-In
  Future<void> _handleGoogleSignIn() async {
    try {
      // Show loading indicator
      setState(() {
        _isLoading = true;
      });

      final userCredential = await GoogleAuthService.signInWithGoogle(
        rememberMe: _rememberMe,
      );

      setState(() {
        _isLoading = false;
      });

      if (userCredential?.user != null) {
        // Get user info for display
        final user = userCredential!.user!;
        final displayName = user.displayName ?? 'Google User';

        // Show success message
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Welcome, $displayName!')));

        // Navigate to dashboard with smooth transition
        AppTransitions.pushAndRemoveUntil(
          context,
          const DashboardScreen(),
        );
      } else {
        // User cancelled the sign-in process or error occurred
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google sign-in was cancelled')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      // Show error message
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Google sign-in failed: $e')));
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sign In',
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header section
                    const Text(
                      'Welcome Back',
                      style: TextStyle(
                        fontSize: 28,
                        fontFamily: 'Lexend',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Hey! Good to see you back',
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

                    // Remember me checkbox and Forgot password link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (value) {
                                setState(() {
                                  _rememberMe = value ?? false;
                                });
                              },
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const Text(
                              'Remember me',
                              style: TextStyle(
                                fontFamily: 'Lexend',
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ForgotPasswordScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              fontFamily: 'Lexend',
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Add spacer to push buttons toward bottom
                    const Spacer(flex: 2),

                    // Login button
                    ElevatedButton(
                      onPressed: _handleLogin,
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
                        'Login',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.black,
                          fontFamily: "Lexend",
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Sign in with Google button - Changed to ElevatedButton with off-white color
                    ElevatedButton(
                      onPressed: _handleGoogleSignIn,
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
                          Image.asset(
                            'assets/images/google_logo.png',
                            height: 24,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Sign in with Google',
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
