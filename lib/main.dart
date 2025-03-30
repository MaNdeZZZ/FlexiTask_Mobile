import 'package:firebase_core/firebase_core.dart';
import 'package:flexitask_mobile/loading_page.dart';
import 'package:flutter/material.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized(); // Pastikan binding diinisialisasi sebelum Firebase
//   await Firebase.initializeApp(); // Inisialisasi Firebase
//   runApp(MyApp());
// }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    print("✅ Firebase berhasil diinisialisasi!");
  } catch (e) {
    print("❌ Firebase gagal diinisialisasi: $e");
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoadingPage(),
    );
  }
}
