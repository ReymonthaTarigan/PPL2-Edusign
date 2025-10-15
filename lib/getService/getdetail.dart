import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class VideoDetailPage extends StatefulWidget {
  final String title;
  final String videoUrl;
  final String? signLangUrl;
  final String? subtitle;

  const VideoDetailPage({
    super.key,
    required this.title,
    required this.videoUrl,
    this.signLangUrl,
    this.subtitle,
  });

  @override
  State<VideoDetailPage> createState() => _VideoDetailPageState();
}

class _VideoDetailPageState extends State<VideoDetailPage> {
  late YoutubePlayerController _youtubeController;
  VideoPlayerController? _signLangController;
  bool _showSubtitle = true;

  @override
  void initState() {
    super.initState();

    final videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);
    _youtubeController = YoutubePlayerController(
      initialVideoId: videoId ?? '',
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
      ),
    );

    if (widget.signLangUrl != null && widget.signLangUrl!.isNotEmpty) {
      _signLangController =
      VideoPlayerController.networkUrl(Uri.parse(widget.signLangUrl!))
        ..initialize().then((_) {
          setState(() {});
          _signLangController!.play();
        });
    }
  }

  @override
  void dispose() {
    _youtubeController.dispose();
    _signLangController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.blue[900],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              YoutubePlayer(
                controller: _youtubeController,
                showVideoProgressIndicator: true,
              ),
              const SizedBox(height: 8),

              // Tombol Subtitle
              TextButton(
                onPressed: () {
                  setState(() {
                    _showSubtitle = !_showSubtitle;
                  });
                },
                child: Text(
                  _showSubtitle ? "Hide Subtitle" : "Show Subtitle",
                  style: const TextStyle(color: Colors.blue),
                ),
              ),

              if (_showSubtitle && widget.subtitle != null)
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    widget.subtitle!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),

          // Video Bahasa Isyarat
          if (_signLangController != null &&
              _signLangController!.value.isInitialized)
            Positioned(
              bottom: 100,
              right: 20,
              width: 120,
              height: 160,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: _signLangController!.value.aspectRatio,
                  child: VideoPlayer(_signLangController!),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
