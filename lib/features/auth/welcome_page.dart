import 'package:flutter/material.dart';

import 'login_page.dart';
import 'register_page.dart';
import 'widgets/premium_auth_components.dart';

class AuthWelcomePage extends StatelessWidget {
  const AuthWelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return PremiumAuthScaffold(
      child: PremiumAuthCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Align(
              alignment: Alignment.topLeft,
              child: MiniStar(),
            ),
            const SizedBox(height: 10),
            const PhoneIllustration(),
            const SizedBox(height: 24),
            const Text(
              'Merhaba',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xff2E2E3A),
                fontSize: 30,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'SmartKOBİ ile gelir, gider,\ncari ve stok takibini tek ekrandan yönetin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xff7A7A8C),
                fontSize: 16,
                height: 1.55,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 34),
            CardActionButton(
              label: 'Giriş yap',
              filled: true,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPagePremium()),
                );
              },
            ),
            const SizedBox(height: 16),
            CardActionButton(
              label: 'Kayıt ol',
              filled: false,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterPage()),
                );
              },
            ),
            const SizedBox(height: 28),
            const Text(
              'Güvenli giriş seçenekleri',
              style: TextStyle(
                color: Color(0xff9A9AAA),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SocialDot(icon: Icons.facebook, color: Color(0xff4267B2)),
                SizedBox(width: 16),
                SocialDot(icon: Icons.g_mobiledata, color: Color(0xffEA4335)),
                SizedBox(width: 16),
                SocialDot(icon: Icons.business, color: Color(0xff0A66C2)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
