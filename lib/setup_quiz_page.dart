import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'form_quiz_page.dart';

class SetupQuizPage extends StatefulWidget {
  const SetupQuizPage({super.key});

  @override
  State<SetupQuizPage> createState() => _SetupQuizPageState();
}

class _SetupQuizPageState extends State<SetupQuizPage> {
  final _videoController = TextEditingController();
  final _jumlahController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final String videoID = _videoController.text;
      final int? jumlah = int.tryParse(_jumlahController.text);

      if (jumlah != null && jumlah > 0) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FormQuizPage(
              jumlahPertanyaan: jumlah,
              videoID: videoID,
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    _jumlahController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3D5A80),
        elevation: 0,
        title: const Text(
          'Setup Quiz Baru',
          style: TextStyle(
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
                const Text(
                  'Masukkan Detail Quiz',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF293241),
                  ),
                ),
                const SizedBox(height: 30),

                // Input Video ID
                TextFormField(
                  controller: _videoController,
                  decoration: InputDecoration(
                    labelText: 'Video ID (yang akan dites)',
                    labelStyle: const TextStyle(color: Color(0xFF293241)),
                    filled: true,
                    fillColor: const Color(0xFFE0FBFC),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF3D5A80), width: 2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF98C1D9)),
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Video ID wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Input Jumlah Pertanyaan
                TextFormField(
                  controller: _jumlahController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Jumlah Pertanyaan',
                    labelStyle: const TextStyle(color: Color(0xFF293241)),
                    filled: true,
                    fillColor: const Color(0xFFE0FBFC),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF3D5A80), width: 2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF98C1D9)),
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Harap isi jumlah';
                    }
                    if (int.tryParse(value) == null || int.parse(value) <= 0) {
                      return 'Masukkan angka positif';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),

                // Tombol Submit
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3D5A80),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 3,
                    ),
                    child: const Text(
                      'Buat Form',
                      style: TextStyle(
                        color: Colors.white,
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