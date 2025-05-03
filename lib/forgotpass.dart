import 'package:flutter/material.dart';
import '../services/authforgot.dart';
import '../signin_signup.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _currentStep = 0;
  final _emailController = TextEditingController();
  bool _isProcessing = false;
  bool _canResend = true;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  void _requestVerificationLink() async {
    if (_isProcessing || !_canResend) return;
    setState(() {
      _isProcessing = true;
      _canResend = false;
    });

    final email = _emailController.text.trim();
    final emailValidationResult = _validateEmail(email);
    if (emailValidationResult != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(emailValidationResult)),
      );
      setState(() {
        _isProcessing = false;
        _canResend = true;
      });
      return;
    }

    try {
      await AuthUtils.sendPasswordResetEmail(email);
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _currentStep = 1;
        });
        // Re-enable resend after 30 seconds
        Future.delayed(const Duration(seconds: 30), () {
          if (mounted) {
            setState(() => _canResend = true);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send reset email: $e')),
        );
        setState(() {
          _isProcessing = false;
          _canResend = true;
        });
      }
    }
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
          onPressed: () {
            if (_emailController.text.isNotEmpty && _currentStep == 0) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Discard Changes?'),
                  content: const Text(
                      'Are you sure you want to discard your changes?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      child: const Text('Discard'),
                    ),
                  ],
                ),
              );
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.06),
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
        return AuthUtils.buildEmailSentStep(
          context,
          _emailController.text.trim(),
          _canResend ? _requestVerificationLink : () {},
        );
      default:
        return AuthUtils.buildEmailVerificationStep(
          _emailController,
          _requestVerificationLink,
        );
    }
  }
}
