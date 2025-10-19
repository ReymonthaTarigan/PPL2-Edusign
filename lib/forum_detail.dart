import 'dart:io';
import 'package:flutter/material.dart';

class ForumDetailPage extends StatefulWidget {
  final String title;
  final String message;
  final File? image;

  const ForumDetailPage({
    super.key,
    required this.title,
    required this.message,
    this.image,
  });

  @override
  State<ForumDetailPage> createState() => _ForumDetailPageState();
}

class _ForumDetailPageState extends State<ForumDetailPage> {
  final TextEditingController _commentController = TextEditingController();

  // contoh sigma
  List<Map<String, dynamic>> comments = [
    {
      "user": "Rafi",
      "text": "Wah topiknya menarik banget!",
      "replies": [
        {"user": "Dina", "text": "Setuju, aku juga penasaran sama pendapat lain!"}
      ]
    },
  ];

  String? replyingTo;

  void addComment({String? replyTo}) {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      if (replyTo == null) {
        comments.add({"user": "You", "text": text, "replies": []});
      } else {
        final comment = comments.firstWhere((c) => c["user"] == replyTo);
        comment["replies"].add({"user": "You", "text": text});
      }
      _commentController.clear();
      replyingTo = null;
    });
  }

  Widget buildComment(Map<String, dynamic> comment) {
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
            Text(comment["user"],
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Color(0xFF3D5A80))),
            const SizedBox(height: 4),
            Text(comment["text"]),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                setState(() {
                  replyingTo = comment["user"];
                });
              },
              child: const Text(
                "Balas",
                style: TextStyle(color: Colors.blue, fontSize: 14),
              ),
            ),
            const SizedBox(height: 6),

            if (comment["replies"] != null && comment["replies"].isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Column(
                  children: comment["replies"]
                      .map<Widget>(
                        (r) => Card(
                          color: const Color(0xFFF1F1F1),
                          elevation: 0,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r["user"],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87)),
                                const SizedBox(height: 3),
                                Text(r["text"]),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3D5A80),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (widget.image != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(widget.image!, fit: BoxFit.cover),
                  ),
                const SizedBox(height: 12),
                Text(
                  widget.message,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
                const Divider(thickness: 1.2, height: 30),

                const Text(
                  "Komentar",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3D5A80)),
                ),
                const SizedBox(height: 10),
                if (comments.isEmpty)
                  const Text("Belum ada komentar, jadilah yang pertama!",
                      style: TextStyle(color: Colors.grey)),
                ...comments.map(buildComment).toList(),
                const SizedBox(height: 80),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: replyingTo == null
                          ? "Tulis komentar..."
                          : "Balas ke $replyingTo...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () =>
                      addComment(replyTo: replyingTo),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3D5A80),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
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