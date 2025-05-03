import 'package:flutter/material.dart';
import 'login.dart';
import 'register.dart';

class SignInSignUpScreen extends StatelessWidget {
  const SignInSignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Change to solid white background
        color: Colors.white,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 1),

                // Enhanced logo section with shadow
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/logo.png',
                          height: 240.0,
                          width: 240.0,
                        ),
                      ),
                      const SizedBox(height: 24.0),
                      // Removed app name text

                      // App tagline
                      const Text(
                        'Organize your tasks with ease',
                        style: TextStyle(
                          fontSize: 18,
                          fontFamily: 'Lexend',
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // Enhanced buttons section
                Column(
                  children: [
                    // Sign In Button with improved design
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD9D9D9),
                        minimumSize: const Size.fromHeight(55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        elevation: 5,
                        shadowColor: Colors.black45,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.login, color: Colors.black87),
                            SizedBox(width: 12),
                            Text(
                              'Sign In',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.black87,
                                fontFamily: "Lexend",
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),

                    // Sign Up Button with matching style to Sign In
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD9D9D9),
                        minimumSize: const Size.fromHeight(55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        elevation: 5,
                        shadowColor: Colors.black45,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_add, color: Colors.black87),
                            SizedBox(width: 12),
                            Text(
                              'Sign Up',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.black87,
                                fontFamily: "Lexend",
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const Spacer(flex: 1),

                // Footer text
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
}
