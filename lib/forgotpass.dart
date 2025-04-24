import 'package:flutter/material.dart';
import 'authforgot.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _currentStep = 0;
  final _emailController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _requestVerificationLink() {
    // Here you would implement the actual logic to send a password reset link
    setState(() {
      _isProcessing = true;
    });

    // Simulate network delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _currentStep = 1;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Forgot Password',
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
          child: _buildCurrentStep(),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    if (_isProcessing) {
      return AuthUtils.buildLoadingStep();
    }

    switch (_currentStep) {
      case 0:
        return AuthUtils.buildEmailVerificationStep(
          _emailController,
          _requestVerificationLink,
        );
      case 1:
        return AuthUtils.buildEmailSentStep(context);
      default:
        return AuthUtils.buildEmailVerificationStep(
          _emailController,
          _requestVerificationLink,
        );
    }
  }
}
