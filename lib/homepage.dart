import 'package:flutter/material.dart';
import 'auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'getService/getvid.dart';


class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header Gradient
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Hi, -",
                          style: TextStyle(
                            fontSize: 28,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            await Auth().signOut();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[900],
                          ),
                          child: const Text("Logout"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: const TextField(
                        decoration: InputDecoration(
                          hintText: "Hinted search text",
                          prefixIcon: Icon(Icons.menu),
                          suffixIcon: Icon(Icons.search),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Category grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    for (final color in [
                      Colors.amber,
                      Colors.green,
                      Colors.blue,
                      Colors.red,
                      Colors.purple,
                      Colors.orange,
                    ])
                      Column(
                        children: [
                          Container(
                            width: 67,
                            height: 67,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                )
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text("Category"),
                        ],
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Recently Viewed Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text("Recently Viewed",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Text("See All", style: TextStyle(color: Colors.blue)),
                  ],
                ),
              ),

              // Stream dari Firestore
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('videos').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text("No videos found"));
                    }

                    final videos = snapshot.data!.docs;

                    String? getYoutubeThumbnail(String url) {
                      final uri = Uri.parse(url);
                      String? videoId;

                      if (uri.host.contains('youtu.be')) {
                        videoId = uri.pathSegments.first;
                      } else if (uri.host.contains('youtube.com')) {
                        videoId = uri.queryParameters['v'];
                      }

                      return videoId != null
                          ? 'https://img.youtube.com/vi/$videoId/hqdefault.jpg'
                          : null;
                    }

                    return Column(
                      children: videos.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final title = data['title'] ?? 'Untitled';
                        final link = data['link'] ?? '';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: VideoCard(
                            title: title,
                            link: link,
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),


              const SizedBox(height: 12),

              // Placeholder video section
              // Padding(
              //   padding: const EdgeInsets.symmetric(horizontal: 24),
              //   child: Row(
              //     children: [
              //       Expanded(
              //         child: Column(
              //           children: [
              //             Container(
              //               height: 100,
              //               color: Colors.black,
              //             ),
              //             const SizedBox(height: 6),
              //             const Text("Title"),
              //           ],
              //         ),
              //       ),
              //       const SizedBox(width: 16),
              //       Expanded(
              //         child: Column(
              //           children: [
              //             Container(
              //               height: 100,
              //               color: Colors.black,
              //             ),
              //             const SizedBox(height: 6),
              //             const Text("Title"),
              //           ],
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: Colors.blue[900],
        unselectedItemColor: Colors.black54,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Subject'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Forms'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
