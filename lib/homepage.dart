import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:auto_size_text/auto_size_text.dart';
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

  Stream<QuerySnapshot<Map<String, dynamic>>> _searchBaseStream() {
    return FirebaseFirestore.instance
        .collection('videos')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .withConverter<Map<String, dynamic>>(
      fromFirestore: (snap, _) => snap.data() ?? {},
      toFirestore: (data, _) => data,
    )
        .snapshots();
  }

  /// 🔹 Fungsi untuk ambil thumbnail dari link YouTube
  String getYoutubeThumbnail(String url) {
    final Uri? uri = Uri.tryParse(url);
    if (uri == null) return '';

    if (uri.host.contains('youtube.com') && uri.queryParameters.containsKey('v')) {
      final videoId = uri.queryParameters['v'];
      return 'https://img.youtube.com/vi/$videoId/0.jpg';
    }

    if (uri.host.contains('youtu.be')) {
      final videoId = uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : '';
      return 'https://img.youtube.com/vi/$videoId/0.jpg';
    }

    return '';
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

                    // ===== SEARCH BOX =====
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

              if (isSearching)
                _buildSearchResults()
              else
                _buildNormalContent(context),
            ],
          ),
        ),
      ),

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

  Widget _buildSearchResults() {
    final q = _query.toLowerCase().trim();
    return Padding(
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
          final filtered = docs.where((d) {
            final title = (d.data()['title'] ?? '').toString().toLowerCase();
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
              final title = data['title'] ?? 'Untitled';
              final link = data['link'] ?? '';

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
    );
  }

  Widget _buildNormalContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "Subjects",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 16),

        // 🔹 Horizontal scroll cards
        SizedBox(
          height: 130,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildCategoryCard(context, "Matematika",
                  "assets/images/Calculator.png", const [Color(0xFFD9D9D9), Color(0xFF62FF5A)]),
              _buildCategoryCard(context, "Pengetahuan Alam",
                  "assets/images/Physics.png", const [Color(0xFFD9D9D9), Color(0xFF5AA0FF)]),
              _buildCategoryCard(context, "Bahasa Indonesia",
                  "assets/images/Translation.png", const [Color(0xFFD9D9D9), Color(0xFFFFB74D)]),
              _buildCategoryCard(context, "Pengetahuan Sosial",
                  "assets/images/Safety Collection Place.png", const [Color(0xFFD9D9D9), Color(0xFFFF6B6B)]),
              _buildCategoryCard(context, "Seni Budaya",
                  "assets/images/Paint Palette.png", const [Color(0xFFD9D9D9), Color(0xFFF48FB1)]),
              _buildCategoryCard(context, "Jasmani & Rohani",
                  "assets/images/Sport.png", const [Color(0xFFD9D9D9), Color(0xFF81C784)]),
              _buildCategoryCard(context, "Informatika",
                  "assets/images/Computer Support.png", const [Color(0xFFD9D9D9), Color(0xFF26C6DA)]),
              _buildCategoryCard(context, "Bahasa Inggris",
                  "assets/images/Language.png", const [Color(0xFFD9D9D9), Color(0xFFFFF176)]),
            ],
          ),
        ),

        const SizedBox(height: 40),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            "Recently added",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
          ),
        ),

        // 🔹 Recently added section with thumbnails
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
                children: videos.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final title = data['title'] ?? 'Untitled';
                  final link = data['link'] ?? '';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 100,
                          height: 60,
                          child: Image.network(
                            getYoutubeThumbnail(link),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image,
                                size: 40, color: Colors.grey),
                          ),
                        ),
                      ),
                      title: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: const Text("Tap to watch"),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VideoDetailPage(
                              title: title,
                              videoUrl: link,
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
      ],
    );
  }

  // === CATEGORY CARD (kotak gradient dengan icon asset) ===
  Widget _buildCategoryCard(
      BuildContext context, String title, String iconPath, List<Color> gradientColors) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CategoryVideosPage(subject: title)),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Container(
          width: 208,
          height: 106,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: const Alignment(-0.8, 0.0),
              end: const Alignment(1.0, 1.0),
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 🔹 Gambar ikon
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset(
                  iconPath,
                  width: 85,
                  height: 85,
                  fit: BoxFit.contain,
                ),
              ),

              // 🔹 Teks kategori (rata kiri + auto wrap)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    title,
                    textAlign: TextAlign.left,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontFamily: 'Urbanist',
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
