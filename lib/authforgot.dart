import 'package:flutter/material.dart';

class AuthUtils {
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
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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

  static Widget buildEmailSentStep(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.mark_email_read,
          size: 80,
          color: Colors.green,
        ),
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
        const Text(
          'We\'ve sent a password reset link to your email. Please check your inbox and follow the link to reset your password.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Lexend',
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 32),
        const Spacer(),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
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
              fontFamily: "Lexend",
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
