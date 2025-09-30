// lib/main.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'frontpage.dart'; // pastikan path sesuai

Future<void> main() async {
  // Baris ini memastikan semua plugin siap sebelum kode lain dijalankan
  WidgetsFlutterBinding.ensureInitialized();
  
  // Baris ini menginisialisasi Firebase menggunakan file firebase_options.dart
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EduSign App', // diganti agar lebih deskriptif
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const FrontPage(),
    );
  }
}