import 'package:flutter/material.dart';
import 'forgot.dart';
import 'register.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFCF9),
      appBar: AppBar(
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
              // Bagian tengah (logo + form + tombol)
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

                      // Input Email
                      SizedBox(
                        width: 300,
                        child: _buildTextField(
                          hintText: "Email",
                          obscure: false,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Input Password
                      SizedBox(
                        width: 300,
                        child: _buildTextField(
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
                          onPressed: () {
                            // aksi login
                          },
                          child: const Text(
                            "Login",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Lupa password
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          "Lupa password?",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            decoration: TextDecoration.underline,
                            decorationThickness: 2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // dafrtar
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Belum punya akun? ",
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF3D5A80),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
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
  Widget _buildTextField({required String hintText, required bool obscure}) {
    return SizedBox(
      height: 50,
      child: TextField(
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: hintText,
          filled: true,
          fillColor: const Color(0xFFA6C9E0),
          hintStyle: const TextStyle(
            color: Color(0xFFE0FBFC),
            fontWeight: FontWeight.w600,
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide:
                const BorderSide(color: Color(0xFF3D5A80), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide:
                const BorderSide(color: Color(0xFF3D5A80), width: 2),
          ),
        ),
      ),
    );
  }
}
