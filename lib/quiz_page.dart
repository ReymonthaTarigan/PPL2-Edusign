import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:auto_size_text/auto_size_text.dart';

enum QuizState { entry, loading, answering, results, noQuiz }

class QuizPage extends StatefulWidget {
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
        const SnackBar(content: Text('Video ID tidak boleh kosong')),
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
        setState(() => _currentState = QuizState.noQuiz);
      } else {
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_currentState) {
      case QuizState.entry:
        return _buildEntryView();
      case QuizState.loading:
        return const Center(child: CircularProgressIndicator(color: Color(0xFF3D5A80)));
      case QuizState.answering:
        return _buildQuestionView();
      case QuizState.results:
        return _buildResultsView();
      case QuizState.noQuiz:
        return _buildNoQuizView();
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
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF293241)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _videoController,
            decoration: InputDecoration(
              labelText: 'Video ID',
              filled: true,
              fillColor: const Color(0xFFE0FBFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
            child: const Text('Mulai Kuis', style: TextStyle(color: Colors.white, fontSize: 16)),
          )
        ],
      ),
    );
  }

  Widget _buildQuestionView() {
    final questionData = _questions[_currentQuestionIndex].data() as Map<String, dynamic>;
    final List<dynamic> options = questionData['options'];

    return Stack(
      children: [
        // Background gradient
        Container(
          height: 250,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF98C1D9), Color(0xFF3D5A80)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(150)),
          ),
        ),

        // Tombol back di kiri atas
        SafeArea(
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),

        // Konten pertanyaan
        Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 100),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Lingkaran nomor
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF3D5A80), width: 4),
                  ),
                  child: Center(
                    child: Text(
                      '${_currentQuestionIndex + 1}',
                      style: const TextStyle(
                        color: Color(0xFF3D5A80),
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Question ${_currentQuestionIndex + 1}/${_questions.length}',
                  style: const TextStyle(
                    color: Color(0xFFFFFFFF),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),

                // Pertanyaan
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 4))
                    ],
                  ),
                  child: Text(
                    questionData['pertanyaan'],
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 40),

                // Pilihan jawaban (dalam box)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: options.map((option) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: GestureDetector(
                          onTap: () => _answerQuestion(option as String),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: const Color(0xFF3D5A80)),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: AutoSizeText(
                                option as String,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                minFontSize: 10,
                                style: const TextStyle(
                                  color: Color(0xFF3D5A80),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
              const Text('Quiz Selesai!',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF293241))),
              const SizedBox(height: 20),
              const Text('Nilai Kamu:', style: TextStyle(fontSize: 18, color: Color(0xFF293241))),
              Text(
                '$_score / ${_questions.length}',
                style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF3D5A80)),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).maybePop(),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3D5A80),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: const Text('Kembali ke Materi',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
              const Text('Quiz untuk materi ini belum tersedia',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF293241))),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).maybePop(),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3D5A80),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: const Text('Kembali',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
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
