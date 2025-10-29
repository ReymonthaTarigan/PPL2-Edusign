import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edu_sign/frontpage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'homepage.dart';
import 'forum.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _selectedIndex = 2;
  String name = "-";
  String jenjang = "-";
  String email = "-";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// 🔹 Ambil data user dari Firestore berdasarkan UID user yang login
  Future<void> _loadUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          setState(() {
            name = doc.data()?['name'] ?? '-';
            jenjang = doc.data()?['jenjang'] ?? '-';
            email = doc.data()?['email'] ?? '-';
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      debugPrint("Error fetching user data: $e");
    }
  }

  /// 🔹 Logout user dan kembali ke halaman login
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const FrontPage()),
    );
  }

  /// 🔹 Aksi saat klik navigasi bawah
  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ForumPage()), // ⬅️ Navigasi ke Forum
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double w = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Settings",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // 🔹 Foto profil + data user
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.grey,
                        ),
                        const SizedBox(width: 16),

                        // 🔹 Data user dari Firestore
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildAutoFitText(w, "NAMA : $name"),
                            _buildAutoFitText(w, "JENJANG : $jenjang"),
                            _buildAutoFitText(w, "EMAIL : $email"),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    const Divider(),
                    _buildMenuItem("Log Out", onTap: _logout),
                    const Divider(),
                    _buildMenuItem("Terms and Conditions"),
                    const Divider(),
                    _buildMenuItem("Privacy and Policy"),
                    const Divider(),
                    _buildMenuItem("Credits"),
                  ],
                ),
              ),
      ),

      // 🔹 Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue[900],
        unselectedItemColor: Colors.black54,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.forum), label: 'Forum'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  /// 🔹 Widget teks auto mengecil bila panjang
  Widget _buildAutoFitText(double width, String text) {
    return SizedBox(
      width: width * 0.6,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, color: Colors.black),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  /// 🔹 Widget menu setting
  Widget _buildMenuItem(String title, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Text(
          title,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
