import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QuestionControllers {
  final pertanyaan = TextEditingController();
  final opsiBenar = TextEditingController();
  final opsiSalah1 = TextEditingController();
  final opsiSalah2 = TextEditingController();
  final opsiSalah3 = TextEditingController();
  final opsiSalah4 = TextEditingController();

  void dispose() {
    pertanyaan.dispose();
    opsiBenar.dispose();
    opsiSalah1.dispose();
    opsiSalah2.dispose();
    opsiSalah3.dispose();
    opsiSalah4.dispose();
  }
}

class FormQuizPage extends StatefulWidget {
  final int jumlahPertanyaan;
  final String videoID;

  const FormQuizPage({
    super.key,
    required this.jumlahPertanyaan,
    required this.videoID,
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
    _controllersList =
        List.generate(widget.jumlahPertanyaan, (_) => QuestionControllers());
  }

  @override
  void dispose() {
    for (var c in _controllersList) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _kirimKeFirebase() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap isi semua field yang wajib diisi'),
          backgroundColor: Color(0xFFEE6C4D),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final batch = FirebaseFirestore.instance.batch();
    final collection = FirebaseFirestore.instance.collection('questions');

    for (var controller in _controllersList) {
      final soal = controller.pertanyaan.text;
      final jawabanBenar = controller.opsiBenar.text;
      final options = [
        jawabanBenar,
        controller.opsiSalah1.text,
        controller.opsiSalah2.text,
        controller.opsiSalah3.text,
        controller.opsiSalah4.text,
      ]..shuffle();

      final data = {
        'videoID': widget.videoID,
        'pertanyaan': soal,
        'options': options,
        'kunciJawaban': jawabanBenar,
      };

      batch.set(collection.doc(), data);
    }

    try {
      await batch.commit();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Sukses! ${widget.jumlahPertanyaan} soal ditambahkan ke database.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan: $e'),
          backgroundColor: const Color(0xFFEE6C4D),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3D5A80),
        elevation: 0,
        title: Text(
          'Buat ${widget.jumlahPertanyaan} Soal',
          style: const TextStyle(
            color: Color(0xFFFAF9F6),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Video ID: ${widget.videoID}',
              style: const TextStyle(
                color: Color(0xFFE0FBFC),
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          itemCount: widget.jumlahPertanyaan,
          itemBuilder: (context, index) =>
              _buildQuestionCard(index, _controllersList[index]),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _kirimKeFirebase,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3D5A80),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
                  'Kirim Semua ke Firebase',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(int index, QuestionControllers controller) {
    return Card(
      color: const Color(0xFF98C1D9),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF293241), width: 2),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Soal Nomor ${index + 1}',
              style: const TextStyle(
                color: Color(0xFF3D5A80),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            _buildInput(controller.pertanyaan, 'Teks Pertanyaan', true),
            _buildInput(controller.opsiBenar, 'Jawaban Benar (Opsi 1)', true),
            _buildInput(controller.opsiSalah1, 'Opsi Salah 1', true),
            _buildInput(controller.opsiSalah2, 'Opsi Salah 2', true),
            _buildInput(controller.opsiSalah3, 'Opsi Salah 3', true),
            _buildInput(controller.opsiSalah4, 'Opsi Salah 4', true),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(
      TextEditingController controller, String label, bool isRequired) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Color(0xFF293241)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF293241)),
          hintText: label,
          hintStyle: const TextStyle(color: Color(0xFF293241)),
          filled: true,
          fillColor: const Color(0xFFE0FBFC),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFF293241), width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFF293241)),
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
        validator: isRequired
            ? (value) =>
                (value == null || value.isEmpty) ? 'Field ini wajib diisi' : null
            : null,
      ),
    );
  }
}