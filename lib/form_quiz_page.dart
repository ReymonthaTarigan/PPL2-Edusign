import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Helper class: videoId DIHAPUS, opsiSalah4 DITAMBAH
class QuestionControllers {
  // final videoId = TextEditingController(); // <- DIHAPUS
  final pertanyaan = TextEditingController();
  final opsiBenar = TextEditingController();
  final opsiSalah1 = TextEditingController();
  final opsiSalah2 = TextEditingController();
  final opsiSalah3 = TextEditingController();
  final opsiSalah4 = TextEditingController(); // <- DITAMBAH

  void dispose() {
    // videoId.dispose(); // <- DIHAPUS
    pertanyaan.dispose();
    opsiBenar.dispose();
    opsiSalah1.dispose();
    opsiSalah2.dispose();
    opsiSalah3.dispose();
    opsiSalah4.dispose(); // <- DITAMBAH
  }
}

class FormQuizPage extends StatefulWidget {
  // Menerima 2 data: jumlah dan videoID
  final int jumlahPertanyaan;
  final String videoID; // <- DITAMBAH

  const FormQuizPage({
    super.key,
    required this.jumlahPertanyaan,
    required this.videoID, // <- DITAMBAH
  });

  @override
  State<FormQuizPage> createState() => _FormQuizPageState();
}

class _FormQuizPageState extends State<FormQuizPage> {
  late List<QuestionControllers> _controllersList;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controllersList = List.generate(
      widget.jumlahPertanyaan,
      (_) => QuestionControllers(),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllersList) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _kirimKeFirebase() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Harap isi semua field yang wajib diisi')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final batch = FirebaseFirestore.instance.batch();
    final collection = FirebaseFirestore.instance.collection('questions');

    for (var controller in _controllersList) {
      // 1. Ambil data
      
      // Ambil videoID dari widget, bukan controller
      final video = widget.videoID; // <- DIUBAH 
      
      final soal = controller.pertanyaan.text;
      final jawabanBenar = controller.opsiBenar.text;

      // 2. Buat list options (sekarang jadi 5)
      final options = [
        jawabanBenar,
        controller.opsiSalah1.text,
        controller.opsiSalah2.text,
        controller.opsiSalah3.text,
        controller.opsiSalah4.text, // <- DITAMBAH
      ];

      // 3. Acak list options
      options.shuffle();

      // 4. Siapkan data map
      final Map<String, dynamic> dataSoal = {
        'videoID': video, // <- videoID ini sama untuk semua soal
        'pertanyaan': soal,
        'options': options,
        'kunciJawaban': jawabanBenar,
      };

      // 5. Tambahkan ke batch
      final docRef = collection.doc();
      batch.set(docRef, dataSoal);
    }

    try {
      // 6. Eksekusi batch
      await batch.commit();

      // 7. Beri feedback sukses
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sukses! ${widget.jumlahPertanyaan} soal ditambahkan.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      // 8. Beri feedback error
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Judul bisa dibuat lebih jelas
        title: Text('Buat ${widget.jumlahPertanyaan} Soal'),
        bottom: PreferredSize( // Tambahan: Subtitle untuk info videoID
           preferredSize: Size.fromHeight(20.0),
           child: Text(
             'Video ID: ${widget.videoID}', 
             style: TextStyle(color: Colors.white70, fontSize: 12)
           ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _kirimKeFirebase,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 16),
          ),
          child: _isLoading
              ? CircularProgressIndicator(color: Colors.white)
              : Text('Kirim Semua ke Firebase', style: TextStyle(fontSize: 16)),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView.builder(
          itemCount: widget.jumlahPertanyaan,
          itemBuilder: (context, index) {
            return _buildQuestionForm(index, _controllersList[index]);
          },
        ),
      ),
    );
  }

  // Widget untuk 1 form soal
  Widget _buildQuestionForm(int index, QuestionControllers controller) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Soal Nomor ${index + 1}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            
            // --- FIELD VIDEO ID DIHAPUS DARI SINI ---
            // _buildTextFormField(
            //   controller: controller.videoId,
            //   ...
            // ),

            _buildTextFormField(
              controller: controller.pertanyaan,
              label: 'Teks Pertanyaan',
              isRequired: true,
            ),
            SizedBox(height: 10),
            _buildTextFormField(
              controller: controller.opsiBenar,
              label: 'Jawaban Benar (Opsi 1)',
              isRequired: true,
            ),
            _buildTextFormField(
              controller: controller.opsiSalah1,
              label: 'Opsi Salah 1',
              isRequired: true,
            ),
            _buildTextFormField(
              controller: controller.opsiSalah2,
              label: 'Opsi Salah 2',
              isRequired: true,
            ),
            _buildTextFormField(
              controller: controller.opsiSalah3,
              label: 'Opsi Salah 3',
              isRequired: true,
            ),
            // --- FIELD OPSI 5 DITAMBAHKAN ---
            _buildTextFormField(
              controller: controller.opsiSalah4,
              label: 'Opsi Salah 4',
              isRequired: true,
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget (tidak berubah)
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    bool isRequired = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        validator: isRequired
            ? (value) {
                if (value == null || value.isEmpty) {
                  return 'Field ini wajib diisi';
                }
                return null;
              }
            : null,
      ),
    );
  }
}