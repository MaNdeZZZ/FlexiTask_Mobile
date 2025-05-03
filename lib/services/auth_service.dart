import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Check if remember me credentials exist and are still valid
  static Future<bool> hasValidRememberMeCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('rememberMe') ?? false;

    if (!rememberMe) {
      return false;
    }

    // Check expiration
    final expiryTime = prefs.getInt('rememberMeExpiry');
    if (expiryTime == null) {
      return false;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    if (now > expiryTime) {
      // Clear expired credentials
      await prefs.setBool('rememberMe', false);
      await prefs.remove('email');
      await prefs.remove('password');
      await prefs.remove('rememberMeExpiry');
      return false;
    }

    // Make sure we have the required credentials
    final email = prefs.getString('email');
    final password = prefs.getString('password');
    return email != null &&
        email.isNotEmpty &&
        password != null &&
        password.isNotEmpty;
  }

  // Get saved email
  static Future<String?> getSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('email');
  }

  // Get saved password
  static Future<String?> getSavedPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('password');
  }
}
