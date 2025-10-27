//comment.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class CommentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 隼 Menambahkan komentar baru untuk video
  Future<void> addComment({
    required String videoId,
    required String userId,
    required String content,
  }) async {
    await _firestore.collection('comments').add({
      'videoId': videoId,
      'userId': userId,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// 隼 Menambahkan balasan untuk komentar tertentu
  Future<void> addReply({
    required String commentId,
    required String userId,
    required String content,
  }) async {
    await _firestore.collection('commentReplies').add({
      'commentId': commentId,
      'userId': userId,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// 隼 Mengambil semua komentar untuk video tertentu (urut waktu)
  Stream<List<Map<String, dynamic>>> getComments(String videoId) {
    return _firestore
        .collection('comments')
        .where('videoId', isEqualTo: videoId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .asyncMap((query) async {
      final List<Map<String, dynamic>> comments = [];

      for (final doc in query.docs) {
        final commentData = doc.data();
        final userId = commentData['userId'];
        String? userName;

        try {
          final userDoc = await _firestore.collection('users').doc(userId).get();
          userName = userDoc.data()?['name'] ?? 'Anonim';
        } catch (_) {
          userName = 'Anonim';
        }

        // 隼 Ambil balasan
        // ! PENTING: Kueri ini MEMBUTUHKAN INDEKS KOMPOSIT di Firestore
        // ! Collection: 'commentReplies', Fields: [commentId (ASC), createdAt (DESC)]
        final repliesSnap = await _firestore
            .collection('commentReplies')
            .where('commentId', isEqualTo: doc.id)
            .orderBy('createdAt', descending: false)
            .get();

        final replies = <Map<String, dynamic>>[]; // Ubah ke List<Map<...>>

        for (final r in repliesSnap.docs) { // Lakukan loop untuk ambil nama pengguna
          final replyData = r.data();
          final replyUserId = replyData['userId'];
          String? replyUserName;

          try {
            final userDoc = await _firestore.collection('users').doc(replyUserId).get();
            replyUserName = userDoc.data()?['name'] ?? 'Anonim';
          } catch (_) {
            replyUserName = 'Anonim';
          }

          replies.add({
            'id': r.id,
            'name': replyUserName ?? 'Anonim', // <-- GUNAKAN NAMA PENGGUNA YANG DIAMBIL
            'content': replyData['content'],
            'createdAt': replyData['createdAt'],
          });
        }

        comments.add({
          'id': doc.id,
          'name': userName ?? 'Anonim',
          'content': commentData['content'],
          'createdAt': commentData['createdAt'],
          'replies': replies,
        });
      }

      return comments;
    });
  }
}