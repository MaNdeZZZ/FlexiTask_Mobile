import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class GoogleAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Sign in with Google
  static Future<UserCredential?> signInWithGoogle({
    bool rememberMe = false,
  }) async {
    try {
      // Begin interactive sign-in process
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // If user cancelled the sign-in flow, return null
      if (googleUser == null) return null;

      // Obtain auth details from request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create new credential for Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      // Store user info in SharedPreferences if Remember Me is enabled
      if (rememberMe) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('rememberMe', true);

        // Add expiration timestamp (30 days from now)
        final expiryTime =
            DateTime.now().add(const Duration(days: 30)).millisecondsSinceEpoch;
        await prefs.setInt('rememberMeExpiry', expiryTime);

        debugPrint(
          "Google sign-in: Remember Me enabled with expiry: $expiryTime",
        );
      }

      return userCredential;
    } catch (e) {
      debugPrint("Error signing in with Google: $e");
      rethrow;
    }
  }

  // Get current user's basic information
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      // Check if user is signed in with Google
      final GoogleSignInAccount? googleUser =
          await _googleSignIn.signInSilently();

      if (googleUser != null) {
        return {
          'displayName': googleUser.displayName,
          'email': googleUser.email,
          'photoURL': googleUser.photoUrl,
        };
      }

      // Check Firebase user if Google sign-in doesn't work
      final User? user = _auth.currentUser;
      if (user != null) {
        return {
          'displayName': user.displayName,
          'email': user.email,
          'photoURL': user.photoURL,
        };
      }

      return null;
    } catch (e) {
      debugPrint("Error getting current user: $e");
      return null;
    }
  }

  // Sign out from Google and Firebase
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      debugPrint("Signed out from Google successfully");
    } catch (e) {
      debugPrint("Error signing out from Google: $e");
    }
  }
}
