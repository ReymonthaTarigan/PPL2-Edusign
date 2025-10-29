import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
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

  /// id dokumen koleksi `videos` (doc.id) — dipakai untuk kuis & fallback videoId komentar
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
  Timer? _ytTicker;
  static const _tick = Duration(milliseconds: 250);
  bool _showSubtitle = true;

  List<_SrtCue> _cues = [];
  int _lastCueIdx = -1;
  String? _currentSubtitle;

  // ===== Komentar =====
  final TextEditingController _commentController = TextEditingController();
  Comment? _replyingTo;
  final Map<String, String> _nameCache = {}; // uid -> name cache

  // ===== Auth =====
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

  /// videoId untuk komentar:
  /// - Prioritas: doc.id dari koleksi `videos`
  /// - Fallback: id YouTube dari url
  String? get _videoIdForComments {
    return widget.videoDocId?.isNotEmpty == true
        ? widget.videoDocId
        : _extractId(widget.videoUrl);
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

  @override
  void dispose() {
    _ytTicker?.cancel();
    _mp4Main?.dispose();
    _yt?.close();
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
        final pos = Duration(milliseconds: (seconds * 1000).round());
        _updateSubtitle(pos);
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

  // ================= Komentar (Firestore) =================

  /// Stream komentar — where(videoId) + orderBy(localCreatedAt desc)
  Stream<QuerySnapshot<Map<String, dynamic>>>? get _commentStream {
    final vid = _videoIdForComments;
    if (vid == null || vid.isEmpty) return null;
    final col = FirebaseFirestore.instance.collection('comments');
    return col
        .where('videoId', isEqualTo: vid)
        .orderBy('localCreatedAt', descending: true)
        .snapshots();
  }

  /// Kirim komentar baru (userId = uid login)
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

  // ====== Prefetch nama user mirip forum_service.getUserName, tapi batch ======
  Future<Map<String, String>> _getNamesForUids(List<String> uids) async {
    // Gunakan cache lebih dulu
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

    // Firestore whereIn maksimal 10 item per query → chunk
    for (var i = 0; i < missing.length; i += 10) {
      final chunk = missing.sublist(i, (i + 10).clamp(0, missing.length));
      try {
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        for (final doc in snap.docs) {
          final data = doc.data();
          final name = (data['name'] as String?) ??
              (data['displayName'] as String?) ??
              doc.id; // fallback uid
          _nameCache[doc.id] = name;
          result[doc.id] = name;
        }

        // Jika ada uid yang tidak ada dokumennya, isi "Guru" biar nggak query ulang
        final foundIds = snap.docs.map((d) => d.id).toSet();
        for (final uid in chunk) {
          if (!foundIds.contains(uid)) {
            _nameCache[uid] = 'Guru';
            result[uid] = 'Guru';
          }
        }
      } catch (e) {
        // Jika error (misal rules), jangan crash – isi fallback
        for (final uid in chunk) {
          _nameCache[uid] = 'Guru';
          result[uid] = 'Guru';
        }
      }
    }
    return result;
  }

  // ================= UI =================

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

              // ===== Komentar (Realtime) =====
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

                            // Kumpulkan semua uid unik lalu prefetch namanya (batch)
                            final uids = <String>{
                              for (final d in docs)
                                (d.data()['userId'] ?? 'guru').toString(),
                            }.toList();

                            return FutureBuilder<Map<String, String>>(
                              future: _getNamesForUids(uids),
                              builder: (context, nameSnap) {
                                final nameMap = nameSnap.data ?? const <String, String>{};

                                return ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
                                  itemCount: docs.length + 1,
                                  separatorBuilder: (_, __) =>
                                      const Divider(thickness: 1, color: Color(0xFF293241)),
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

                                    // Ambil nama dari map/cached
                                    final displayName = nameMap[userId] ??
                                        _nameCache[userId] ??
                                        userId; // sementara pakai uid sampai future resolve

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

          // Input komentar
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
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
