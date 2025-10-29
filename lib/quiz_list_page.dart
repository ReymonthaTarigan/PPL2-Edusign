import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'setup_quiz_page.dart';

class QuizListPage extends StatelessWidget {
  final String videoId;
  const QuizListPage({super.key, required this.videoId});

  @override
  Widget build(BuildContext context) {
    final questionsRef = FirebaseFirestore.instance
        .collection('questions')
        .where('videoID', isEqualTo: videoId);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3D5A80),
        title: const Text('Daftar Soal', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            tooltip: 'Tambah Soal',
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SetupQuizPage(videoId: videoId),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: questionsRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Belum ada soal untuk video ini.\nTekan tombol tambah untuk mulai membuat.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final docRef = docs[i].reference;
              final no = i + 1;
              final pertanyaan = (data['pertanyaan'] ?? '').toString();
              final options =
                  (data['options'] as List?)?.map((e) => e.toString()).toList() ??
                      const [];
              final kunciJawaban = (data['kunciJawaban'] ?? '').toString();

              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F4FF),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))
                  ],
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nomor Soal
                    Text(
                      'Soal $no',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1E88E5),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Pertanyaan
                    Text(
                      pertanyaan,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),

                    // Pilihan jawaban
                    ...options.map((opt) {
                      final isAnswer = opt == kunciJawaban;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              isAnswer
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              size: 18,
                              color: isAnswer
                                  ? const Color(0xFF2E7D32)
                                  : Colors.black45,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                opt,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isAnswer
                                      ? const Color(0xFF2E7D32)
                                      : Colors.black87,
                                  fontWeight:
                                      isAnswer ? FontWeight.w700 : FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),

                    const SizedBox(height: 8),

                    // Tombol Edit & Hapus
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          tooltip: 'Edit soal',
                          icon: const Icon(Icons.edit_outlined,
                              color: Color(0xFF1565C0)),
                          onPressed: () {
                            _showEditDialog(
                              context,
                              docRef,
                              pertanyaan,
                              options,
                              kunciJawaban,
                            );
                          },
                        ),
                        IconButton(
                          tooltip: 'Hapus soal',
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.redAccent),
                          onPressed: () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: const Text('Hapus Soal?'),
                                content: const Text(
                                    'Tindakan ini tidak bisa dibatalkan.'),
                                actions: [
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.of(dialogContext).pop(false),
                                      child: const Text('Batal')),
                                  ElevatedButton(
                                      onPressed: () =>
                                          Navigator.of(dialogContext).pop(true),
                                      child: const Text('Hapus')),
                                ],
                              ),
                            );
                            if (ok == true) {
                              await docRef.delete();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Soal dihapus')),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ==== Dialog Edit Soal ====
  void _showEditDialog(BuildContext context, DocumentReference docRef,
      String pertanyaan, List<String> options, String kunciJawaban) {
    final pertanyaanController = TextEditingController(text: pertanyaan);
    final optionControllers = List.generate(
      4,
      (i) => TextEditingController(
        text: i < options.length ? options[i] : '',
      ),
    );
    final kunciController = TextEditingController(text: kunciJawaban);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Soal"),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: pertanyaanController,
                  decoration:
                      const InputDecoration(labelText: "Pertanyaan"),
                ),
                const SizedBox(height: 12),
                ...List.generate(4, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TextField(
                      controller: optionControllers[i],
                      decoration: InputDecoration(
                        labelText: "Opsi ${i + 1}",
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 12),
                TextField(
                  controller: kunciController,
                  decoration:
                      const InputDecoration(labelText: "Kunci Jawaban"),
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
                backgroundColor: const Color(0xFF3D5A80),
                foregroundColor: Colors.white, // ← ini bikin teksnya putih
              ),
              child: const Text("Simpan Perubahan"),
              onPressed: () async {
                final newQuestion = pertanyaanController.text.trim();
                final newOptions =
                    optionControllers.map((c) => c.text.trim()).toList();
                final newAnswer = kunciController.text.trim();

                if (newQuestion.isEmpty ||
                    newOptions.any((e) => e.isEmpty) ||
                    newAnswer.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("⚠ Harap isi semua field sebelum menyimpan.")),
                  );
                  return;
                }

                await docRef.update({
                  'pertanyaan': newQuestion,
                  'options': newOptions,
                  'kunciJawaban': newAnswer,
                });

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("✅ Soal berhasil diperbarui!")),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}
