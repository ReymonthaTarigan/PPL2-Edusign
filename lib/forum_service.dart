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
  // Gunakan localCreatedAt agar stream/orderBy stabil sebelum serverTimestamp terisi
  Future<void> addComment({
    required String postId,
    required String userId,
    required String content,
  }) async {
    await _firestore.collection('forumComments').add({
      'postId': postId,
      'userId': userId,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(), // server time (mungkin null sesaat)
      'localCreatedAt': DateTime.now(),          // client time (langsung terisi)
    });
  }

  // 🔍 Ambil semua postingan forum (urut terbaru)
  Stream<QuerySnapshot> getAllPosts() {
    return _firestore
        .collection('forumPost')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // 🔍 Ambil komentar berdasarkan postId, urut lama→baru dengan localCreatedAt
  Stream<QuerySnapshot> getComments(String postId) {
    return _firestore
        .collection('forumComments')
        .where('postId', isEqualTo: postId)
        .orderBy('localCreatedAt', descending: false)
        .snapshots();
  }

  // 🔍 Ambil nama user dari collection users (opsional)
  Future<String> getUserName(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      return (doc.data()?['name'] as String?) ?? 'Anonim';
    }
    return 'Anonim';
  }
}
