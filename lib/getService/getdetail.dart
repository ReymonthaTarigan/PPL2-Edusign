import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

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
  YoutubePlayerController? _yt;
  VideoPlayerController? _mp4Main;
  Timer? _ytTicker;
  static const _tick = Duration(milliseconds: 250);
  bool _showSubtitle = true;

  List<_SrtCue> _cues = [];
  int _lastCueIdx = -1;
  String? _currentSubtitle;

  final List<Comment> _comments = [
    Comment(
      name: "Rani Kusuma",
      avatarUrl: "https://i.pravatar.cc/150?img=3",
      text: "Videonya sangat informatif!",
      replies: [
        Comment(
          name: "Bima Setiawan",
          avatarUrl: "https://i.pravatar.cc/150?img=12",
          text: "Setuju banget, apalagi bagian penjelasan terakhir.",
        ),
      ],
    ),
  ];

  final TextEditingController _commentController = TextEditingController();
  Comment? _replyingTo;
  final Map<Comment, bool> _showReplies = {};

  bool get _isYouTube {
    final u = Uri.tryParse(widget.videoUrl);
    if (u == null) return false;
    return u.host.contains('youtube.com') || u.host.contains('youtu.be');
  }

  String? _extractId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    }
    if (uri.host.contains('youtube.com')) {
      return uri.queryParameters['v'];
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadSrtFromUrl(widget.subtitle);

    if (_isYouTube) {
      final id = _extractId(widget.videoUrl);
      if (id != null && id.isNotEmpty) {
        _yt = YoutubePlayerController(
          params: const YoutubePlayerParams(
            showControls: true,
            showFullscreenButton: true,
            enableCaption: true,
          ),
        )
          ..loadVideoById(videoId: id)
          ..listen(_onYoutubeEvent);
      }
    } else {
      _mp4Main = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
        ..initialize().then((_) {
          setState(() {});
          _mp4Main!.addListener(_onMp4MainEvent);
        });
    }
  }

  Future<void> _loadSrtFromUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final content = utf8.decode(res.bodyBytes);
        _cues = _parseSrt(content);
        _lastCueIdx = -1;
        setState(() {});
      }
    } catch (_) {}
  }

  List<_SrtCue> _parseSrt(String srt) {
    final lines = srt.replaceAll('\r\n', '\n').split('\n');
    final cues = <_SrtCue>[];
    int i = 0;

    Duration? toDuration(String t) {
      final parts = t.split(RegExp('[:,]'));
      if (parts.length != 4) return null;
      return Duration(
        hours: int.tryParse(parts[0]) ?? 0,
        minutes: int.tryParse(parts[1]) ?? 0,
        seconds: int.tryParse(parts[2]) ?? 0,
        milliseconds: int.tryParse(parts[3]) ?? 0,
      );
    }

    while (i < lines.length) {
      while (i < lines.length && lines[i].trim().isEmpty) i++;
      if (i >= lines.length) break;
      i++;
      if (i >= lines.length) break;
      final timeLine = lines[i].trim();
      final m = RegExp(
        r'(\d{2}:\d{2}:\d{2},\d{3})\s*-->\s*(\d{2}:\d{2}:\d{2},\d{3})',
      ).firstMatch(timeLine);
      i++;
      if (m == null) continue;

      final start = toDuration(m.group(1)!);
      final end = toDuration(m.group(2)!);
      if (start == null || end == null) continue;

      final textLines = <String>[];
      while (i < lines.length && lines[i].trim().isNotEmpty) {
        textLines.add(lines[i]);
        i++;
      }
      cues.add(_SrtCue(start: start, end: end, text: textLines.join('\n').trim()));
    }
    return cues;
  }

  void _updateSubtitle(Duration pos) {
    if (_cues.isEmpty) return;
    int startIdx = (_lastCueIdx >= 0 && _lastCueIdx < _cues.length) ? _lastCueIdx : 0;
    String? found;
    int idxFound = -1;

    final c0 = _cues[startIdx];
    if (pos >= c0.start && pos <= c0.end) {
      found = c0.text;
      idxFound = startIdx;
    } else {
      for (int k = 0; k < _cues.length; k++) {
        final i = (startIdx + k) % _cues.length;
        final c = _cues[i];
        if (pos >= c.start && pos <= c.end) {
          found = c.text;
          idxFound = i;
          break;
        }
      }
    }

    if (idxFound == -1) {
      if (_currentSubtitle != null) {
        setState(() {
          _currentSubtitle = null;
          _lastCueIdx = -1;
        });
      }
    } else {
      if (_currentSubtitle != found || _lastCueIdx != idxFound) {
        setState(() {
          _currentSubtitle = found;
          _lastCueIdx = idxFound;
        });
      }
    }
  }

  void _onYoutubeEvent(YoutubePlayerValue v) {
    if (v.playerState == PlayerState.playing) {
      _ytTicker ??= Timer.periodic(_tick, (_) async {
        final seconds = await _yt!.currentTime;
        if (seconds != null) {
          final pos = Duration(milliseconds: (seconds * 1000).round());
          _updateSubtitle(pos);
        }
      });
    } else {
      _ytTicker?.cancel();
      _ytTicker = null;
    }
  }

  void _onMp4MainEvent() {
    if (_mp4Main == null) return;
    final main = _mp4Main!.value;
    _updateSubtitle(main.position);
  }

  void _addComment(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      if (_replyingTo != null) {
        _replyingTo!.replies.add(
          Comment(
            name: "Kamu",
            avatarUrl: "https://i.pravatar.cc/150?img=20",
            text: text,
          ),
        );
        _showReplies[_replyingTo!] = true;
        _replyingTo = null;
      } else {
        _comments.add(Comment(
          name: "Kamu",
          avatarUrl: "https://i.pravatar.cc/150?img=20",
          text: text,
        ));
      }
      _commentController.clear();
    });
  }

  Widget _buildComment(Comment comment) {
    final isExpanded = _showReplies[comment] ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(thickness: 1, color: Color(0xFF293241)),
        Row(children: [
          CircleAvatar(backgroundImage: NetworkImage(comment.avatarUrl), radius: 18),
          const SizedBox(width: 8),
          Text(comment.name,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF293241))),
        ]),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 42.0),
          child: Text(comment.text, style: const TextStyle(color: Color(0xFF293241))),
        ),
        Row(
          children: [
            TextButton(
              onPressed: () => setState(() => _replyingTo = comment),
              child: const Text("Balas", style: TextStyle(color: Color(0xFF293241))),
            ),
            if (comment.replies.isNotEmpty)
              TextButton(
                onPressed: () => setState(() => _showReplies[comment] = !isExpanded),
                child: Text(
                  isExpanded ? "Sembunyikan Balasan" : "Lihat ${comment.replies.length} Balasan",
                  style: const TextStyle(color: Color(0xFF293241)),
                ),
              ),
          ],
        ),
        if (isExpanded)
          Container(
            margin: const EdgeInsets.only(left: 42, bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE0FBFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: comment.replies.map((r) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(backgroundImage: NetworkImage(r.avatarUrl), radius: 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF293241))),
                            Text(r.text, style: const TextStyle(color: Color(0xFF293241))),
                          ],
                        ),
                      )
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        const Divider(thickness: 1, color: Color(0xFF293241)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title), backgroundColor: const Color(0xFF3D5A80)),
      body: Stack(
        children: [
          Column(
            children: [
              AspectRatio(aspectRatio: 16 / 9, child: _buildPlayerArea()),
              TextButton(
                onPressed: () => setState(() => _showSubtitle = !_showSubtitle),
                child: Text(_showSubtitle ? 'Hide Subtitle' : 'Show Subtitle'),
              ),
              Expanded(
                child: Container(
                  color: const Color(0xFFFAF9F6),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
                    children: [
                      const Text(
                        "Komentar",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF293241),
                        ),
                      ),
                      for (var comment in _comments) _buildComment(comment),
                    ],
                  ),
                ),
              ),
            ],
          ),

          if (_replyingTo != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 120,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF98C1D9),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, -2))
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Membalas: ${_replyingTo!.name}",
                        style: const TextStyle(color: Color(0xFF293241)),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF293241)),
                      onPressed: () => setState(() => _replyingTo = null),
                    ),
                  ],
                ),
              ),
            ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: const Color(0xFF3D5A80),
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 20),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: "Tulis komentar...",
                          hintStyle: const TextStyle(color: Color(0xFF293241)),
                          filled: true,
                          fillColor: const Color(0xFFE0FBFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF293241)),
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Color(0xFFE0FBFC)),
                      onPressed: () => _addComment(_commentController.text),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerArea() {
    final Widget mainPlayer = _isYouTube
        ? (_yt == null
            ? const Center(child: Text('Link YouTube tidak valid.'))
            : YoutubePlayer(controller: _yt!))
        : (_mp4Main == null || !_mp4Main!.value.isInitialized)
            ? const Center(child: CircularProgressIndicator())
            : AspectRatio(
                aspectRatio: _mp4Main!.value.aspectRatio,
                child: VideoPlayer(_mp4Main!),
              );
    return Stack(children: [
      Positioned.fill(child: mainPlayer),
      if (_showSubtitle && (_currentSubtitle?.isNotEmpty ?? false))
        Positioned(
          left: 12,
          right: 12,
          bottom: 8,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _currentSubtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ),
    ]);
  }
}

class _SrtCue {
  final Duration start;
  final Duration end;
  final String text;
  _SrtCue({required this.start, required this.end, required this.text});
}

class Comment {
  final String name;
  final String avatarUrl;
  final String text;
  final List<Comment> replies;

  Comment({
    required this.name,
    required this.avatarUrl,
    required this.text,
    List<Comment>? replies,
  }) : replies = replies ?? [];
}