import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'getdetail.dart';

class VideoCard extends StatelessWidget {
  final String title;
  final String link;

  const VideoCard({
    super.key,
    required this.title,
    required this.link,
  });

  String? getYoutubeThumbnail(String url) {
    final uri = Uri.parse(url);
    String? videoId;

    if (uri.host.contains('youtu.be')) {
      videoId = uri.pathSegments.first;
    } else if (uri.host.contains('youtube.com')) {
      videoId = uri.queryParameters['v'];
    }

    return videoId != null
        ? 'https://img.youtube.com/vi/$videoId/hqdefault.jpg'
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final thumbnail = getYoutubeThumbnail(link);

    return GestureDetector(
      onTap: () async {
        // 🔹 Ambil detail video dari Firestore berdasarkan link/title
        final videoDoc = await FirebaseFirestore.instance
            .collection('videos')
            .where('link', isEqualTo: link)
            .get();

        if (videoDoc.docs.isNotEmpty) {
          final data = videoDoc.docs.first.data();

          // 🔹 Ambil data lengkap dari Firestore
          final signLangUrl = data['signLanguage'] ?? '';
          final subtitle = data['subtitle'] ?? '';

          // 🔹 Navigasi ke halaman detail video
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoDetailPage(
                title: title,
                videoUrl: link, // ✅ ini yang dulu belum ada
                signLangUrl: signLangUrl,
                subtitle: subtitle,
              ),
            ),
          );
        }
      },
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (thumbnail != null)
              ClipRRect(
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  thumbnail,
                  fit: BoxFit.cover,
                  height: 180,
                  width: double.infinity,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
