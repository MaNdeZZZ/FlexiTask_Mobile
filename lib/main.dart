import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    print("✅ Firebase berhasil diinisialisasi!");
  } catch (e) {
    print("❌ Firebase gagal diinisialisasi: $e");
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlexiTask',
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Lexend'),
      home: const LoadingPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
