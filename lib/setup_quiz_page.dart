import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'form_quiz_page.dart';

class SetupQuizPage extends StatefulWidget {
  // terima videoId dari AdminHomePage
  final String videoId;
  // opsional: kalau nanti kamu mau mode edit, bisa kirim jumlah awal
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
  late final TextEditingController _videoController;
  late final TextEditingController _jumlahController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _videoController = TextEditingController(text: widget.videoId);
    _jumlahController = TextEditingController(
      text: widget.initialJumlah != null ? widget.initialJumlah.toString() : '',
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final String videoID = _videoController.text.trim();
      final int? jumlah = int.tryParse(_jumlahController.text.trim());

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

                // Video ID (terisi & readOnly)
                TextFormField(
                  controller: _videoController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Video ID',
                    labelStyle: const TextStyle(color: Color(0xFF293241)),
                    filled: true,
                    fillColor: const Color(0xFFE0FBFC),
                    suffixIcon: const Icon(Icons.lock_outline),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF3D5A80), width: 2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF98C1D9)),
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Jumlah Pertanyaan
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
                    final n = int.tryParse(value);
                    if (n == null || n <= 0) {
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
                    child: Text(
                      isEdit ? 'Perbarui Form' : 'Buat Form',
                      style: const TextStyle(
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
