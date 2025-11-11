import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edu_sign/frontpage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
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
  String _profilePhotoUrl = "";
  bool isLoading = true;

  final TextEditingController _nameController = TextEditingController();
  String _selectedJenjang = "SD";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final data = doc.data() ?? {};

          setState(() {
            name = (data['name'] ?? '-').toString();
            jenjang = (data['jenjang'] ?? '-').toString();
            email = (data['email'] ?? user.email ?? '-').toString();
            _profilePhotoUrl = (data['profilePhoto'] ?? '').toString();
            isLoading = false;
          });

          _nameController.text = name == "-" ? "" : name;
          _selectedJenjang =
              (jenjang == "-" || jenjang.isEmpty) ? "SD" : jenjang;
        } else {
          setState(() {
            email = user.email ?? '-';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      debugPrint("Error fetching user data: $e");
    }
  }

  Future<void> _saveProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final newName = _nameController.text.trim();
      final newJenjang = _selectedJenjang;

      if (newName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Nama tidak boleh kosong.")),
        );
        return;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(
        {
          'name': newName,
          'jenjang': newJenjang,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      setState(() {
        name = newName;
        jenjang = newJenjang;
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profil berhasil diperbarui.")),
      );
    } catch (e) {
      debugPrint("Error updating profile: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal memperbarui profil.")),
        );
      }
    }
  }

  Future<void> _changeProfilePhoto() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      if (file.bytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal membaca file gambar.")),
        );
        return;
      }

      final ext = (file.extension ?? 'jpg').toLowerCase();
      final contentType = ext == 'png' ? 'image/png' : 'image/jpeg';

      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_photos')
          .child('${user.uid}.$ext');

      final uploadTask = await ref.putData(
        file.bytes!,
        SettableMetadata(contentType: contentType),
      );

      final downloadUrl = await uploadTask.ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(
        {
          'profilePhoto': downloadUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      setState(() {
        _profilePhotoUrl = downloadUrl;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Foto profil berhasil diperbarui.")),
      );
    } catch (e) {
      debugPrint("Error change profile photo: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal mengubah foto profil.")),
        );
      }
    }
  }

  void _openEditProfileSheet() {
    _nameController.text = name == "-" ? "" : name;
    _selectedJenjang =
        (jenjang == "-" || jenjang.isEmpty) ? _selectedJenjang : jenjang;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Edit Profil",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "Nama",
                  hintText: "Masukkan nama lengkap",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedJenjang,
                decoration: InputDecoration(
                  labelText: "Jenjang",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: "SD", child: Text("SD")),
                  DropdownMenuItem(value: "SMP", child: Text("SMP")),
                  DropdownMenuItem(value: "SMA", child: Text("SMA")),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedJenjang = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Simpan Perubahan",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const FrontPage()),
    );
  }

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
        MaterialPageRoute(builder: (context) => const ForumPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Profil Pengguna",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Kelola akun Edusign kamu",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Profile Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.shade600,
                            Colors.blue.shade300,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 34,
                                backgroundColor: Colors.white.withOpacity(0.25),
                                backgroundImage: _profilePhotoUrl.isNotEmpty
                                    ? NetworkImage(_profilePhotoUrl)
                                    : null,
                                child: _profilePhotoUrl.isEmpty
                                    ? const Icon(
                                        Icons.person,
                                        size: 38,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                              Positioned(
                                bottom: -2,
                                right: -2,
                                child: InkWell(
                                  onTap: _changeProfilePhoto,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.15),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      size: 16,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildAutoFitText(
                                  w,
                                  name == "-" ? "Pengguna Baru" : name,
                                  isBold: true,
                                  color: Colors.white,
                                ),
                                const SizedBox(height: 4),
                                _buildAutoFitText(
                                  w,
                                  jenjang == "-" || jenjang.isEmpty
                                      ? "Belum pilih jenjang"
                                      : "Jenjang: $jenjang",
                                  color: Colors.white.withOpacity(0.9),
                                ),
                                const SizedBox(height: 4),
                                _buildAutoFitText(
                                  w,
                                  email,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Info chips
                    Row(
                      children: [
                        _buildInfoChip(
                          icon: Icons.school,
                          label: jenjang == "-" || jenjang.isEmpty
                              ? "Atur jenjang belajar"
                              : "Jenjang $jenjang",
                        ),
                        const SizedBox(width: 8),
                        _buildInfoChip(
                          icon: Icons.person_outline,
                          label: name == "-"
                              ? "Lengkapi nama kamu"
                              : "Profil sudah terisi",
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Pengaturan Akun
                    const Text(
                      "Pengaturan Akun",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 0.7,
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildMenuItem(
                            Icons.edit_outlined,
                            "Edit Profil",
                            "Ubah nama & jenjang belajar",
                            onTap: _openEditProfileSheet,
                          ),
                          const Divider(height: 0),
                          _buildMenuItem(
                            Icons.logout,
                            "Log Out",
                            "Keluar dari akun Edusign",
                            textColor: Colors.red[700],
                            iconColor: Colors.red[700],
                            onTap: _logout,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
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

  Widget _buildAutoFitText(
    double width,
    String text, {
    bool isBold = false,
    Color color = Colors.black,
  }) {
    return SizedBox(
      width: width * 0.6,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            color: color,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blue[700]),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: iconColor ?? Colors.blue[800],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: textColor ?? Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
