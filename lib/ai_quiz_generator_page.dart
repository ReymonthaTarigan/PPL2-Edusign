import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class AiQuizGeneratorPage extends StatefulWidget {
  const AiQuizGeneratorPage({super.key});

  @override
  State<AiQuizGeneratorPage> createState() => _AiQuizGeneratorPageState();
}

class _AiQuizGeneratorPageState extends State<AiQuizGeneratorPage> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  
  // Ini untuk memberi tahu StreamBuilder ID apa yang harus dicari
  String? _videoIDToQuery;

  // Fungsi untuk memanggil robot AI Anda
  Future<void> _triggerGeneration() async {
    if (!_formKey.currentState!.validate()) return;

    final videoId = _controller.text.trim();
    setState(() {
      _isLoading = true;
      _videoIDToQuery = videoId; // Mulai "dengarkan" Firestore
    });

    try {
      // 1. Tentukan lokasi robot Anda
      final functions = FirebaseFunctions.instanceFor(region: "asia-southeast2");
      
      // 2. Panggil nama robotnya (kita akan namai 'generateQuizOnCall')
      final callable = functions.httpsCallable('generateQuizOnCall');
      
      // 3. Kirim videoID sebagai data
      final response = await callable.call({'videoID': videoId});

      // 4. Tampilkan pesan sukses dari robot
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.data['message']),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseFunctionsException catch (e) {
      // 5. Tampilkan pesan error jika robot gagal
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error tidak diketahui: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // 6. Selesai loading
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Generate Quiz Otomatis (AI)'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- Bagian Input ---
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: 'Video ID (yang file .srt nya sudah ada)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Video ID wajib diisi';
                  }
                  return null;
                },
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              // Jangan biarkan tombol diklik saat sedang loading
              onPressed: _isLoading ? null : _triggerGeneration,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              ),
              child: _isLoading 
                  ? CircularProgressIndicator(color: Colors.white) 
                  : Text('Generate Soal'),
            ),
            
            Divider(height: 40),

            // --- Bagian Hasil ---
            Text(
              'Hasil Generate:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 10),
            
            // Widget ini akan "mendengarkan" database secara real-time
            _buildResultsStream(),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsStream() {
    // 1. Jika user belum menekan tombol, tampilkan pesan
    if (_videoIDToQuery == null) {
      return Text('Tekan tombol "Generate" untuk memulai...');
    }
    
    // 2. Jika user sudah menekan, dengarkan Firestore
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        // Dengarkan koleksi 'questions' yang videoID-nya cocok
        stream: FirebaseFirestore.instance
            .collection('questions')
            .where('videoID', isEqualTo: _videoIDToQuery)
            .snapshots(),
            
        builder: (context, snapshot) {
          // 3. Saat loading (menunggu data dari Firestore)
          if (snapshot.connectionState == ConnectionState.waiting && !_isLoading) {
            return Center(child: Text('Menunggu data dari server...'));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.red)));
          }
          
          // 4. Jika data kosong (robot belum selesai/tidak ada soal)
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            if (_isLoading) {
               return Center(child: Text('Robot AI sedang bekerja...'));
            }
            return Center(child: Text('Belum ada soal untuk Video ID ini.'));
          }

          // 5. Jika data ditemukan, tampilkan!
          final docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final question = docs[index].data() as Map<String, dynamic>;
              return Card(
                margin: EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  title: Text(question['pertanyaan']),
                  subtitle: Text('Jawaban: ${question['kunciJawaban']}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}