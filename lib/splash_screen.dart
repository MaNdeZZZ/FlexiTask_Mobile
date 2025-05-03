import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'signin_signup.dart';
import 'dashboard.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  @override
  void initState() {
    super.initState();
    // First check for remember me credentials
    _checkAuthStatus();
  }

  // Check if user has valid remember me credentials
  Future<void> _checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('rememberMe') ?? false;

    // Wait for at least 3 seconds to show splash screen
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    if (rememberMe) {
      // Check if credentials are still valid (not expired)
      final expiryTime = prefs.getInt('rememberMeExpiry') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      print(
        "Checking remember me: $rememberMe, expiry: $expiryTime, now: $now",
      );

      if (now < expiryTime) {
        // Valid unexpired session exists, go directly to dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
        return;
      }

      // Clear expired credentials
      await prefs.setBool('rememberMe', false);
      await prefs.remove('email');
      await prefs.remove('password');
      await prefs.remove('rememberMeExpiry');

      print("Expired credentials cleared");
    }

    // No valid credentials, go to sign in page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SignInSignUpScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFffffff), // Set background color
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo_tagline.png', // Ensure this image exists in assets
              width: 500,
              height: 500,
            ),
            const SizedBox(height: 20),
            // Uncomment if you want to show a loading indicator
            // const CircularProgressIndicator(
            //   color: Colors.white,
            // ),
          ],
        ),
      ),
    );
  }
}
