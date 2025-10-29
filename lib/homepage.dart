import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'getService/getdetail.dart';
import 'auth.dart';
import 'forum.dart';
import 'setting.dart';
import 'category_videos_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // Stream dasar untuk pencarian: ambil video terbaru lalu filter di client
  Stream<QuerySnapshot<Map<String, dynamic>>> _searchBaseStream() {
    return FirebaseFirestore.instance
        .collection('videos')
        .orderBy('timestamp', descending: true)
        .limit(100) // naikkan kalau dataset makin besar
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (snap, _) => snap.data() ?? {},
          toFirestore: (data, _) => data,
        )
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final bool isSearching = _query.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== HEADER =====
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF98C1D9), Color(0xFF3D5A80)],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(Auth().currentUser?.uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Text(
                            "Hi, -",
                            style: TextStyle(
                              fontSize: 28,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }
                        final userData =
                            snapshot.data!.data() as Map<String, dynamic>?;
                        final name = userData?['name'] ?? '-';
                        return Text(
                          "Hi, $name",
                          style: const TextStyle(
                            fontSize: 28,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // ===== SEARCH BOX (tanpa hamburger) =====
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (v) => setState(() => _query = v),
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: "Search videos by title...",
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _query.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _query = '');
                                  },
                                ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // ===== MODE PENCARIAN =====
              if (isSearching) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "Search results",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 12),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _searchBaseStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final docs = snapshot.data?.docs ?? [];
                      final q = _query.toLowerCase().trim();

                      // Filter contains + case-insensitive
                      final filtered = docs.where((d) {
                        final data = d.data();
                        final title = (data['title'] ?? '').toString().toLowerCase();
                        return title.contains(q);
                      }).toList();

                      if (filtered.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text("No results"),
                        );
                      }

                      return Column(
                        children: filtered.map((doc) {
                          final data = doc.data();
                          final title = (data['title'] ?? 'Untitled').toString();
                          final link = (data['link'] ?? '').toString();
                          final signLang = data['signLanguage'];
                          final subtitle = data['subtitle'];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                            child: ListTile(
                              leading: const Icon(Icons.play_circle_fill,
                                  color: Colors.blue, size: 40),
                              title: Text(title),
                              subtitle: const Text("Tap to watch"),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => VideoDetailPage(
                                      title: title,
                                      videoUrl: link,
                                      signLangUrl: signLang,
                                      subtitle: subtitle,
                                      videoDocId: doc.id,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),
              ]

              // ===== MODE NORMAL =====
              else ...[
                // CATEGORY
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "Subjects",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  height: 120,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _buildCategory(context, "Matematika", Colors.amber[700]!),
                        _buildCategory(context, "Bahasa Indonesia", Colors.green),
                        _buildCategory(context, "IPA", Colors.blue),
                        _buildCategory(context, "IPS", Colors.red),
                        _buildCategory(context, "Bahasa Inggris", Colors.purple),
                        _buildCategory(context, "PPKN", Colors.deepOrange),
                        _buildCategory(context, "Seni Budaya", Colors.teal),
                        _buildCategory(context, "PJOK", Colors.brown),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Recently added
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    "Recently added",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('videos')
                        .orderBy('timestamp', descending: true)
                        .limit(5)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text("No videos available"),
                        );
                      }

                      final videos = snapshot.data!.docs;
                      return Column(
                        children: List.generate(videos.length, (i) {
                          final doc = videos[i];
                          final data = doc.data() as Map<String, dynamic>;
                          final title = data['title'] ?? 'Untitled';
                          final link = data['link'] ?? '';
                          final signLang = data['signLanguage'];
                          final subtitle = data['subtitle'];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                            child: ListTile(
                              leading: const Icon(
                                Icons.play_circle_fill,
                                color: Colors.blue,
                                size: 40,
                              ),
                              title: Text(title),
                              subtitle: const Text("Tap to watch"),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => VideoDetailPage(
                                      title: title,
                                      videoUrl: link,
                                      signLangUrl: signLang,
                                      subtitle: subtitle,
                                      videoDocId: doc.id,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),

      // ===== BOTTOM NAV =====
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: Colors.blue[900],
        unselectedItemColor: Colors.black54,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ForumPage()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.forum), label: 'Forum'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  static Widget _buildCategory(BuildContext context, String title, Color color) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoryVideosPage(subject: title),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    offset: Offset(2, 4),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.book, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
