import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Penting untuk cek admin

// Import semua halaman lain yang Anda perlukan
import 'auth.dart';
import 'homepage.dart';
import 'register.dart';
import 'verify.dart';
import 'forgot.dart';
import 'admin_homepage.dart'; // Halaman admin

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final Auth _auth = Auth();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isAdminLogin = false; // State untuk toggle admin

  // --- FUNGSI SIGNIN YANG SUDAH DIPERBARUI TOTAL ---
  Future<void> signIn() async {
    final emailOrUsername = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (emailOrUsername.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Field tidak boleh kosong.")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isAdminLogin) {
        // --- LOGIKA BARU: LOGIN SEBAGAI ADMIN ---

        // 1. Query koleksi 'admins' untuk mencari username
        final adminQuery = await FirebaseFirestore.instance
            .collection('admins')
            .where('username', isEqualTo: emailOrUsername)
            .limit(1)
            .get();

        if (adminQuery.docs.isEmpty) {
          // 2. Jika username admin tidak ditemukan
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: Colors.red,
                content: Text('Username admin tidak ditemukan.'),
              ),
            );
          }
        } else {
          // 3. Username ditemukan, cek password
          final adminData = adminQuery.docs.first.data();
          final String correctPassword = adminData['password'] as String;

          if (password == correctPassword) {
            // 4. Password BENAR
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Colors.green,
                  content: Text('Login Admin Berhasil! Mengalihkan...'),
                ),
              );
              await Future.delayed(const Duration(milliseconds: 1500));
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminHomePage()),
                );
              }
            }
          } else {
            // 5. Password SALAH
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Colors.red,
                  content: Text('Password admin salah.'),
                ),
              );
            }
          }
        }
      } else {
        // --- LOGIKA LAMA: LOGIN SEBAGAI USER BIASA ---

        // 1. Validasi format email (hanya untuk user)
        final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
        if (!emailRegex.hasMatch(emailOrUsername)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Format email tidak valid.")),
            );
          }
          // Hentikan loading
          setState(() { _isLoading = false; }); 
          return;
        }

        // 2. Sign in dengan Firebase Auth
        await _auth.signIn(email: emailOrUsername, password: password);
        final user = _auth.currentUser;

        if (user != null) {
          await user.reload();
          if (user.emailVerified) {
            // ... (Logika sukses login user) ...
             if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Colors.green,
                  content: Text('Login Berhasil! Mengalihkan...'),
                ),
              );
            }
            await Future.delayed(const Duration(milliseconds: 1500));
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            }
          } else {
            // ... (Logika user belum verifikasi) ...
             if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Colors.red,
                  content: Text('Email anda belum terverifikasi! Anda akan diarahkan ke halaman verifikasi...'),
                ),
              );
            }
            await Future.delayed(const Duration(milliseconds: 1500));
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const VerifyScreen()),
              );
            }
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      // Blok catch ini sekarang HANYA menangani error dari login USER
      String message;
      if (e.code == 'wrong-password' || e.code == 'user-not-found' || e.code == 'invalid-credential') {
        message = "Email/password salah";
      } else if (e.code == 'invalid-email') {
        message = "Format email tidak valid.";
      } else {
        message = "Login Gagal: ${e.message}";
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text(message)),
        );
      }
    } catch (e) {
      // Blok catch umum untuk error lain (misal error Firestore)
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text('Terjadi kesalahan: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFCF9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 150),
                      const Text(
                        "EDUSIGN",
                        style: TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3D5A80),
                        ),
                      ),
                      const Text(
                        "Selamat datang kembali",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFA6C9E0),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // --- PERUBAHAN HINT TEXT DINAMIS ---
                      SizedBox(
                        width: 300,
                        child: _buildTextField(
                          controller: _emailController,
                          hintText: _isAdminLogin ? "Username Admin" : "Email",
                          obscure: false,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Input Password
                      SizedBox(
                        width: 300,
                        child: _buildTextField(
                          controller: _passwordController,
                          hintText: "Password",
                          obscure: true,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Lupa password
                      Align(
                        alignment: Alignment.center,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: TextButton(
                            // Sembunyikan jika login admin
                            onPressed: _isAdminLogin ? null : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                              );
                            },
                            child: Text(
                              "Lupa password?",
                              style: TextStyle(
                                fontSize: 14,
                                color: _isAdminLogin ? Colors.grey : Colors.black87,
                                decoration: TextDecoration.underline,
                                decorationThickness: 2,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      // Toggle Login Admin
                      SizedBox(
                        width: 300,
                        child: SwitchListTile(
                          title: const Text(
                            "Login sebagai Guru",
                            style: TextStyle(
                              color: Color(0xFF3D5A80),
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          value: _isAdminLogin,
                          onChanged: (bool value) {
                            setState(() {
                              _isAdminLogin = value;
                            });
                          },
                          activeColor: const Color(0xFF3D5A80),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Tombol Login
                      SizedBox(
                        width: 300,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3D5A80),
                            foregroundColor: const Color(0xFFFAF9F6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 4,
                          ),
                          onPressed: _isLoading ? null : signIn,
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  "Login",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bagian bawah: Register
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                // Sembunyikan jika login admin
                child: _isAdminLogin ? const SizedBox(height: 40) : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Belum punya akun? ",
                      style: TextStyle(fontSize: 14, color: Color(0xFF3D5A80)),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegisterScreen()),
                        );
                      },
                      child: const Text(
                        "Daftar",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3D5A80),
                          decoration: TextDecoration.underline,
                          decorationThickness: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Custom TextField
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required bool obscure,
  }) {
    return SizedBox(
      height: 50,
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: hintText,
          filled: true,
          fillColor: const Color(0xFFA6C9E0),
          hintStyle: const TextStyle(
            color: Color(0xFFE0FBFC),
            fontWeight: FontWeight.w600,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Color(0xFF3D5A80), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Color(0xFF3D5A80), width: 2),
          ),
        ),
      ),
    );
  }
}