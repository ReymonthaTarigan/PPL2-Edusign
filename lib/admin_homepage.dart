import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth.dart';
import 'login.dart';
import 'package:http/http.dart' as http;

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final Auth auth = Auth();

  // Controller untuk input
  final TextEditingController linkController = TextEditingController();
  final TextEditingController titleController = TextEditingController();

  // Dropdown
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

  // 🔹 Dialog Upload
  void openUploadDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
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
                  onChanged: (value) {
                    setState(() => selectedGrade = value);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedSubject,
                  decoration:
                      const InputDecoration(labelText: "Pilih Mata Pelajaran"),
                  items: subjects
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) {
                    setState(() => selectedSubject = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3D5A80),
              ),
              onPressed: () {
                uploadVideo(dialogContext); // kirim dialogContext
              },
              child: const Text("Upload"),
            ),
          ],
        );
      },
    );
  }

  // 🔹 Fungsi Upload dan Panggil Endpoint Flask
  Future<void> uploadVideo(BuildContext dialogContext) async {
    print("📍 MULAI uploadVideo() dipanggil");

    if (titleController.text.isEmpty ||
        linkController.text.isEmpty ||
        selectedGrade == null ||
        selectedSubject == null) {
      print("⚠ Form belum lengkap");
      return;
    }

    try {
      print("📍 Tambah video ke Firestore...");
      final docRef = await FirebaseFirestore.instance.collection("videos").add({
        "title": titleController.text.trim(),
        "link": linkController.text.trim(),
        "educationLevel": selectedGrade,
        "subject": selectedSubject,
        "status": false,
        "timestamp": FieldValue.serverTimestamp(),
      });

      final videoId = docRef.id;
      print("✅ Firestore OK, ID: $videoId");

      const String ngrokBaseUrl =
          "https://roni-uncharacterised-patchily.ngrok-free.dev";
      final String apiUrl = "$ngrokBaseUrl/process/$videoId";
      print("🌐 Akan memanggil Flask di: $apiUrl");

      final response = await http
          .get(Uri.parse(apiUrl))
          .timeout(const Duration(seconds: 30));

      print("📥 Respon diterima: ${response.statusCode}");
      print("🧾 Isi respon: ${response.body}");
    } catch (e) {
      print("❌ ERROR: $e");
    }
  }


  // 🔹 UI Utama
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
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
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
          label:
              const Text("Upload Video Baru", style: TextStyle(fontSize: 18)),
          onPressed: openUploadDialog,
        ),
      ),
    );
  }
}
