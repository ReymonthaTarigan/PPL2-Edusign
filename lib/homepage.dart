import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'getService/getdetail.dart';
import 'auth.dart';
import 'forum.dart';
import 'setting.dart';
import 'category_videos_page.dart'; // halaman baru untuk kategori

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 HEADER
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
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: const TextField(
                        decoration: InputDecoration(
                          hintText: "Search...",
                          prefixIcon: Icon(Icons.menu),
                          suffixIcon: Icon(Icons.search),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // 🔹 CATEGORY SCROLL (Horizontal)
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

              // 🔹 RECENTLY VIEWED
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      "Recently Viewed",
                      style:
                      TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      "See All",
                      style: TextStyle(color: Colors.blue, fontSize: 18),
                    ),
                  ],
                ),
              ),

              // 🔹 VIDEO LIST
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                  FirebaseFirestore.instance.collection('videos').snapshots(),
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
            ],
          ),
        ),
      ),

      // 🔹 BOTTOM NAVIGATION
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: Colors.blue[900],
        unselectedItemColor: Colors.black54,
        onTap: (index) {
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ForumPage()),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Subject'),
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
