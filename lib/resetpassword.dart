import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  Future<void> _loadUserEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      setState(() {
        _emailController.text = user.email!;
      });
      debugPrint('Loaded user email: ${user.email}');
    } else {
      debugPrint('No user email found');
    }
  }

  Future<void> _sendPasswordResetEmail() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });
    debugPrint('Sending password reset email to: ${_emailController.text}');

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent. Check your inbox.'),
        ),
      );
      debugPrint('Password reset email sent successfully');
      Navigator.pop(context);
    } catch (e, stackTrace) {
      debugPrint('Error sending password reset email: $e');
      debugPrint('Stack trace: $stackTrace');
      String errorMessage;
      if (e.toString().contains('user-not-found')) {
        errorMessage = 'No user found with this email';
      } else if (e.toString().contains('invalid-email')) {
        errorMessage = 'Invalid email address';
      } else {
        errorMessage = 'Error: ${e.toString()}';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Change Password',
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
          child:
              _isLoading ? _buildLoadingIndicator() : _buildResetPasswordForm(),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Processing your request...',
            style: TextStyle(fontFamily: 'Lexend'),
          ),
        ],
      ),
    );
  }

  Widget _buildResetPasswordForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reset Your Password',
          style: TextStyle(
            fontSize: 24,
            fontFamily: 'Lexend',
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter your email address to receive a password reset link.',
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Lexend',
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email Address',
            hintText: 'Enter your email address',
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            labelStyle: const TextStyle(fontFamily: 'Lexend'),
          ),
        ),
        const Spacer(),
        ElevatedButton(
          onPressed: _sendPasswordResetEmail,
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
              fontFamily: 'Lexend',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
