import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// sesuaikan path jika berbeda
import 'getService/getdetail.dart';

class CategoryVideosPage extends StatelessWidget {
  final String subject;
  const CategoryVideosPage({super.key, required this.subject});

  /// 🔹 Fungsi untuk ambil thumbnail dari link YouTube
  String getYoutubeThumbnail(String url) {
    final Uri? uri = Uri.tryParse(url);
    if (uri == null) return '';

    if (uri.host.contains('youtube.com') && uri.queryParameters.containsKey('v')) {
      final videoId = uri.queryParameters['v'];
      return 'https://img.youtube.com/vi/$videoId/0.jpg';
    }

    if (uri.host.contains('youtu.be')) {
      final videoId = uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : '';
      return 'https://img.youtube.com/vi/$videoId/0.jpg';
    }

    return '';
  }

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
                  // 🔹 Tambahkan thumbnail YouTube di sini
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 100,
                      height: 60,
                      child: Image.network(
                        getYoutubeThumbnail(link),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image,
                            size: 40, color: Colors.grey),
                      ),
                    ),
                  ),
                  title: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
