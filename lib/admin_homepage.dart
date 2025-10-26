import 'package:flutter/material.dart';
import 'auth.dart';
import 'login.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final Auth auth = Auth();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Guru Dashboard"),
        backgroundColor: const Color(0xFF3D5A80),
        foregroundColor: Colors.white,
        actions: [
          // Tombol Logout untuk Admin
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.signOut();
              if (context.mounted) {
                // Kembali ke Login dan hapus semua halaman sebelumnya
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          )
        ],
      ),
      body: const Center(
        child: Text(
          "Selamat Datang, Guru!",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF3D5A80),
          ),
        ),
      ),
    );
  }
}