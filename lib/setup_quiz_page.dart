import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'form_quiz_page.dart';
import 'quiz_list_page.dart';

class SetupQuizPage extends StatefulWidget {
  final String videoId;
  final int? initialJumlah;

  const SetupQuizPage({
    super.key,
    required this.videoId,
    this.initialJumlah,
  });

  @override
  State<SetupQuizPage> createState() => _SetupQuizPageState();
}

class _SetupQuizPageState extends State<SetupQuizPage> {
  late final TextEditingController _jumlahController;
  final _formKey = GlobalKey<FormState>();

  bool _isAiLoading = false; // loading khusus tombol AI

  @override
  void initState() {
    super.initState();
    _jumlahController = TextEditingController(
      text: widget.initialJumlah != null ? widget.initialJumlah.toString() : '',
    );
  }

  @override
  void dispose() {
    _jumlahController.dispose();
    super.dispose();
  }

  // FLOW 1: Manual
  void _goToManualForm() {
    if (_formKey.currentState!.validate()) {
      final jumlah = int.tryParse(_jumlahController.text.trim());
      if (jumlah != null && jumlah > 0) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FormQuizPage(
              jumlahPertanyaan: jumlah,
              videoID: widget.videoId,
            ),
          ),
        );
      }
    }
  }

  // FLOW 2: Generate Otomatis dengan AI (tanpa pindah halaman dulu)
  Future<void> _generateWithAi() async {
    if (_isAiLoading) return;

    final videoId = widget.videoId;
    if (videoId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video ID tidak valid.')),
      );
      return;
    }

    setState(() {
      _isAiLoading = true;
    });

    try {
      final functions = FirebaseFunctions.instanceFor(region: "asia-southeast2");
      final callable = functions.httpsCallable('generateQuizOnCall');

      final response = await callable.call({'videoID': videoId});

      if (!mounted) return;

      final message = (response.data is Map && response.data['message'] != null)
          ? response.data['message'] as String
          : 'Berhasil generate kuis otomatis.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );

      // Setelah sukses generate → langsung pindah ke QuizListPage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => QuizListPage(videoId: videoId),
        ),
      );
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Silahkan generate subtitle video ini dahulu'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error tidak diketahui: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAiLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialJumlah != null;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3D5A80),
        elevation: 0,
        title: Text(
          isEdit ? 'Edit Quiz' : 'Setup Quiz Baru',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Text(
                  isEdit ? 'Perbarui Detail Quiz' : 'Masukkan Detail Quiz',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF293241),
                  ),
                ),
                const SizedBox(height: 30),

                // Input jumlah untuk flow manual
                TextFormField(
                  controller: _jumlahController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Jumlah Pertanyaan (Manual)',
                    labelStyle: const TextStyle(color: Color(0xFF293241)),
                    filled: true,
                    fillColor: const Color(0xFFE0FBFC),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          const BorderSide(color: Color(0xFF3D5A80), width: 2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide:
                          const BorderSide(color: Color(0xFF98C1D9)),
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  validator: (value) {
                    // Validasi ini hanya untuk tombol manual.
                    // Untuk AI, field ini boleh dikosongkan.
                    if (value == null || value.isEmpty) {
                      return 'Isi jumlah untuk form manual, atau gunakan tombol AI di bawah.';
                    }
                    final n = int.tryParse(value);
                    if (n == null || n <= 0) {
                      return 'Masukkan angka positif';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Tombol Flow Manual
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _goToManualForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3D5A80),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      isEdit ? 'Perbarui Form Manual' : 'Buat Form Manual',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Pemisah
                Row(
                  children: const [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'ATAU',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF7B8794),
                        ),
                      ),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),

                // Tombol Flow AI
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isAiLoading ? null : _generateWithAi,
                    icon: _isAiLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(
                          color: Color(0xFF3D5A80), width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    label: Text(
                      _isAiLoading
                          ? 'Menghasilkan soal...'
                          : 'Generate Otomatis dengan AI',
                      style: const TextStyle(
                        color: Color(0xFF3D5A80),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
