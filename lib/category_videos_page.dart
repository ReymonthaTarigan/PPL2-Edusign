import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// sesuaikan path jika berbeda
import 'getService/getdetail.dart';

class CategoryVideosPage extends StatelessWidget {
  final String subject;
  const CategoryVideosPage({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(subject),
        backgroundColor: const Color(0xFF3D5A80),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('videos')
            .where('subject', isEqualTo: subject)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No videos found for this subject"));
          }

          final videos = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final doc = videos[index];
              final data = doc.data() as Map<String, dynamic>;
              final title = data['title'] ?? 'Untitled';
              final link = data['link'] ?? '';
              final signLang = data['signLanguage'];
              final subtitle = data['subtitle'];

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                child: ListTile(
                  leading: const Icon(Icons.play_circle_fill,
                      color: Colors.blue, size: 40),
                  title: Text(title),
                  subtitle: const Text("Tap to watch"),
                  onTap: () {
                    final docId = doc.id; // <<< ambil ID dokumen dari koleksi `videos`
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VideoDetailPage(
                          title: title,
                          videoUrl: link,
                          signLangUrl: signLang,
                          subtitle: subtitle,
                          videoDocId: docId, // <<< kirim ke halaman detail
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
