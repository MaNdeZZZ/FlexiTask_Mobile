import 'package:firebase_auth/firebase_auth.dart';
import 'package:flexitask_updated/register.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './forgotpass.dart';
import './dashboard.dart';
import 'services/google_auth_service.dart';
import 'local_notification.dart';
import 'transitions.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _rememberMe = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkRememberedUser();
  }

  String? _validateEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  Future<void> _checkRememberedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('rememberMe') ?? false;

    if (rememberMe) {
      final email = prefs.getString('email') ?? '';
      final uid = prefs.getString('uid') ?? '';
      final expiryTime = prefs.getInt('rememberMeExpiry') ?? 0;

      if (email.isNotEmpty &&
          uid.isNotEmpty &&
          DateTime.now().millisecondsSinceEpoch < expiryTime) {
        try {
          User? user = FirebaseAuth.instance.currentUser;
          if (user != null && user.uid == uid) {
            setState(() {
              _emailController.text = email;
              _rememberMe = true;
            });
            await LocalNotificationService.initialize();
            await LocalNotificationService.requestPermissions();
            AppTransitions.pushAndRemoveUntil(context, const DashboardScreen());
          } else {
            await prefs.remove('rememberMe');
            await prefs.remove('email');
            await prefs.remove('uid');
            await prefs.remove('rememberMeExpiry');
          }
        } catch (e) {
          print('Error checking remembered user: $e');
        }
      } else {
        await prefs.remove('rememberMe');
        await prefs.remove('email');
        await prefs.remove('uid');
        await prefs.remove('rememberMeExpiry');
      }
    }
  }

  Future<void> _saveUserCredentials(String email, String uid) async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setBool('rememberMe', true);
      await prefs.setString('email', email);
      await prefs.setString('uid', uid);
      final expiryTime =
          DateTime.now().add(const Duration(days: 30)).millisecondsSinceEpoch;
      await prefs.setInt('rememberMeExpiry', expiryTime);
      print("Credentials saved. UID: $uid, Expiry: $expiryTime");
    } else {
      await prefs.setBool('rememberMe', false);
      await prefs.remove('email');
      await prefs.remove('uid');
      await prefs.remove('rememberMeExpiry');
      print("Remember me not checked, credentials cleared");
    }
  }

  void _handleLogin() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      setState(() => _isLoading = false);
      return;
    }

    final emailValidationResult = _validateEmail(email);
    if (emailValidationResult != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(emailValidationResult)),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      final userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        if (!user.emailVerified) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Please verify your email before logging in')),
          );
          setState(() => _isLoading = false);
          return;
        }

        await _saveUserCredentials(email, user.uid);
        await LocalNotificationService.initialize();
        await LocalNotificationService.requestPermissions();
        AppTransitions.pushAndRemoveUntil(context, const DashboardScreen());
      }
    } catch (e) {
      String errorMessage = 'Login failed';
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'invalid-email':
            errorMessage = 'The email address is invalid.';
            break;
          case 'user-not-found':
            errorMessage = 'No user found with this email.';
            break;
          case 'wrong-password':
            errorMessage = 'Incorrect password.';
            break;
          case 'user-disabled':
            errorMessage = 'This account has been disabled.';
            break;
          default:
            errorMessage = 'Login failed: ${e.message}';
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final userCredential = await GoogleAuthService.signInWithGoogle(
        rememberMe: _rememberMe,
      );

      if (userCredential?.user != null) {
        final user = userCredential!.user!;
        final displayName = user.displayName ?? 'Google User';

        if (_rememberMe) {
          await _saveUserCredentials(user.email ?? '', user.uid);
        }

        await LocalNotificationService.initialize();
        await LocalNotificationService.requestPermissions();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Welcome, $displayName!')),
        );

        AppTransitions.pushAndRemoveUntil(context, const DashboardScreen());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google sign-in was cancelled')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google sign-in failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sign In',
          style: TextStyle(fontFamily: 'Lexend', fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_emailController.text.isNotEmpty ||
                _passwordController.text.isNotEmpty) {
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
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.06),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 28,
                      fontFamily: 'Lexend',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Hey! Good to see you back',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Lexend',
                      color: Colors.black54,
                    ),
                  ),
                  const Spacer(flex: 1),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'Enter your email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelStyle: const TextStyle(fontFamily: 'Lexend'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelStyle: const TextStyle(fontFamily: 'Lexend'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (value) {
                              setState(() => _rememberMe = value ?? false);
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const Text(
                            'Remember me',
                            style: TextStyle(
                              fontFamily: 'Lexend',
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            fontFamily: 'Lexend',
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(flex: 2),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
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
                      'Login',
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
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF5F5F5),
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      elevation: 3,
                      shadowColor: Colors.black26,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('assets/images/google_logo.png',
                            height: 24),
                        const SizedBox(width: 12),
                        const Text(
                          'Sign in with Google',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            fontFamily: 'Lexend',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Don\'t have an account? Sign Up',
                        style: TextStyle(
                          fontFamily: 'Lexend',
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
