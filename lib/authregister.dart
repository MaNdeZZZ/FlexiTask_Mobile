import 'package:flutter/material.dart';
import 'signin_signup.dart';

class AuthRegisterUtils {
  static Widget buildEmailSentStep(
      BuildContext context, String email, String username) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.mark_email_read, size: 80, color: Colors.green),
        const SizedBox(height: 24),
        Text(
          'Welcome, $username!',
          style: const TextStyle(
            fontSize: 24,
            fontFamily: 'Lexend',
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'We\'ve sent a verification link to $email. Please check your inbox and follow the link to verify your account.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontFamily: 'Lexend',
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 32),
        const Spacer(),
        ElevatedButton(
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const SignInSignUpScreen(),
              ),
              (route) => false,
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(
              0xFFD9D9D9,
            ), // Changed to match signin_signup.dart
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            elevation: 5,
            shadowColor: Colors.black45,
          ),
          child: const Text(
            'Back to Sign In',
            style: TextStyle(
              fontSize: 18,
              color: Colors.black,
              fontFamily: "Lexend",
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class RegistrationConfirmationScreen extends StatefulWidget {
  final String email;
  final String username; // Add username parameter

  const RegistrationConfirmationScreen({
    Key? key,
    required this.email,
    required this.username, // Add required username
  }) : super(key: key);

  @override
  State<RegistrationConfirmationScreen> createState() =>
      _RegistrationConfirmationScreenState();
}

class _RegistrationConfirmationScreenState
    extends State<RegistrationConfirmationScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Simulate verification process with loading
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Registration',
          style: TextStyle(fontFamily: 'Lexend', fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _isLoading
              ? _buildLoadingIndicator()
              // Pass the username to the email sent step
              : AuthRegisterUtils.buildEmailSentStep(
                  context, widget.email, widget.username),
        ),
      ),
    );
  }

  // Loading indicator widget
  Widget _buildLoadingIndicator() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 24),
          Text(
            'Verifying your account...',
            style: TextStyle(fontFamily: 'Lexend', fontSize: 16),
          ),
        ],
      ),
    );
  }
}
