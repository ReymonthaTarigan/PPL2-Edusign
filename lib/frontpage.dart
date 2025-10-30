import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'login.dart';
import 'register.dart';

void main() {
  runApp(const FrontPage());
}

class FrontPage extends StatelessWidget {
  const FrontPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Edusign',
      debugShowCheckedModeBanner: false,
      home: const WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      body: SafeArea(
        // Scroll agar aman di HP kecil/layar sempit
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;

            // Ukuran adaptif
            final logoHeight = math.min(220.0, h * 0.26);
            final titleSize = math.max(24.0, w * 0.06);      // "Selamat datang di"
            final brandSize = math.max(36.0, w * 0.12);      // "EDUSIGN"
            final buttonWidth = math.min(w * 0.85, 360.0);
            final buttonHeight = math.max(44.0, h * 0.06);
            final gapSmall = h * 0.012;  // ~8–12px
            final gapLarge = h * 0.12;   // spasi besar di tengah

            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: math.max(16.0, w * 0.06)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo responsif
                    Image.asset(
                      "assets/images/logo.png",
                      height: logoHeight,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: gapSmall),
                    Text(
                      "Selamat datang di",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3D5A80),
                        height: 1.15,
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        "EDUSIGN",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: brandSize,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF3D5A80),
                          height: 1.0,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    SizedBox(height: gapLarge),

                    // Tombol 1
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: buttonWidth,
                        minHeight: buttonHeight,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3D5A80),
                            foregroundColor: const Color(0xFFFAF9F6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 4,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                            );
                          },
                          child: const Text(
                            "Sudah Punya Akun",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: gapSmall * 1.5),

                    // Tombol 2
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: buttonWidth,
                        minHeight: buttonHeight,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF98C1D9),
                            foregroundColor: const Color(0xFF3D5A80),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                              side: const BorderSide(
                                color: Color(0xFF3D5A80),
                                width: 1.5,
                              ),
                            ),
                            elevation: 4,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const RegisterScreen()),
                            );
                          },
                          child: const Text(
                            "Belum Punya Akun",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: gapSmall),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
