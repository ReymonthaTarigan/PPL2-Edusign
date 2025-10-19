import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'homepage.dart';
import 'setting.dart';
import 'forum_detail.dart';

class ForumPage extends StatefulWidget {
  const ForumPage({super.key});

  @override
  State<ForumPage> createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage> {
  bool isCreating = false;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  File? _selectedImage;

  final List<Map<String, dynamic>> _posts = [
    {
      "title": "KANCIL TERNYATA SIGMA?!!??",
      "message": "Menurut kalian bener ga sih kalo kancil itu sigma skibidi??",
      "image": null
    },
    {
      "title": "Kelinci vs kura-kura ternyata bukan tentang siapa yang cepat",
      "message":
          "Si Kelinci dalam cerita ini adalah anak yang secara alami berbakat dan cepat. Bakat mereka justru menjadi kutukan karena ekspektasi orang tua menjadi jauh lebih tinggi. Mereka dipaksa berlari tanpa henti dengan dalih \"memaksimalkan potensi\" dan \"demi kesuksesan\".",
      "image": null
    },
    {
      "title": "aku wumbo, dia mumbo",
      "message": "M untuk Mulyono, sedangkan W untuk widodo. He dupe joke oui",
      "image": null
    },
  ];

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  void postForum() {
    String title = _titleController.text.trim();
    String message = _messageController.text.trim();

    if (title.length > 67) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Judul tidak boleh lebih dari 67 karakter")),
      );
      return;
    }

    if (title.isNotEmpty && message.isNotEmpty) {
      setState(() {
        _posts.insert(0, {
          "title": title,
          "message": message,
          "image": _selectedImage,
        });
        _titleController.clear();
        _messageController.clear();
        _selectedImage = null;
        isCreating = false;
      });
    }
  }

  int _selectedIndex = 2;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 0) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const HomePage()));
    } else if (index == 3) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const ProfilePage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3D5A80),
        title: const Text("Forum", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: "Cari post...",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => setState(() => isCreating = !isCreating),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3D5A80),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isCreating ? "Batal" : "Buat Baru",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          if (isCreating)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    maxLength: 67,
                    decoration: const InputDecoration(
                      labelText: "Judul / Topik (maks. 67 karakter)",
                      border: OutlineInputBorder(),
                      counterText: "",
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _messageController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Isi pesan...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: pickImage,
                        icon: const Icon(Icons.image_outlined),
                        label: const Text("Tambah Gambar"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF98C1D9),
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (_selectedImage != null)
                        Expanded(
                          child: Image.file(
                            _selectedImage!,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: postForum,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3D5A80),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Post",
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const Divider(thickness: 1),
                ],
              ),
            ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _posts.length,
              itemBuilder: (context, index) {
                final post = _posts[index];
                String message = post["message"];
                bool isLong = message.length > 100;
                String displayText =
                    isLong ? "${message.substring(0, 100)}..." : message;

                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ForumDetailPage(
                          title: post["title"],
                          message: post["message"],
                          image: post["image"],
                        ),
                      ),
                    );
                  },
                  child: Card(
                    color: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post["title"],
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(displayText),
                          if (post["image"] != null) ...[
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(post["image"],
                                  height: 150, fit: BoxFit.cover),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF3D5A80),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: "Subject"),
          BottomNavigationBarItem(icon: Icon(Icons.forum), label: "Forms"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}