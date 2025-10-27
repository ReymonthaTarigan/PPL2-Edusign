// lib/services/forum_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ForumService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 📝 Tambah postingan baru
  Future<void> addPost({
    required String title,
    required String content,
    required String userId,
  }) async {
    await _firestore.collection('forumPost').add({
      'title': title,
      'content': content,
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // 💬 Tambah komentar pada postingan
  Future<void> addComment({
    required String postId,
    required String userId,
    required String content,
  }) async {
    await _firestore.collection('forumComments').add({
      'postId': postId,
      'userId': userId,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // 🔍 Ambil semua postingan forum (urut dari terbaru)
  Stream<QuerySnapshot> getAllPosts() {
    return _firestore
        .collection('forumPost')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // 🔍 Ambil semua komentar berdasarkan postId
  Stream<QuerySnapshot> getComments(String postId) {
    return _firestore
        .collection('forumComments')
        .where('postId', isEqualTo: postId)
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  // 🔍 Ambil nama user berdasarkan userId (dari collection users)
  Future<String> getUserName(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      return doc['name'] ?? 'Anonim';
    }
    return 'Anonim';
  }
}
