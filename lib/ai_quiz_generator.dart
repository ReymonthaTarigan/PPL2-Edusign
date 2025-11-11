import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'quiz_list_page.dart';

class AiQuizGeneratorPage extends StatefulWidget {
  final String videoId; // dikirim dari SetupQuizPage / AdminHomePage

  const AiQuizGeneratorPage({
    super.key,
    required this.videoId,
  });

  @override
  State<AiQuizGeneratorPage> createState() => _AiQuizGeneratorPageState();
}

class _AiQuizGeneratorPageState extends State<AiQuizGeneratorPage> {
  bool _isLoading = false;

  Future<void> _triggerGeneration() async {
    final videoId = widget.videoId;

    if (videoId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video ID tidak valid.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
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

      // Setelah berhasil → langsung pindah ke halaman list quiz
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
          content: Text('Error dari server: ${e.message}'),
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
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tidak menampilkan videoId, hanya info umum
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Quiz Otomatis (AI)'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Generate kuis otomatis untuk video ini.\n'
              'Pastikan file subtitle (.srt) sudah tersedia di server.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _triggerGeneration,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Generate Soal'),
            ),
          ],
        ),
      ),
    );
  }
}
