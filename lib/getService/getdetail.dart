import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class VideoDetailPage extends StatefulWidget {
  final String title;
  final String videoUrl;      // YouTube URL atau MP4 langsung
  final String? signLangUrl;  // MP4 interpreter
  final String? subtitle;     // URL .srt
  

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
  YoutubePlayerController? _yt;      // player utama jika YouTube
  VideoPlayerController? _mp4Main;   // player utama jika MP4
  VideoPlayerController? _signLang;  // overlay interpreter

  // Ticker untuk polling posisi YouTube saat playing
  Timer? _ytTicker;
  static const _tick = Duration(milliseconds: 250);

  bool _showSubtitle = true;

  // ==== Subtitle SRT ====
  List<_SrtCue> _cues = [];
  int _lastCueIdx = -1;
  String? _currentSubtitle;

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

    if ((widget.signLangUrl ?? '').isNotEmpty) {
      _signLang = VideoPlayerController.networkUrl(Uri.parse(widget.signLangUrl!))
        ..initialize().then((_) => setState(() {}));
    }

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

  // ---------- SUBTITLE ----------
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
      i++; // skip nomor cue bila ada

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

    // Cari cue aktif; optimasi mulai dari last index
    int startIdx = (_lastCueIdx >= 0 && _lastCueIdx < _cues.length) ? _lastCueIdx : 0;
    String? found;
    int idxFound = -1;

    // cek current dulu
    final c0 = _cues[startIdx];
    if (pos >= c0.start && pos <= c0.end) {
      found = c0.text;
      idxFound = startIdx;
    } else {
      // cari searah
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

  // ---------- YOUTUBE ----------
  void _startYtTicker() {
    _ytTicker ??= Timer.periodic(_tick, (_) async {
      try {
        if (_yt == null) return;
        final seconds = await _yt!.currentTime; // Future<double>?
        if (seconds != null) {
          final pos = Duration(milliseconds: (seconds * 1000).round());
          _updateSubtitle(pos);

          // jaga sinkron interpreter (opsional)
          if (_signLang != null && _signLang!.value.isInitialized) {
            final diff = (pos - _signLang!.value.position).inMilliseconds.abs();
            if (diff > 500) _signLang!.seekTo(pos);
          }
        }
      } catch (_) {}
    });
  }

  void _stopYtTicker() {
    _ytTicker?.cancel();
    _ytTicker = null;
  }

  Future<void> _onYoutubeEvent(YoutubePlayerValue v) async {
    // start/stop ticker berdasar state
    if (v.playerState == PlayerState.playing) {
      _startYtTicker();
      _signLang?.play();
    } else if (v.playerState == PlayerState.ended) {
      _stopYtTicker();
      _signLang?..pause()..seekTo(Duration.zero);
      _updateSubtitle(const Duration(days: 0)); // paksa evaluasi ulang (kosong)
    } else {
      // paused/buffering/cued/unknown
      _stopYtTicker();
      _signLang?.pause();
    }
  }

  // ---------- MP4 ----------
  void _onMp4MainEvent() {
    if (_mp4Main == null) return;
    final main = _mp4Main!.value;

    // update subtitle kontinyu
    _updateSubtitle(main.position);

    if (_signLang != null && _signLang!.value.isInitialized) {
      if (main.isBuffering || !main.isPlaying) {
        _signLang!.pause();
        if (!main.isPlaying &&
            main.position >= main.duration &&
            main.duration != Duration.zero) {
          _signLang!.seekTo(Duration.zero);
        }
      } else {
        _signLang!.play();
        final diff = (main.position - _signLang!.value.position).inMilliseconds.abs();
        if (diff > 500) _signLang!.seekTo(main.position);
      }
    }
  }

  @override
  void dispose() {
    _stopYtTicker();
    _yt?.close();
    _mp4Main?.removeListener(_onMp4MainEvent);
    _mp4Main?.dispose();
    _signLang?.dispose();
    super.dispose();
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

    return Stack(
      children: [
        Positioned.fill(child: mainPlayer),

        // Interpreter overlay (kanan-bawah)
        if (_signLang != null && _signLang!.value.isInitialized)
          Positioned(
            right: 12,
            bottom: 12,
            width: 140,
            height: 180,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: _signLang!.value.aspectRatio,
                child: VideoPlayer(_signLang!),
              ),
            ),
          ),

        // Subtitle overlay (tengah-bawah)
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.35,
                    shadows: [Shadow(blurRadius: 2, color: Colors.black)],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title), backgroundColor: Colors.blue[900]),
      body: Column(
        children: [
          AspectRatio(aspectRatio: 16 / 9, child: _buildPlayerArea()),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() => _showSubtitle = !_showSubtitle),
            child: Text(
              _showSubtitle ? 'Hide Subtitle' : 'Show Subtitle',
              style: const TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }
}

// ===== Model sederhana untuk cue SRT =====
class _SrtCue {
  final Duration start;
  final Duration end;
  final String text;
  _SrtCue({required this.start, required this.end, required this.text});
}
