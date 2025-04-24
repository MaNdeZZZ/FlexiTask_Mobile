import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  int _currentStep = 0;
  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Handle password reset request
  void _resetPassword() {
    // Basic validation
    if (_emailController.text.isEmpty) {
      _showErrorSnackBar('Please enter your email address');
      return;
    }

    if (_newPasswordController.text.isEmpty) {
      _showErrorSnackBar('Please enter a new password');
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showErrorSnackBar('Passwords do not match');
      return;
    }

    // Show loading indicator
    setState(() {
      _isLoading = true;
    });

    // Simulate API call with delay
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      // Save the new password (in a real app, this would happen after email verification)
      _saveNewPassword();

      // Show verification sent screen
      setState(() {
        _isLoading = false;
        _currentStep = 1;
      });
    });
  }

  // Save the new password to SharedPreferences (demo only)
  void _saveNewPassword() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('password', _newPasswordController.text);
  }

  // Show error message
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
          child: _isLoading ? _buildLoadingIndicator() : _buildCurrentStep(),
        ),
      ),
    );
  }

  // Loading indicator
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

  // Build the current step in the password reset flow
  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildResetPasswordForm();
      case 1:
        return _buildVerificationSentScreen();
      default:
        return _buildResetPasswordForm();
    }
  }

  // Build the reset password form UI
  Widget _buildResetPasswordForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Change Your Password',
          style: TextStyle(
            fontSize: 24,
            fontFamily: 'Lexend',
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter your email and new password. A verification link will be sent to your email.',
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Lexend',
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 24),

        // Email field
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
        const SizedBox(height: 16),

        // New password field
        TextField(
          controller: _newPasswordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'New Password',
            hintText: 'Enter your new password',
            prefixIcon: const Icon(Icons.lock_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            labelStyle: const TextStyle(fontFamily: 'Lexend'),
          ),
        ),
        const SizedBox(height: 16),

        // Confirm password field
        TextField(
          controller: _confirmPasswordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Confirm New Password',
            hintText: 'Confirm your new password',
            prefixIcon: const Icon(Icons.lock_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            labelStyle: const TextStyle(fontFamily: 'Lexend'),
          ),
        ),

        const Spacer(),

        // Submit button
        ElevatedButton(
          onPressed: _resetPassword,
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
            'Send Verification Link',
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

  // Build the verification sent screen UI
  Widget _buildVerificationSentScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.mark_email_read, size: 80, color: Colors.green),
        const SizedBox(height: 24),
        const Text(
          'Verification Email Sent!',
          style: TextStyle(
            fontSize: 24,
            fontFamily: 'Lexend',
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'We\'ve sent a verification link to ${_emailController.text}. Please check your inbox and follow the link to complete the password change.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontFamily: 'Lexend',
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Once verified, you can use your new password to sign in.',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Lexend', fontWeight: FontWeight.w500),
        ),
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
            'Back to Profile',
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
