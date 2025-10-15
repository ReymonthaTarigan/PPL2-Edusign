import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/material.dart';

class VideoDetailPage extends StatefulWidget {
  final String title;
  final String videoUrl; // URL YouTube
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
  final _yt = YoutubeExplode();
  VideoPlayerController? _mainController;
  VideoPlayerController? _signLangController;
  bool _showSubtitle = true;

  @override
  void initState() {
    super.initState();
    _initializeVideos();
  }

  Future<void> _initializeVideos() async {
    // 🔹 Ambil stream URL dari YouTube
    final videoId = VideoId(widget.videoUrl);
    final manifest = await _yt.videos.streamsClient.getManifest(videoId);
    final streamInfo = manifest.muxed.bestQuality; // video+audio
    final youtubeStreamUrl = streamInfo.url.toString();

    // 🔹 Inisialisasi VideoPlayer dari link YouTube
    _mainController = VideoPlayerController.networkUrl(Uri.parse(youtubeStreamUrl))
      ..initialize().then((_) {
        setState(() {});
        _mainController!.play();
      });

    // 🔹 Inisialisasi Video Bahasa Isyarat (jika ada)
    if (widget.signLangUrl != null && widget.signLangUrl!.isNotEmpty) {
      _signLangController = VideoPlayerController.networkUrl(Uri.parse(widget.signLangUrl!))
        ..initialize().then((_) {
          setState(() {});
          _signLangController!.play();
        });
    }
  }

  @override
  void dispose() {
    _yt.close();
    _mainController?.dispose();
    _signLangController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _mainController?.value.isInitialized == true
          ? AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.blue[900],
      )
          : null,
      body: Stack(
        children: [
          // Video utama
          if (_mainController != null && _mainController!.value.isInitialized)
            Center(
              child: AspectRatio(
                aspectRatio: _mainController!.value.aspectRatio,
                child: VideoPlayer(_mainController!),
              ),
            )
          else
            const Center(child: CircularProgressIndicator()),

          // Tombol show/hide subtitle
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Column(
              children: [
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
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      widget.subtitle!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        backgroundColor: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),

          // Video Bahasa Isyarat (kecil di pojok)
          if (_signLangController != null &&
              _signLangController!.value.isInitialized)
            Positioned(
              bottom: 100,
              right: 20,
              width: 120,
              height: 160,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: VideoPlayer(_signLangController!),
              ),
            ),
        ],
      ),
    );
  }
}
