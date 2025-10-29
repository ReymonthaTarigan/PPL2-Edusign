import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum QuizState { entry, loading, answering, results, noQuiz } // + noQuiz

class QuizPage extends StatefulWidget {
  /// Jika diisi, halaman akan otomatis mengisi textfield & langsung memulai kuis
  final String? initialVideoId;

  const QuizPage({super.key, this.initialVideoId});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  QuizState _currentState = QuizState.entry;
  final _videoController = TextEditingController();

  List<DocumentSnapshot> _questions = [];
  int _currentQuestionIndex = 0;
  int _score = 0;
  String _currentVideoId = "";

  @override
  void initState() {
    super.initState();
    final iv = (widget.initialVideoId ?? '').trim();
    if (iv.isNotEmpty) {
      _videoController.text = iv;
      WidgetsBinding.instance.addPostFrameCallback((_) => _startQuiz());
    }
  }

  Future<void> _startQuiz() async {
    final videoId = _videoController.text.trim();
    if (videoId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video ID tidak boleh kosong'),
          backgroundColor: Color(0xFFEE6C4D),
        ),
      );
      return;
    }

    setState(() {
      _currentState = QuizState.loading;
      _currentVideoId = videoId;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('questions')
          .where('videoID', isEqualTo: videoId)
          .get();

      if (snapshot.docs.isEmpty) {
        // TAMPILKAN HALAMAN “belum tersedia”
        setState(() {
          _currentState = QuizState.noQuiz;
        });
      } else {
        snapshot.docs.shuffle();
        setState(() {
          _questions = snapshot.docs;
          _currentState = QuizState.answering;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFFEE6C4D),
        ),
      );
      _resetQuiz();
    }
  }

  void _answerQuestion(String selectedOption) {
    final correctAnswer = _questions[_currentQuestionIndex].get('kunciJawaban');
    if (selectedOption == correctAnswer) _score++;
    setState(() => _currentQuestionIndex++);
    if (_currentQuestionIndex >= _questions.length) {
      setState(() => _currentState = QuizState.results);
    }
  }

  void _resetQuiz() {
    setState(() {
      _currentState = QuizState.entry;
      _questions = [];
      _currentQuestionIndex = 0;
      _score = 0;
      _currentVideoId = "";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3D5A80),
        elevation: 2,
        title: const Text(
          'Quiz EduSign',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_currentState) {
      case QuizState.entry:
        return _buildEntryView();
      case QuizState.loading:
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFF3D5A80)),
        );
      case QuizState.answering:
        return _buildQuestionView();
      case QuizState.results:
        return _buildResultsView();
      case QuizState.noQuiz:
        return _buildNoQuizView(); // << baru
    }
  }

  Widget _buildEntryView() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Masukkan Video ID untuk memulai kuis',
            style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF293241),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _videoController,
            style: const TextStyle(color: Color(0xFF293241)),
            decoration: InputDecoration(
              labelText: 'Video ID',
              labelStyle: const TextStyle(color: Color(0xFF293241)),
              filled: true,
              fillColor: const Color(0xFFE0FBFC),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Color(0xFF293241), width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Color(0xFF3D5A80), width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _startQuiz,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3D5A80),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text(
              'Mulai Kuis',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildQuestionView() {
    final questionData = _questions[_currentQuestionIndex].data() as Map<String, dynamic>;
    final List<dynamic> options = questionData['options'];

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          color: const Color(0xFF98C1D9),
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF293241), width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Soal ${_currentQuestionIndex + 1} dari ${_questions.length}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF293241), fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0FBFC),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromARGB(255, 49, 49, 49),
                          offset: Offset(-2, 2), blurRadius: 4, spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Text(
                      questionData['pertanyaan'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF293241), fontSize: 20, fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ...options.map((option) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: ElevatedButton(
                        onPressed: () => _answerQuestion(option as String),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3D5A80),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 3,
                        ),
                        child: Text(
                          option as String,
                          style: const TextStyle(
                            fontSize: 16, color: Color(0xFFE0FBFC), fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsView() {
    return Center(
      child: Card(
        color: const Color(0xFF98C1D9),
        margin: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF293241), width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Quiz Selesai!',
                style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF293241),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Nilai Kamu:', style: TextStyle(fontSize: 18, color: Color(0xFF293241))),
              Text(
                '$_score / ${_questions.length}',
                style: const TextStyle(
                  fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF3D5A80),
                ),
              ),
              const SizedBox(height: 24),
              // GANTI: tombol kembali ke materi (pop ke halaman sebelumnya)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).maybePop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3D5A80),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  'Kembali ke Materi',
                  style: TextStyle(
                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Tampilan bila tidak ada soal untuk video ini
  Widget _buildNoQuizView() {
    return Center(
      child: Card(
        color: const Color(0xFF98C1D9),
        margin: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF293241), width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Quiz untuk materi ini belum tersedia',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF293241),
                ),
              ),
              const SizedBox(height: 16),
              
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).maybePop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3D5A80),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  'Kembali',
                  style: TextStyle(
                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }
}