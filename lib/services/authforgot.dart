import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../signin_signup.dart';

class AuthUtils {
  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } catch (e) {
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'invalid-email':
            throw 'The email address is invalid.';
          case 'user-not-found':
            throw 'No user found with this email address.';
          default:
            throw 'Failed to send reset email: ${e.message}';
        }
      }
      throw 'An error occurred: $e';
    }
  }

  static Widget buildEmailVerificationStep(
      TextEditingController emailController, VoidCallback onSendLink) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reset Password',
          style: TextStyle(
            fontSize: 28,
            fontFamily: 'Lexend',
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter your email address to receive a verification link',
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Lexend',
            color: Colors.black54,
          ),
        ),
        const Spacer(flex: 1),
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email',
            hintText: 'Enter your email address',
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            labelStyle: const TextStyle(fontFamily: 'Lexend'),
          ),
        ),
        const Spacer(flex: 2),
        ElevatedButton(
          onPressed: onSendLink,
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
            'Send Reset Link',
            style: TextStyle(
              fontSize: 18,
              color: Colors.black,
              fontFamily: "Lexend",
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  static Widget buildEmailSentStep(
      BuildContext context, String email, VoidCallback onResendLink) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.mark_email_read, size: 80, color: Colors.green),
        const SizedBox(height: 24),
        const Text(
          'Reset Link Sent!',
          style: TextStyle(
            fontSize: 24,
            fontFamily: 'Lexend',
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'We\'ve sent a password reset link to $email. Please check your inbox and follow the link to reset your password.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontFamily: 'Lexend',
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: onResendLink,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                onResendLink == () {} ? Colors.grey : const Color(0xFFF5F5F5),
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            elevation: 3,
            shadowColor: Colors.black26,
          ),
          child: const Text(
            'Resend Email',
            style: TextStyle(
              fontSize: 18,
              color: Colors.black,
              fontFamily: 'Lexend',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (context) => const SignInSignUpScreen()),
              (route) => false,
            );
          },
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
            'Back to Login',
            style: TextStyle(
              fontSize: 18,
              color: Colors.black,
              fontFamily: 'Lexend',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }

  static Widget buildLoadingStep() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 24),
          Text(
            'Sending verification email...',
            style: TextStyle(fontFamily: 'Lexend', fontSize: 16),
          ),
        ],
      ),
    );
  }
}
