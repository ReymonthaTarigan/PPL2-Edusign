import 'package:flutter/material.dart';
import 'getdetail.dart';

class VideoCard extends StatelessWidget {
  final String title;
  final String link;

  const VideoCard({super.key, required this.title, required this.link});

  String getYoutubeThumbnail(String url) {
    try {
      final uri = Uri.parse(url);
      final videoId = uri.pathSegments.last.split('?').first;
      return 'https://img.youtube.com/vi/$videoId/0.jpg';
    } catch (e) {
      return 'https://via.placeholder.com/120x90?text=No+Thumbnail';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigasi ke halaman detail
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoDetailPage(
              title: title,
              link: link,
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  getYoutubeThumbnail(link),
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const Icon(
                Icons.play_circle_fill,
                size: 60,
                color: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
