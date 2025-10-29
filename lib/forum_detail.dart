import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'forum_service.dart';

class ForumDetailPage extends StatefulWidget {
  final String postId;
  final String title;
  final String content;
  final String userId;
  final File? image;

  const ForumDetailPage({
    super.key,
    required this.postId,
    required this.title,
    required this.content,
    required this.userId,
    this.image,
  });

  @override
  State<ForumDetailPage> createState() => _ForumDetailPageState();
}

class _ForumDetailPageState extends State<ForumDetailPage> {
  final TextEditingController _commentController = TextEditingController();
  final ForumService _forumService = ForumService();
  final _auth = FirebaseAuth.instance;

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Komentar tidak boleh kosong')),
      );
      return;
    }

    final uid = _auth.currentUser?.uid ?? 'anon';
    try {
      await _forumService.addComment(
        postId: widget.postId,
        userId: uid,
        content: text,
      );
      _commentController.clear();
      FocusScope.of(context).unfocus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim komentar: $e')),
      );
    }
  }

  Widget _buildCommentItem(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    final content = (data['content'] as String?) ?? '';
    final userId = (data['userId'] as String?) ?? 'anon';
    final tsServer = data['createdAt'] as Timestamp?;
    final tsLocal = data['localCreatedAt'] as Timestamp?;
    final createdAt = (tsServer ?? tsLocal)?.toDate();

    return FutureBuilder<String>(
      future: _forumService.getUserName(userId),
      builder: (context, snap) {
        final displayName =
            (snap.data?.isNotEmpty ?? false) ? snap.data! : userId;
        return Card(
          color: Colors.white,
          elevation: 1,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3D5A80),
                    )),
                const SizedBox(height: 4),
                Text(content),
                if (createdAt != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    createdAt.toString(),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3D5A80),
        elevation: 0,
        title: const Text('Detail Post'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (widget.image != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(widget.image!, fit: BoxFit.cover),
                  ),
                const SizedBox(height: 12),
                Text(
                  widget.content,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
                const Divider(thickness: 1.2, height: 30),

                const Text(
                  "Komentar",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3D5A80),
                  ),
                ),
                const SizedBox(height: 10),

                // ===== Realtime comments dari Firestore (stabil dengan localCreatedAt) =====
                StreamBuilder<QuerySnapshot>(
                  stream: _forumService.getComments(widget.postId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snapshot.hasError) {
                      return Text('Terjadi kesalahan: ${snapshot.error}');
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Text(
                        "Belum ada komentar, jadilah yang pertama!",
                        style: TextStyle(color: Colors.grey),
                      );
                    }

                    final docs = snapshot.data!.docs;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: docs.map(_buildCommentItem).toList());
                  },
                ),

                const SizedBox(height: 80),
              ],
            ),
          ),

          // ===== Input komentar =====
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendComment(),
                    decoration: InputDecoration(
                      hintText: "Tulis komentar...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _sendComment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3D5A80),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
