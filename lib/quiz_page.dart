import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Tipe untuk status halaman
enum QuizState { entry, loading, answering, results }

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  // --- State Management ---
  QuizState _currentState = QuizState.entry;
  final _videoController = TextEditingController();

  List<DocumentSnapshot> _questions = [];
  int _currentQuestionIndex = 0;
  int _score = 0;
  String _currentVideoId = ""; // Untuk menyimpan video ID yang diinput

  // --- Fungsi Logika ---

  // 1. Dipanggil saat tombol "Mulai Quiz" ditekan
  Future<void> _startQuiz() async {
    final videoId = _videoController.text.trim();
    if (videoId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Video ID tidak boleh kosong')),
      );
      return;
    }

    setState(() {
      _currentState = QuizState.loading;
      _currentVideoId = videoId; // Simpan video ID
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('questions')
          .where('videoID', isEqualTo: videoId)
          .get();

      if (snapshot.docs.isEmpty) {
        // Jika tidak ada soal, kembali ke awal dan beri pesan
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Soal untuk Video ID ini tidak ditemukan.')),
        );
        _resetQuiz();
      } else {
        // Jika soal ada, acak urutan soal
        snapshot.docs.shuffle();

        setState(() {
          _questions = snapshot.docs;
          _currentState = QuizState.answering;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      _resetQuiz();
    }
  }

  // 2. Dipanggil saat user memilih jawaban
  void _answerQuestion(String selectedOption) {
    final correctAnswer = _questions[_currentQuestionIndex].get('kunciJawaban');

    if (selectedOption == correctAnswer) {
      // Jawaban benar
      setState(() {
        _score++;
      });
    }

    // Pindah ke soal berikutnya
    setState(() {
      _currentQuestionIndex++;
    });

    // Jika soal sudah habis, pindah ke halaman hasil
    if (_currentQuestionIndex >= _questions.length) {
      setState(() {
        _currentState = QuizState.results;
      });
    }
  }

  // 3. Dipanggil untuk mengulang quiz
  void _resetQuiz() {
    setState(() {
      _currentState = QuizState.entry;
      _questions = [];
      _currentQuestionIndex = 0;
      _score = 0;
      _currentVideoId = "";
      // _videoController.clear(); // Biarkan terisi agar mudah di-tes ulang
    });
  }

  // --- Fungsi Build UI ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz EduSign'),
      ),
      body: _buildBody(),
    );
  }

  // Router untuk tampilan
  Widget _buildBody() {
    switch (_currentState) {
      case QuizState.entry:
        return _buildEntryView();
      case QuizState.loading:
        return Center(child: CircularProgressIndicator());
      case QuizState.answering:
        return _buildQuestionView();
      case QuizState.results:
        return _buildResultsView();
    }
  }

  // Tampilan 1: Halaman Masuk
  Widget _buildEntryView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Masukkan Video ID',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: 20),
          TextField(
            controller: _videoController,
            decoration: InputDecoration(
              labelText: 'Video ID',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _startQuiz,
            child: Text('Mulai Quiz'),
          )
        ],
      ),
    );
  }

  // Tampilan 2: Halaman Soal
  Widget _buildQuestionView() {
    if (_questions.isEmpty || _currentQuestionIndex >= _questions.length) {
      return Center(child: Text('Soal tidak valid.'));
    }

    final questionData =
        _questions[_currentQuestionIndex].data() as Map<String, dynamic>;
        
    // --- PERBAIKAN DI SINI ---
    // 1. Buat SALINAN list agar bisa diacak tanpa merusak data asli
    final List<dynamic> options = List.from(questionData['options']);
    
    // 2. Acak salinan list tersebut
    options.shuffle();
    // --- AKHIR PERBAIKAN ---

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Info Progres
          Text(
            'Soal ${_currentQuestionIndex + 1} dari ${_questions.length}',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),

          // Pertanyaan
          Text(
            questionData['pertanyaan'],
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 30),

          // Pilihan Jawaban (Sekarang sudah dari list yang teracak)
          ...options.map((option) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: ElevatedButton(
                onPressed: () => _answerQuestion(option as String),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(option as String, style: TextStyle(fontSize: 18)),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // Tampilan 3: Halaman Hasil
  Widget _buildResultsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Quiz Selesai!',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          SizedBox(height: 20),
          Text(
            'Nilai Kamu:',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(
            '$_score / ${_questions.length}',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          SizedBox(height: 30),
          ElevatedButton(
            onPressed: _resetQuiz,
            child: Text('Coba Video ID Lain'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }
}