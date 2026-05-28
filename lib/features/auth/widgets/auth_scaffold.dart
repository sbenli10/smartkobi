import 'package:flutter/material.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1F3A), // #0B1F3A - Gece Laciverti
      body: Stack(
        children: [
          // Arka plan soft fintech glow efektleri
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xffc89b3c).withValues(alpha: 0.05),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xffc89b3c).withValues(alpha: 0.22),
                    blurRadius: 120,
                    spreadRadius: 18,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -150,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xff081a2f).withValues(alpha: 0.8),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xff081a2f).withValues(alpha: 0.7),
                    blurRadius: 90,
                    spreadRadius: 12,
                  ),
                ],
              ),
            ),
          ),
          // Ana İçerik Taşıyıcı ve Responsive Sınırlandırıcı
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 460),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
