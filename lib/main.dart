import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'splash_screen.dart';
import 'theme_constants.dart';
import 'local_notification.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure system UI overlay style to ensure status bar is visible
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  // Ensure status bar is visible
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
    overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
  );

  try {
    await Firebase.initializeApp();
    print("✅ Firebase berhasil diinisialisasi!");
  } catch (e) {
    print("❌ Firebase gagal diinisialisasi: $e");
  }

  // Initialize notifications early
  await LocalNotificationService.initialize();

  // Pre-check notification permissions to avoid black screen
  final prefs = await SharedPreferences.getInstance();
  final permissionRequested =
      prefs.getBool('notification_permission_requested') ?? false;

  runApp(MyApp(permissionRequested: permissionRequested));
}

class MyApp extends StatelessWidget {
  final bool permissionRequested;

  const MyApp({super.key, this.permissionRequested = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlexiTask',
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Lexend',
        colorScheme: ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          background: AppColors.background,
          surface: AppColors.background,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: AppColors.primaryText),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.primaryText),
          titleTextStyle: TextStyle(
            color: AppColors.primaryText,
            fontFamily: 'Lexend',
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: AppButtonStyles.primaryButton,
        ),
      ),
      home: permissionRequested
          ? const LoadingPage()
          : const NotificationPermissionScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// New dedicated screen for notification permissions
class NotificationPermissionScreen extends StatefulWidget {
  const NotificationPermissionScreen({Key? key}) : super(key: key);

  @override
  State<NotificationPermissionScreen> createState() =>
      _NotificationPermissionScreenState();
}

class _NotificationPermissionScreenState
    extends State<NotificationPermissionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 60),
              // App logo at top
              Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 100,
                  width: 100,
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'FlexiTask',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Lexend',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Organize your tasks with ease',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Lexend',
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 60),
              const Icon(
                Icons.notifications_active,
                size: 70,
                color: Color(0xFF34A853),
              ),
              const SizedBox(height: 24),
              const Text(
                'Aktifkan Notifikasi',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Lexend',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'FlexiTask memerlukan izin untuk mengirim notifikasi agar Anda tidak melewatkan tugas-tugas penting Anda.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Lexend',
                  height: 1.4,
                ),
              ),
              const Spacer(),
              // Buttons at bottom
              Row(
                children: [
                  // Not Now button
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _handlePermissionResponse(false),
                      child: const Text(
                        'Nanti',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Lexend',
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Enable button
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF34A853),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _handlePermissionResponse(true),
                      child: const Text(
                        'Aktifkan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Lexend',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handlePermissionResponse(bool granted) async {
    // Save permission requested status regardless of choice
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notification_permission_requested', true);

    // Request permissions if granted
    if (granted) {
      await LocalNotificationService.requestPermissions();
    }

    // Navigate to loading page
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoadingPage()),
    );
  }
}
