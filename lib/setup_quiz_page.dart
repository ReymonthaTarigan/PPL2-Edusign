import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'form_quiz_page.dart'; // Halaman 2

class SetupQuizPage extends StatefulWidget {
  const SetupQuizPage({super.key});

  @override
  State<SetupQuizPage> createState() => _SetupQuizPageState();
}

class _SetupQuizPageState extends State<SetupQuizPage> {
  // Bikin 2 controller
  final _videoController = TextEditingController();
  final _jumlahController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // Ambil kedua nilai
      final String videoID = _videoController.text;
      final int? jumlah = int.tryParse(_jumlahController.text);

      if (jumlah != null && jumlah > 0) {
        // Kirim kedua data ke halaman FormQuizPage
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FormQuizPage(
              jumlahPertanyaan: jumlah,
              videoID: videoID, // <- Data videoID dikirim
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
      appBar: AppBar(
        title: Text('Setup Quiz Baru'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Masukkan Detail Quiz',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              SizedBox(height: 20),
              
              // --- FORM UNTUK VIDEO ID ---
              TextFormField(
                controller: _videoController,
                decoration: InputDecoration(
                  labelText: 'Video ID (yang akan dites)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Video ID wajib diisi';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),

              // --- FORM UNTUK JUMLAH SOAL ---
              TextFormField(
                controller: _jumlahController,
                decoration: InputDecoration(
                  labelText: 'Jumlah Pertanyaan',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                ),
                child: Text('Buat Form'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}