import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:edu_sign/quiz_page.dart';

// Firestore + Auth
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VideoDetailPage extends StatefulWidget {
  final String title;
  final String videoUrl;
  final String? signLangUrl;
  final String? subtitle;
  final String? videoDocId;

  const VideoDetailPage({
    super.key,
    required this.title,
    required this.videoUrl,
    this.signLangUrl,
    this.subtitle,
    this.videoDocId,
  });

  @override
  State<VideoDetailPage> createState() => _VideoDetailPageState();
}

class _VideoDetailPageState extends State<VideoDetailPage> {
  YoutubePlayerController? _yt;
  VideoPlayerController? _mp4Main;
  VideoPlayerController? _signLang;

  // Timer yang lebih conservative untuk menghindari stutter
  Timer? _syncTimer;
  Timer? _subtitleTimer;
  Timer? _debounceTimer;
  
  // State tracking dengan debouncing
  Duration _lastSyncPosition = Duration.zero;
  Duration _lastSubtitlePosition = Duration.zero;
  bool _isPlaying = false;
  bool _isBuffering = false;
  bool _isSeeking = false;
  
  // Interval yang lebih conservative untuk Android
  static const Duration _syncInterval = Duration(milliseconds: 500);
  static const Duration _subtitleInterval = Duration(milliseconds: 1000);
  static const Duration _syncThreshold = Duration(milliseconds: 1000);
  static const Duration _debounceDelay = Duration(milliseconds: 300);
  
  // Performance tracking
  int _syncFailures = 0;
  static const int _maxSyncFailures = 3;
  
  bool _showSubtitle = true;
  bool _showSignLang = true;

  List<_SrtCue> _cues = [];
  int _lastCueIdx = -1;
  String? _currentSubtitle;

  final TextEditingController _commentController = TextEditingController();
  Comment? _replyingTo;
  final Map<String, String> _nameCache = {};

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Platform detection yang kompatibel
  bool get _isAndroid => Theme.of(context).platform == TargetPlatform.android;
  bool get _isWeb => kIsWeb; // Hanya gunakan kIsWeb
  bool get _isIOS => Theme.of(context).platform == TargetPlatform.iOS;

  // Responsive sizing untuk video bahasa isyarat
  double get _signLangWidth {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (_isWeb) {
      // Web/Chrome: ukuran tetap
      return 140.0;
    } else if (_isAndroid) {
      // Android: responsive berdasarkan screen width
      if (screenWidth < 400) {
        return 100.0; // Small screen
      } else if (screenWidth < 600) {
        return 120.0; // Medium screen
      } else {
        return 140.0; // Large screen
      }
    } else {
      // iOS dan lainnya
      return 130.0;
    }
  }

  double get _signLangHeight {
    // Maintain aspect ratio 4:3 untuk video bahasa isyarat
    return _signLangWidth * 0.75;
  }

  double get _signLangRightMargin {
    final screenWidth = MediaQuery.of(context).size.width;
    if (_isAndroid && screenWidth < 400) {
      return 8.0;
    }
    return 12.0;
  }

  double get _signLangBottomMargin {
    final screenHeight = MediaQuery.of(context).size.height;
    if (_isAndroid && screenHeight < 800) {
      return 8.0;
    }
    return 12.0;
  }

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

  String? get _videoIdForComments {
    return widget.videoDocId?.isNotEmpty == true
        ? widget.videoDocId
        : _extractId(widget.videoUrl);
  }

  @override
  void initState() {
    super.initState();
    _loadSrtFromUrl(widget.subtitle);
    _initializeSignLanguage();
    _initializeMainPlayer();
  }

  Future<void> _initializeSignLanguage() async {
    if ((widget.signLangUrl ?? '').isNotEmpty) {
      try {
        // Low quality untuk bahasa isyarat (hemat memory)
        _signLang = VideoPlayerController.networkUrl(
          Uri.parse(widget.signLangUrl!),
          videoPlayerOptions: VideoPlayerOptions(
            mixWithOthers: true,
            allowBackgroundPlayback: false,
          ),
        );
        
        await _signLang!.initialize();
        
        // Set volume ke 0 dan low quality
        await _signLang!.setVolume(0.0);
        
        // Set looping untuk menghindari re-initialization
        _signLang!.setLooping(true);
        
        if (mounted) setState(() {});
      } catch (e) {
        if (kDebugMode) print('Error initializing sign language video: $e');
        // Fallback: disable sign language jika gagal
        setState(() => _showSignLang = false);
      }
    }
  }

