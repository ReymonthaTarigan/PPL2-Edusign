import 'package:flutter/material.dart';
import 'login.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  String? selectedJenjang;
  final List<String> jenjangList = [
    "SD",
    "SMP",
    "SMA",
  ];

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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                const Text(
                  "EDUSIGN",
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3D5A80),
                  ),
                ),
                const Text(
                  "Registrasi akun baru",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFA6C9E0),
                  ),
                ),
                const SizedBox(height: 40),

                // Nama
                SizedBox(
                  width: 300,
                  height: 50,
                  child: _buildTextField(hintText: "Nama", obscure: false),
                ),
                const SizedBox(height: 20),

                // Jenjang Pendidikan
                SizedBox(
                  width: 300,
                  height: 50,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA6C9E0),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: const Color(0xFF3D5A80),
                        width: 1.5,
                      ),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: selectedJenjang,
                      hint: const Text(
                        "Jenjang Pendidikan",
                        style: TextStyle(
                          color: Color(0xFF293241),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                      ),
                      items: jenjangList
                          .map(
                            (jenjang) => DropdownMenuItem<String>(
                              value: jenjang,
                              child: Text(jenjang),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedJenjang = value;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Email
                SizedBox(
                  width: 300,
                  height: 50,
                  child: _buildTextField(hintText: "Email", obscure: false),
                ),
                const SizedBox(height: 20),

                // Password
                SizedBox(
                  width: 300,
                  height: 50,
                  child: _buildTextField(hintText: "Password", obscure: true),
                ),
                const SizedBox(height: 20),

                // Konfirmasi Password
                SizedBox(
                  width: 300,
                  height: 50,
                  child: _buildTextField(
                      hintText: "Konfirmasi Password", obscure: true),
                ),
                const SizedBox(height: 40),

                // Tombol Daftar
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
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "Daftar",
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
      ),
    );
  }

  // Custom TextField
  Widget _buildTextField({required String hintText, required bool obscure}) {
    return TextField(
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: const Color(0xFFA6C9E0),
        hintStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
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
