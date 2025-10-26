import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'frontpage.dart';
import 'firebase_options.dart';
import 'setup_quiz_page.dart'; // Tambahkan ini di atas
import 'quiz_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      title: 'EduSign App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SetupQuizPage(), //SetupQuizPage(masukin soal) & QuizPage(nyoba jawab)
    );
  }
}