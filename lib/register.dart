import 'package:flutter/material.dart';
import 'authregister.dart'; // Import the new file

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _rememberMe = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _verifyPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _verifyPasswordController.dispose();
    super.dispose();
  }

  // New method to handle registration
  void _register() {
    // Here you would implement actual registration logic
    // For now, we'll just navigate to the confirmation screen

    // Validate form first (basic validation)
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _verifyPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    if (_passwordController.text != _verifyPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    // Navigate to the confirmation screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegistrationConfirmationScreen(
          email: _emailController.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sign Up',
          style: TextStyle(
            fontFamily: 'Lexend',
            fontWeight: FontWeight.w700,
          ),
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

              // Remember me checkbox
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

              // Add spacer to push buttons toward bottom
              const Spacer(flex: 2),

              // Register button
              ElevatedButton(
                onPressed: _register, // Use the new method
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD9D9D9),
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
              OutlinedButton(
                onPressed: () {
                  // Google sign up logic here
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  side: const BorderSide(color: Colors.black26),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
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
                      'Sign up with Google',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
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
