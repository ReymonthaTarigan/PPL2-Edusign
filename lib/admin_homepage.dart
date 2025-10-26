import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth.dart';
import 'login.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final Auth auth = Auth();

  // Controller Text Input
  final TextEditingController linkController = TextEditingController();
  final TextEditingController titleController = TextEditingController();

  // Dropdown value
  String? selectedGrade;
  String? selectedSubject;

  final List<String> grades = ["SD", "SMP", "SMA"];
  final List<String> subjects = [
    "Pendidikan Kewarganegaraan",
    "Bahasa Indonesia",
    "Matematika",
    "IPA",
    "IPS",
    "Bahasa Inggris",
    "Informatika",
    "Seni Budaya dan Prakarya",
    "Pendidikan Jasmani, Olahraga dan Kesehatan",
  ];

  void openUploadDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Upload Video Baru"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: "Judul Video"),
                ),
                TextField(
                  controller: linkController,
                  decoration: const InputDecoration(labelText: "YouTube URL"),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedGrade,
                  decoration: const InputDecoration(labelText: "Pilih Jenjang"),
                  items: grades
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) => setState(() => selectedGrade = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedSubject,
                  decoration: const InputDecoration(labelText: "Pilih Mata Pelajaran"),
                  items: subjects
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) => setState(() => selectedSubject = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Batal"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3D5A80)),
              child: const Text("Upload"),
              onPressed: uploadVideo,
            ),
          ],
        );
      },
    );
  }

  Future<void> uploadVideo() async {
    if (titleController.text.isEmpty ||
        linkController.text.isEmpty ||
        selectedGrade == null ||
        selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠ Harap lengkapi semua data!")),
      );
      return;
    }

    await FirebaseFirestore.instance.collection("videos").add({
      "title": titleController.text,
      "link": linkController.text,
      "educationLevel": selectedGrade,
      "subject": selectedSubject,
      "Status": true,
      "timestamp": DateTime.now(),
    });

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Video berhasil diupload!")),
    );

    // bersihkan input
    titleController.clear();
    linkController.clear();
    selectedGrade = null;
    selectedSubject = null;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Guru Dashboard"),
        backgroundColor: const Color(0xFF3D5A80),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.signOut();
              if (context.mounted) {
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
      body: Center(
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3D5A80),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
          icon: const Icon(Icons.upload, size: 26),
          label: const Text("Upload Video Baru", style: TextStyle(fontSize: 18)),
          onPressed: openUploadDialog,
        ),
      ),
    );
  }
}
