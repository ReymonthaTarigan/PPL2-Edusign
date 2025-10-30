import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show FieldValue;
import 'package:http/http.dart' as http;

import 'forum.dart';
import 'setting.dart';
import 'getService/getdetail.dart';
import 'setup_quiz_page.dart';
import 'quiz_list_page.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  // ====== upload dialog state ======
  final TextEditingController linkController = TextEditingController();
  final TextEditingController titleController = TextEditingController();

  String? selectedGrade;
  String? selectedSubject;

  final List<String> grades = ["SD", "SMP", "SMA"];
  final List<String> subjects = const [
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

  // === search state ===
  String searchQuery = '';

  @override
  void dispose() {
    linkController.dispose();
    titleController.dispose();
    super.dispose();
  }
  void _onBackPressed() async {
    final popped = await Navigator.maybePop(context);
    if (!popped && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sudah di halaman awal')),
      );
    }
  }


  void openUploadDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
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
                  value: selectedGrade, // boleh null
                  decoration: const InputDecoration(labelText: "Pilih Jenjang"),
                  items: grades
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => selectedGrade = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedSubject, // boleh null
                  decoration: const InputDecoration(labelText: "Pilih Mata Pelajaran"),
                  items: subjects
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => selectedSubject = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Batal"),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3D5A80), foregroundColor: Colors.white),
              onPressed: () => uploadVideo(dialogContext),
              child: const Text("Upload"),
            ),
          ],
        );
      },
    );
  }

  // Firestore OK -> tutup dialog + SnackBar sukses, lalu panggil Flask (error hanya di terminal)
  Future<void> uploadVideo(BuildContext dialogContext) async {
    if (titleController.text.isEmpty ||
        linkController.text.isEmpty ||
        selectedGrade == null ||
        selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lengkapi judul, link, jenjang, dan mapel.")),
      );
      return;
    }

    String? videoId;

    try {
      final docRef = await FirebaseFirestore.instance.collection("videos").add({
        "title": titleController.text.trim(),
        "link": linkController.text.trim(),
        "educationLevel": selectedGrade,
        "subject": selectedSubject,
        "status": false, // menandakan masih diproses
        "timestamp": FieldValue.serverTimestamp(),
      });

      videoId = docRef.id;

      Navigator.of(dialogContext).pop(); // tutup dialog
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "✅ Video berhasil diupload. Sistem sedang memproses bahasa isyarat dan subtitlenya.",
          ),
        ),
      );
    } catch (e) {
      Navigator.of(dialogContext).pop();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Gagal upload: $e")),
      );
      return;
    }

    // Panggil Flask (error hanya di terminal)
    if (videoId != null) {
      try {
        const String ngrokBaseUrl =
            "https://roni-uncharacterised-patchily.ngrok-free.dev";
        final String apiUrl = "$ngrokBaseUrl/process/$videoId";
        final response =
            await http.get(Uri.parse(apiUrl)).timeout(const Duration(seconds: 30));
        // print untuk debugging
        // ignore: avoid_print
        print("Flask status=${response.statusCode}, body=${response.body}");
      } catch (e) {
        // ignore: avoid_print
        print("❌ ERROR Flask/ngrok: $e");
      }
    }
  }

  Future<void> _handleQuizTap(String videoDocId) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('questions')
          .where('videoID', isEqualTo: videoDocId)
          .limit(1)
          .get();

      if (!mounted) return;

      if (snap.docs.isEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SetupQuizPage(videoId: videoDocId),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QuizListPage(videoId: videoDocId),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memeriksa kuis: $e')),
      );
    }
  }

  Future<void> _confirmAndDeleteVideo(String videoDocId, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      useRootNavigator: true,          // <-- penting
      barrierDismissible: false,       // <-- opsional: biar ga ketutup karena tap di luar
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Video"),
        content: Text('Yakin ingin menghapus video:\n"$title"?'),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(ctx, rootNavigator: true).pop(false), // <-- tutup dialog
            child: const Text("Batal"),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete_outline),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () =>
                Navigator.of(ctx, rootNavigator: true).pop(true),  // <-- tutup dialog
            label: const Text("Hapus"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance.collection('videos').doc(videoDocId).delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Video "$title" berhasil dihapus.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Gagal menghapus: $e')),
      );
    }
  }


  // ====== UI ======
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF98C1D9), Color(0xFF3D5A80)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Stack(
                children: [
                  // Konten kiri (judul + search)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Hi, Admin",
                        style: TextStyle(
                          fontSize: 28,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SearchBox(
                        onChanged: (value) => setState(() => searchQuery = value),
                      ),
                    ],
                  ),

                  // Tombol Logout di sudut kanan atas
                  Positioned(
                    top: 0,
                    right: 0,
                    child: TextButton(
                      onPressed: _onBackPressed,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: const Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),


            const SizedBox(height: 12),

            // ====== LIST SEMUA VIDEO ======
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('videos').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final rawDocs = snapshot.data?.docs ?? const <QueryDocumentSnapshot>[];

                  // Map dokumen -> data aman (skip bila null/tipe tak sesuai)
                  final safeDocs = <QueryDocumentSnapshot>[];
                  for (final d in rawDocs) {
                    try {
                      final data = d.data();
                      if (data is Map<String, dynamic>) {
                        // pastikan title minimal string (boleh kosong)
                        final _ = (data['title'] ?? '').toString();
                        safeDocs.add(d);
                      } else {
                        // ignore: avoid_print
                        print('⚠️ Skip doc ${d.id}: data bukan Map<String,dynamic>');
                      }
                    } catch (e) {
                      // ignore: avoid_print
                      print('⚠️ Skip doc ${d.id}: error cast data -> $e');
                    }
                  }

                  // filter berdasarkan judul (case-insensitive)
                  final filteredDocs = safeDocs.where((doc) {
                    final q = searchQuery.trim().toLowerCase();
                    final data = (doc.data() as Map<String, dynamic>);
                    final title = (data['title'] ?? '').toString();
                    return title.toLowerCase().contains(q);
                  }).toList();

                  if (filteredDocs.isEmpty) {
                    return const Center(child: Text("Tidak ada video yang cocok."));
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: filteredDocs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final doc = filteredDocs[i];
                      final data = (doc.data() as Map<String, dynamic>);

                      // Ambil field dengan fallback aman (tidak pernah null)
                      final title = (data['title'] ?? 'Untitled').toString();
                      final link = (data['link'] ?? '').toString();
                      final subject = (data['subject'] ?? '-').toString();
                      final grade = (data['educationLevel'] ?? '-').toString();
                      final signLang = data['signLanguage']; // bisa null
                      final subtitle = data['subtitle']; // bisa null
                      final isProcessing = (data['status'] == false);

                      return _VideoCard(
                        title: title,
                        subject: subject,
                        grade: grade,
                        processing: isProcessing,
                        onTitleTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VideoDetailPage(
                                title: title,
                                videoUrl: link,
                                signLangUrl: signLang,
                                subtitle: subtitle,
                                videoDocId: doc.id,
                              ),
                            ),
                          );
                        },
                        onQuizTap: () => _handleQuizTap(doc.id),
                        onDeleteTap: () => _confirmAndDeleteVideo(doc.id, title),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // BOTTOM NAV
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: Colors.blue[900],
        unselectedItemColor: Colors.black54,
        type: BottomNavigationBarType.fixed, // biar layout stabil dengan 2 item
        onTap: (index) {
          if (index == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ForumPage()));
          } 
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.forum), label: 'Forum'),
        ],
      ),

      // FAB UPLOAD
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openUploadDialog,
        backgroundColor: const Color(0xFF3D5A80),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.upload),
        label: const Text("Upload Video Baru"),
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  final String title;
  final String subject;
  final String grade;
  final bool processing;
  final VoidCallback onTitleTap;
  final VoidCallback onQuizTap;
  final VoidCallback onDeleteTap;

  const _VideoCard({
    required this.title,
    required this.subject,
    required this.grade,
    required this.processing,
    required this.onTitleTap,
    required this.onQuizTap,
    required this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    const cardBg = Color(0xFFF7F4FF);
    const chipBg = Color(0xFFE8F2FF);
    const chipBorder = Color(0xFFBBD9FF);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.slideshow, color: Color(0xFF1E88E5), size: 28),
          const SizedBox(width: 10),
          // judul + chips
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: onTitleTap,
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color.fromARGB(255, 0, 0, 0),
                      fontWeight: FontWeight.w700,
                  
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  children: [
                    _Pill(text: subject, bg: chipBg, border: chipBorder),
                    _Pill(text: grade, bg: chipBg, border: chipBorder),
                    if (processing) const _ProcessingBadge(), // indikator tanpa animasi
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Kelola Kuis',
            icon: const Icon(Icons.quiz, color: Color(0xFF3949AB)),
            onPressed: onQuizTap,
          ),
          IconButton(
            tooltip: 'Hapus Video',
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: onDeleteTap,
          ),
          const Icon(Icons.chevron_right, color: Colors.black45),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color bg;
  final Color border;
  const _Pill({required this.text, required this.bg, required this.border});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border, width: 1),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF1A73E8)),
      ),
    );
  }
}

/// Badge sederhana: ikon + teks tanpa animasi
class _ProcessingBadge extends StatelessWidget {
  const _ProcessingBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5), // soft orange
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFD7A8), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.schedule, size: 16, color: Color(0xFFB26A00)),
          SizedBox(width: 6),
          Text(
            "processing bahasa isyarat dan subtitle",
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFFB26A00),
            ),
          ),
        ],
      ),
    );
  }
}

// === SearchBox yang mengirim perubahan ke parent ===
class _SearchBox extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const _SearchBox({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(28),
      ),
      child: TextField(
        onChanged: onChanged,
        decoration: const InputDecoration(
          hintText: "Cari berdasarkan judul video...",
          prefixIcon: Icon(Icons.search),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