  Future<void> _initializeMainPlayer() async {
    if (_isYouTube) {
      final id = _extractId(widget.videoUrl);
      if (id != null && id.isNotEmpty) {
        _yt = YoutubePlayerController(
          params: YoutubePlayerParams(
            showControls: false,
            showFullscreenButton: false,
            enableCaption: false,
            origin: 'https://www.youtube-nocookie.com',
            // Reduced quality untuk Android
            strictRelatedVideos: false,
            interfaceLanguage: 'id',
          ),
        )
          ..loadVideoById(videoId: id)
          ..listen(_onYoutubeEvent);
      }
    } else {
      try {
        _mp4Main = VideoPlayerController.networkUrl(
          Uri.parse(widget.videoUrl),
          videoPlayerOptions: VideoPlayerOptions(
            mixWithOthers: true,
            allowBackgroundPlayback: false,
          ),
        );
        
        await _mp4Main!.initialize();
        
        _mp4Main!.addListener(_onMp4MainEvent);
        
        if (mounted) setState(() {});
      } catch (e) {
        if (kDebugMode) print('Error initializing main video: $e');
      }
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _subtitleTimer?.cancel();
    _debounceTimer?.cancel();
    _mp4Main?.removeListener(_onMp4MainEvent);
    _mp4Main?.dispose();
    _yt?.close();
    _signLang?.dispose();
    _commentController.dispose();
    super.dispose();
  }

  // ================= Subtitles =================
  Future<void> _loadSrtFromUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final content = utf8.decode(res.bodyBytes);
        _cues = _parseSrt(content);
        _lastCueIdx = -1;
        if (mounted) setState(() {});
      }
    } catch (e) {
      if (kDebugMode) print('Error loading subtitles: $e');
    }
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

      i++; // skip cue index line
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
    
    // Hanya update jika posisi berubah signifikan (lebih conservative)
    if ((pos - _lastSubtitlePosition).inMilliseconds.abs() < 500) return;
    _lastSubtitlePosition = pos;

    String? found;
    int idxFound = -1;

    // Linear search (lebih stabil untuk Android)
    for (int i = 0; i < _cues.length; i++) {
      final cue = _cues[i];
      if (pos >= cue.start && pos <= cue.end) {
        found = cue.text;
        idxFound = i;
        break;
      }
    }

    if (idxFound != _lastCueIdx || _currentSubtitle != found) {
      if (mounted) {
        setState(() {
          _currentSubtitle = found;
          _lastCueIdx = idxFound;
        });
      }
    }
  }

  // ================= Sinkronisasi dengan Debouncing =================
  void _startSyncTimers() {
    // Timer untuk subtitle (sangat jarang update)
    _subtitleTimer?.cancel();
    _subtitleTimer = Timer.periodic(_subtitleInterval, (_) async {
      if (!_isPlaying || _isBuffering || _isSeeking) return;
      
      final pos = await _getCurrentPosition();
      if (pos != null) {
        _updateSubtitle(pos);
      }
    });

    // Timer untuk sinkronisasi bahasa isyarat (sangat conservative)
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_syncInterval, (_) async {
      if (!_isPlaying || _isBuffering || !_showSignLang || _isSeeking) return;
      
      // Reset sync failures jika berhasil
      if (_syncFailures > 0) _syncFailures = 0;
      
      await _syncSignLanguage();
    });
  }

  void _stopSyncTimers() {
    _syncTimer?.cancel();
    _syncTimer = null;
    _subtitleTimer?.cancel();
    _subtitleTimer = null;
    _debounceTimer?.cancel();
  }

  Future<Duration?> _getCurrentPosition() async {
    try {
      if (_isYouTube && _yt != null) {
        final seconds = await _yt!.currentTime;
        return Duration(milliseconds: (seconds * 1000).round());
      } else if (_mp4Main != null && _mp4Main!.value.isInitialized) {
        return _mp4Main!.value.position;
      }
    } catch (e) {
      if (kDebugMode) print('Error getting current position: $e');
      _syncFailures++;
    }
    return null;
  }

  Future<void> _syncSignLanguage() async {
    if (_signLang == null || !_signLang!.value.isInitialized) return;
    
    // Jika terlalu banyak failures, disable sementara
    if (_syncFailures >= _maxSyncFailures) {
      if (kDebugMode) print('Too many sync failures, temporarily disabling sync');
      _stopSyncTimers();
      // Restart setelah 5 detik
      Future.delayed(const Duration(seconds: 5), () {
        if (_isPlaying && !_isBuffering) {
          _syncFailures = 0;
          _startSyncTimers();
        }
      });
      return;
    }

    try {
      final mainPos = await _getCurrentPosition();
      if (mainPos == null) return;

      final signPos = _signLang!.value.position;
      final diff = (mainPos - signPos).inMilliseconds.abs();

      // Hanya sinkronkan jika perbedaan sangat signifikan
      if (diff > _syncThreshold.inMilliseconds) {
        _isSeeking = true;
        await _signLang!.seekTo(mainPos);
        _lastSyncPosition = mainPos;
        
        // Reset seeking flag setelah seek selesai
        Future.delayed(const Duration(milliseconds: 500), () {
          _isSeeking = false;
        });
      }

      // Pastikan status play sesuai (dengan debouncing)
      if (_isPlaying && !_signLang!.value.isPlaying) {
        _debounceTimer?.cancel();
        _debounceTimer = Timer(_debounceDelay, () async {
          if (_isPlaying && !_signLang!.value.isPlaying) {
            await _signLang!.play();
          }
        });
      }
    } catch (e) {
      if (kDebugMode) print('Error syncing sign language: $e');
      _syncFailures++;
    }
  }

  // ================= Event Handlers =================
  void _onYoutubeEvent(YoutubePlayerValue value) {
    final wasPlaying = _isPlaying;
    _isPlaying = value.playerState == PlayerState.playing;
    _isBuffering = value.playerState == PlayerState.buffering;

    if (_isPlaying && !wasPlaying) {
      _startSyncTimers();
      if (_showSignLang && _signLang != null) {
        _signLang!.play();
      }
    } else if (!_isPlaying && wasPlaying) {
      _stopSyncTimers();
      _signLang?.pause();
      
      if (value.playerState == PlayerState.ended) {
        _signLang?.seekTo(Duration.zero);
        _updateSubtitle(Duration.zero);
      }
    }
  }

  void _onMp4MainEvent() {
    if (_mp4Main == null) return;
    final value = _mp4Main!.value;
    
    final wasPlaying = _isPlaying;
    _isPlaying = value.isPlaying && !value.isBuffering;
    _isBuffering = value.isBuffering;

    if (_isPlaying && !wasPlaying) {
      _startSyncTimers();
      if (_showSignLang && _signLang != null) {
        _signLang!.play();
      }
    } else if (!_isPlaying && wasPlaying) {
      _stopSyncTimers();
      _signLang?.pause();
      
      if (value.position >= value.duration && value.duration != Duration.zero) {
        _signLang?.seekTo(Duration.zero);
        _updateSubtitle(Duration.zero);
      }
    }
  }

  // ================= Toggle Functions =================
  Future<void> _toggleSignLang() async {
    final newValue = !_showSignLang;
    setState(() => _showSignLang = newValue);

    if (!_showSignLang) {
      _signLang?.pause();
      return;
    }

    // Sinkronkan ulang saat ditampilkan (dengan delay)
    Future.delayed(const Duration(milliseconds: 500), () async {
      if (_signLang != null && _signLang!.value.isInitialized) {
        final pos = await _getCurrentPosition();
        if (pos != null) {
          _isSeeking = true;
          await _signLang!.seekTo(pos);
          Future.delayed(const Duration(milliseconds: 500), () {
            _isSeeking = false;
          });
        }
        
        if (_isPlaying) {
          _signLang?.play();
        }
      }
    });
  }

  // ================= UI dengan Responsive Sizing =================
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

      // Overlay Bahasa Isyarat dengan responsive sizing
      if (_showSignLang && _signLang != null && _signLang!.value.isInitialized)
        Positioned(
          right: _signLangRightMargin,
          bottom: _signLangBottomMargin,
          width: _signLangWidth,
          height: _signLangHeight,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: _signLang!.value.aspectRatio,
                child: VideoPlayer(_signLang!),
              ),
            ),
          ),
        ),

      // Subtitle dengan responsive positioning
      if (_showSubtitle && (_currentSubtitle?.isNotEmpty ?? false))
        Positioned(
          left: 12,
          right: _signLangWidth + 24, // Beri ruang untuk video bahasa isyarat
          bottom: _isAndroid ? 4 : 8,
          child: Center(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: _isAndroid ? 8 : 12, 
                vertical: _isAndroid ? 4 : 6
              ),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _currentSubtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white, 
                  fontSize: _isAndroid ? 14 : 16
                ),
              ),
            ),
          ),
        ),
    ]);
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

              // Status indicator untuk debugging (hanya di debug mode)
              if (kDebugMode && _syncFailures > 0)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  color: Colors.orange.withOpacity(0.8),
                  child: Text(
                    'Sinkronisasi bermasalah ($_syncFailures/$_maxSyncFailures) - Platform: ${_isAndroid ? "Android" : _isWeb ? "Web" : "Other"}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Tombol toggle dengan responsive spacing
              Padding(
                padding: EdgeInsets.only(top: 4.0, bottom: _isAndroid ? 4.0 : 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => setState(() => _showSubtitle = !_showSubtitle),
                      child: Text(_showSubtitle ? 'Hide Subtitle' : 'Show Subtitle'),
                    ),
                    SizedBox(width: _isAndroid ? 8 : 12),
                    TextButton(
                      onPressed: _toggleSignLang,
                      child: Text(_showSignLang ? 'Hide Bahasa Isyarat' : 'Show Bahasa Isyarat'),
                    ),
                  ],
                ),
              ),

              // Quiz button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.quiz),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3D5A80),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      final idForQuiz = widget.videoDocId;
                      if (idForQuiz == null || idForQuiz.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('ID video tidak tersedia')),
                        );
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizPage(initialVideoId: idForQuiz),
                        ),
                      );
                    },
                    label: const Text(
                      'Mulai Kuis untuk Video Ini',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),

              // Komentar section (tetap sama)
              Expanded(
                child: Container(
                  color: const Color(0xFFFAF9F6),
                  child: (_commentStream == null)
                      ? const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: Text(
                            "Video ID tidak ditemukan. Komentar tidak dapat dimuat.",
                            style: TextStyle(color: Color(0xFF293241)),
                          ),
                        )
                      : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: _commentStream,
                          builder: (context, snap) {
                            if (snap.connectionState == ConnectionState.waiting) {
                              return const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            if (snap.hasError) {
                              return Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text('Gagal memuat komentar: ${snap.error}',
                                    style: const TextStyle(color: Color(0xFF293241))),
                              );
                            }

                            final docs = snap.data?.docs ?? [];
                            if (docs.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.only(top: 12),
                                child: Text(
                                  "Belum ada komentar. Jadilah yang pertama!",
                                  style: TextStyle(color: Color(0xFF293241)),
                                ),
                              );
                            }

                            final uids = <String>{
                              for (final d in docs) (d.data()['userId'] ?? 'guru').toString(),
                            }.toList();

                            return FutureBuilder<Map<String, String>>(
                              future: _getNamesForUids(uids),
                              builder: (context, nameSnap) {
                                final nameMap = nameSnap.data ?? const <String, String>{};

                                return ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
                                  itemCount: docs.length + 1,
                                  separatorBuilder: (_, __) => const Divider(thickness: 1, color: Color(0xFF293241)),
                                  itemBuilder: (context, index) {
                                    if (index == 0) {
                                      return const Padding(
                                        padding: EdgeInsets.only(bottom: 8.0),
                                        child: Text(
                                          "Komentar",
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF293241),
                                          ),
                                        ),
                                      );
                                    }

                                    final d = docs[index - 1];
                                    final data = d.data();
                                    final text = (data['content'] ?? '').toString();
                                    final userId = (data['userId'] ?? 'guru').toString();

                                    final displayName = nameMap[userId] ?? _nameCache[userId] ?? userId;

                                    return _buildCommentCard(
                                      name: displayName.isNotEmpty ? displayName : 'Guru',
                                      avatarUrl: "https://i.pravatar.cc/150?u=$userId",
                                      text: text,
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                ),
              ),
            ],
          ),

          // Reply UI dan input komentar (tetap sama)
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
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, -2))],
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
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) async {
                          final text = _commentController.text;
                          await _sendCommentToFirestore(text);
                        },
                        decoration: InputDecoration(
                          hintText: "Tulis komentar...",
                          hintStyle: const TextStyle(color: Color(0xFF293241)),
                          filled: true,
                          fillColor: const Color(0xFFE0FBFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF293241)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Color(0xFFE0FBFC)),
                      onPressed: () async {
                        final text = _commentController.text;
                        await _sendCommentToFirestore(text);
                      },
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

  // ================= Komentar Functions (tetap sama) =================
  Stream<QuerySnapshot<Map<String, dynamic>>>? get _commentStream {
    final vid = _videoIdForComments;
    if (vid == null || vid.isEmpty) return null;
    final col = FirebaseFirestore.instance.collection('comments');
    return col
        .where('videoId', isEqualTo: vid)
        .orderBy('localCreatedAt', descending: true)
        .snapshots();
  }

  Future<void> _sendCommentToFirestore(String text) async {
    final vid = _videoIdForComments;
    if (vid == null || vid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video ID tidak ditemukan untuk komentar.')),
      );
      return;
    }
    final content = text.trim();
    if (content.isEmpty) return;

    final String uid = _auth.currentUser?.uid ?? 'guru';

    try {
      await FirebaseFirestore.instance.collection('comments').add({
        'content': content,
        'videoId': vid,
        'userId': uid,
        'createdAt': FieldValue.serverTimestamp(),
        'localCreatedAt': DateTime.now(),
      });
      _commentController.clear();
      setState(() => _replyingTo = null);
      FocusScope.of(context).unfocus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim komentar: $e')),
      );
    }
  }

  Future<Map<String, String>> _getNamesForUids(List<String> uids) async {
    final result = <String, String>{};
    final missing = <String>[];

    for (final uid in uids) {
      if (_nameCache.containsKey(uid)) {
        result[uid] = _nameCache[uid]!;
      } else {
        missing.add(uid);
      }
    }
    if (missing.isEmpty) return result;

    for (var i = 0; i < missing.length; i += 10) {
      final chunk = missing.sublist(i, (i + 10).clamp(0, missing.length));
      try {
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        for (final doc in snap.docs) {
          final data = doc.data();
          final name = (data['name'] as String?) ?? (data['displayName'] as String?) ?? doc.id;
          _nameCache[doc.id] = name;
          result[doc.id] = name;
        }

        final foundIds = snap.docs.map((d) => d.id).toSet();
        for (final uid in chunk) {
          if (!foundIds.contains(uid)) {
            _nameCache[uid] = 'Guru';
            result[uid] = 'Guru';
          }
        }
      } catch (e) {
        for (final uid in chunk) {
          _nameCache[uid] = 'Guru';
          result[uid] = 'Guru';
        }
      }
    }
    return result;
  }

  Widget _buildCommentCard({
    required String name,
    required String avatarUrl,
    required String text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(thickness: 1, color: Color(0xFF293241)),
        Row(
          children: [
            CircleAvatar(backgroundImage: NetworkImage(avatarUrl), radius: 18),
            const SizedBox(width: 8),
            Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF293241)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 42.0),
          child: Text(text, style: const TextStyle(color: Color(0xFF293241))),
        ),
        const Divider(thickness: 1, color: Color(0xFF293241)),
      ],
    );
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