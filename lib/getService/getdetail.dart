import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'youtube_service.dart';


class VideoDetailPage extends StatefulWidget {
  final String title;
  final String link;

  const VideoDetailPage({
    super.key,
    required this.title,
    required this.link,
  });


  @override
  State<VideoDetailPage> createState() => _VideoDetailPageState();
}
class _VideoDetailPageState extends State<VideoDetailPage> {
  late YoutubePlayerController _controller;
  Map<String, dynamic>? videoData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVideoData();
  }

  Future<void> _loadVideoData() async {
    final service = YouTubeService();
    final data = await service.fetchVideoDetails(widget.link);

    final videoId = YoutubePlayer.convertUrlToId(widget.link);
    _controller = YoutubePlayerController(
      initialVideoId: videoId ?? '',
      flags: const YoutubePlayerFlags(autoPlay: false),
    );

    setState(() {
      videoData = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (videoData == null) {
      return const Scaffold(
        body: Center(child: Text("Video not found")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(videoData!["title"] ?? "Video")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            YoutubePlayer(controller: _controller),
            const SizedBox(height: 16),
            Text(
              videoData!["title"],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              "By ${videoData!["channel"]}",
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.visibility, color: Colors.grey, size: 18),
                const SizedBox(width: 4),
                Text("${videoData!["views"]} views"),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              videoData!["description"],
              style: const TextStyle(fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
