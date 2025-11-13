import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/material.dart';

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
  final _yt = YoutubeExplode();
  VideoPlayerController? _mainController;
  VideoPlayerController? _signLangController;
  bool _showSubtitle = true;

  final TextEditingController _commentController = TextEditingController();
  final List<String> _comments = [];

  @override
  void initState() {
    super.initState();
    _initializeVideos();
  }

  Future<void> _initializeVideos() async {
    final videoId = VideoId(widget.videoUrl);
    final manifest = await _yt.videos.streamsClient.getManifest(videoId);
    final streamInfo = manifest.muxed.bestQuality;
    final youtubeStreamUrl = streamInfo.url.toString();

    _mainController = VideoPlayerController.networkUrl(Uri.parse(youtubeStreamUrl))
      ..initialize().then((_) {
        setState(() {});
        _mainController!.play();
      });

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
    _commentController.dispose();
    super.dispose();
  }

  void _addComment() {
    if (_commentController.text.trim().isEmpty) return;
    setState(() {
      _comments.add(_commentController.text.trim());
      _commentController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.blue[900],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              children: [
                // 🔹 Video utama
                if (_mainController != null &&
                    _mainController!.value.isInitialized)
                  AspectRatio(
                    aspectRatio: _mainController!.value.aspectRatio,
                    child: VideoPlayer(_mainController!),
                  )
                else
                  const SizedBox(
                    height: 220,
                    child: Center(child: CircularProgressIndicator()),
                  ),

                const SizedBox(height: 10),

                // 🔹 Tombol Subtitle
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showSubtitle = !_showSubtitle;
                    });
                  },
                  child: Text(
                    _showSubtitle ? "Sembunyikan Subtitle" : "Tampilkan Subtitle",
                    style: const TextStyle(color: Colors.blue),
                  ),
                ),

                // 🔹 Subtitle
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

                // 🔹 Video Bahasa Isyarat (opsional)
                if (_signLangController != null &&
                    _signLangController!.value.isInitialized)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 160,
                        height: 200,
                        child: VideoPlayer(_signLangController!),
                      ),
                    ),
                  ),

                const Divider(height: 30, thickness: 1),

                // 🔹 Kolom input komentar
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: "Tulis komentar...",
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide:
                                  const BorderSide(color: Colors.blueAccent),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send, color: Colors.blueAccent),
                        onPressed: _addComment,
                      ),
                    ],
                  ),
                ),

                // 🔹 Daftar komentar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  color: const Color(0xFFF5F5F5),
                  child: _comments.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            "Belum ada komentar",
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _comments.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Colors.blueAccent,
                                child: Icon(Icons.person, color: Colors.white),
                              ),
                              title: Text(_comments[index]),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
