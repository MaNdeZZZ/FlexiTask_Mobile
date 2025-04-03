import 'package:flutter/material.dart';
import 'login.dart';
import 'register.dart';

class SignInSignUpScreen extends StatelessWidget {
  const SignInSignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),

                // Logo Section
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/logo.png',
                          height: 200.0,
                          width: 200.0,
                        ),
                      ),
                      const SizedBox(height: 20.0),
                      const Text(
                        'Organize your tasks with ease',
                        style: TextStyle(
                          fontSize: 18,
                          fontFamily: 'Lexend',
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Buttons Section
                Column(
                  children: [
                    _buildButton(
                      context,
                      icon: Icons.login,
                      label: 'Sign In',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    _buildButton(
                      context,
                      icon: Icons.person_add,
                      label: 'Sign Up',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => RegisterScreen()),
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Footer Text
                const Padding(
                  padding: EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    '© 2025 FlexiTask - All rights reserved',
                    style: TextStyle(
                      fontFamily: 'Lexend',
                      fontSize: 12,
                      color: Colors.black45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Reusable Button Widget
  Widget _buildButton(BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFD9D9D9),
        minimumSize: const Size.fromHeight(55),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        elevation: 5,
        shadowColor: Colors.black45,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.black87),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.black87,
                fontFamily: "Lexend",
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}