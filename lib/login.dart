import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'forgot.dart';
import 'homepage.dart';
import 'register.dart';
import 'auth.dart';
import 'verify.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final Auth _auth = Auth();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // State untuk mengontrol tampilan loading
  bool _isLoading = false;

  Future<void> signIn() async {
    // 1. Tampilkan loading indicator
    setState(() {
      _isLoading = true;
    });

    try {
      await _auth.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

        final user = _auth.currentUser;
        if (user != null) {
          await user.reload();
          if (user.emailVerified) {
            // simpan data user ke Firestore
            await _auth.saveUserData(
              uid: user.uid,
              name: "Nama yang diinput di RegisterScreen",
              jenjang: "Jenjang yang dipilih",
              email: user.email!,
            );

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: Colors.green,
                content: Text('Login Berhasil! Mengalihkan...'),
              ),
            );

            await Future.delayed(const Duration(milliseconds: 1500));

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );

          } else {

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: Colors.red,
                content: Text('Email anda belum terverifikasi! Anda akan diarahkan ke halaman verifikasi...'),
              ),
            );

            await Future.delayed(const Duration(milliseconds: 1500));

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const VerifyScreen()),
            );
          }
        }

    } on FirebaseAuthException catch (e) {
      // Jika gagal, tampilkan SnackBar error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Login Gagal: ${e.message}'),
        ),
      );
      print("Login Gagal: ${e.message}");
    } finally {
      // 3. Sembunyikan loading indicator setelah selesai (baik berhasil maupun gagal)
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
        // ... (AppBar Anda tetap sama)
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            Navigator.pop(context);
          },
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
                      // ... (Bagian Teks Judul tetap sama)
                      const SizedBox(height: 150),
                      const Text("EDUSIGN", style: TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: Color(0xFF3D5A80))),
                      const Text("Selamat datang kembali", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFA6C9E0))),
                      const SizedBox(height: 40),

                      // Input Email
                      SizedBox(
                        width: 300,
                        child: _buildTextField(
                          controller: _emailController,
                          hintText: "Email",
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
                      const SizedBox(height: 40),

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
                          // 4. Nonaktifkan tombol saat loading, lalu panggil signIn
                          onPressed: _isLoading ? null : signIn,
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  "Login",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      
                      // ... (Sisa UI Anda tetap sama)
                      TextButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()));
                        },
                        child: const Text("Lupa password?", style: TextStyle(fontSize: 14, color: Colors.black87, decoration: TextDecoration.underline, decorationThickness: 2, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Belum punya akun? ", style: TextStyle(fontSize: 14, color: Color(0xFF3D5A80))),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
                      },
                      child: const Text("Daftar", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF3D5A80), decoration: TextDecoration.underline, decorationThickness: 2)),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required bool obscure,
  }) {
    // ... (Fungsi _buildTextField Anda tetap sama)
    return SizedBox(
      height: 50,
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: hintText,
          filled: true,
          fillColor: const Color(0xFFA6C9E0),
          hintStyle: const TextStyle(color: Color(0xFFE0FBFC), fontWeight: FontWeight.w600),
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