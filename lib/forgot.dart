import 'package:flutter/material.dart';
import 'verify.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
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
              // Bagian tengah
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 200),
                      const Text(
                        "EDUSIGN",
                        style: TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3D5A80),
                        ),
                      ),
                      const Text(
                        "Atur ulang password anda",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFA6C9E0),
                        ),
                      ),
                      const SizedBox(height: 50),

                      // Input Email
                      SizedBox(
                        width: 300,
                        height: 50,
                        child: _buildTextField(hintText: "Email"),
                      ),
                      const SizedBox(height: 30),

                      // Tombol Kirim Verifikasi
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
                            //tambahin si email verif disini ntar
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const VerifyScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            "Kirim Verifikasi",
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

              // Bagian bawah -> kembali ke login
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Kembali ke ",
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF3D5A80),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "Login",
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
  Widget _buildTextField({required String hintText}) {
    return TextField(
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: const Color(0xFFA6C9E0),
        hintStyle: const TextStyle(
          color: Color(0xFFE0FBFC),
          fontWeight: FontWeight.w600,
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 15,
          horizontal: 20,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Color(0xFF3D5A80), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Color(0xFF3D5A80), width: 2),
        ),
      ),
    );
  }
}
