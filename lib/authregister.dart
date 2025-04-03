import 'package:flutter/material.dart';
import 'signin_signup.dart'; // Import the SignInSignUpScreen

class RegistrationConfirmationScreen extends StatelessWidget {
  final String email;

  const RegistrationConfirmationScreen({Key? key, required this.email})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Auth',
          style: TextStyle(
            fontFamily: 'Lexend',
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Main content centered
            Center(
              child: Container(
                width: 350, // Increased width
                padding: const EdgeInsets.all(32.0), // Increased padding
                decoration: BoxDecoration(
                  color: const Color(0xFFD9D9D9),
                  borderRadius:
                      BorderRadius.circular(16), // Slightly larger radius
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 12,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Verify Your\nEmail!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28, // Increased font size
                        fontFamily: 'Lexend',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24), // Increased spacing
                    Text(
                      'We have sent you an email with a link to $email for verification.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18, // Increased font size
                        fontFamily: 'Lexend',
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Back button positioned at the bottom of the screen
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignInSignUpScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black.withOpacity(0.6),
                  ),
                  child: const Text(
                    'Back to Sign In/Sign Up',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Lexend',
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
