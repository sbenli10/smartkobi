import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../home/home_shell.dart';
import 'register_page.dart';

class LoginPagePremium extends StatefulWidget {
  const LoginPagePremium({super.key});

  @override
  State<LoginPagePremium> createState() => _LoginPagePremiumState();
}

class _LoginPagePremiumState extends State<LoginPagePremium> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showError('Lütfen önce geçerli bir e-posta adresi girin.');
      return;
    }
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'http://localhost:3000/#/reset-password',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Şifre sıfırlama bağlantısı e-posta adresinize gönderildi.'),
          backgroundColor: Color(0xff22C55E),
        ),
      );
    } catch (_) {
      _showError('Şifre sıfırlama sırasında bir sorun oluştu. Lütfen tekrar deneyin.');
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );

      if (!mounted) return;
      if (response.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Giriş başarılı. Ana sayfa açılıyor...'),
            backgroundColor: Color(0xff22C55E),
            duration: Duration(seconds: 1),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeShell()),
        );
      }
    } on AuthException catch (e) {
      final msg = e.message.contains('Invalid login credentials')
          ? 'E-posta veya şifre hatalı.'
          : e.message.contains('Email not confirmed')
              ? 'E-posta adresinizi doğrulamanız gerekiyor.'
              : 'Bağlantı sırasında bir sorun oluştu. Lütfen tekrar deneyin.';
      _showError('$msg\n\nHata Detayı: ${e.statusCode} - ${e.message}');
    } catch (e) {
      _showError('Bağlantı sırasında bir sorun oluştu.\nHata: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xffEF4444),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff031B2D), // Temel koyu arka plan
      body: Stack(
        children: [
          const _TurquoiseAuthBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _PremiumLogoSection(),
                      const SizedBox(height: 36),
                      _GlassAuthPanel(
                        formKey: _formKey,
                        emailCtrl: _emailCtrl,
                        passCtrl: _passCtrl,
                        loading: _loading,
                        obscure: _obscure,
                        onToggleObscure: () => setState(() => _obscure = !_obscure),
                        onLogin: _login,
                        onResetPassword: _resetPassword,
                      ),
                      const SizedBox(height: 36),
                      _BottomAuthLinks(
                        loading: _loading,
                        onRegisterTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const RegisterPage()),
                          );
                        },
                      ),
                      const SizedBox(height: 28),
                      const _SecurityNote(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// HELPER WIDGETS FOR PREMIUM TURQUOISE FINTECH DESIGN
// ============================================================================

class _TurquoiseAuthBackground extends StatelessWidget {
  const _TurquoiseAuthBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Ana Gradient: Koyu Lacivert -> Derin Turkuaz
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xff031B2D), // Derin üst
                Color(0xff0A2E45), // Orta Turkuaz-Laci
                Color(0xff0D3F5A), // Alt Turkuaz ışık noktası
              ],
            ),
          ),
        ),
        // Sağ Üst Turkuaz Glow
        Positioned(
          top: -120,
          right: -100,
          child: Container(
            width: 380,
            height: 380,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xff1CC7C9).withValues(alpha: 0.12),
                  const Color(0xff1CC7C9).withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        // Sol Alt Camgöbeği/Altın Glow Karışımı
        Positioned(
          bottom: -150,
          left: -150,
          child: Container(
            width: 450,
            height: 450,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xff7EE7E8).withValues(alpha: 0.08),
                  const Color(0xff7EE7E8).withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PremiumLogoSection extends StatelessWidget {
  const _PremiumLogoSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 80,
          width: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: const Color(0xff062338), // Koyu iç zemin
            border: Border.all(color: const Color(0xff1CC7C9).withValues(alpha: 0.15)), // Turkuaz ince sınır
            boxShadow: [
              BoxShadow(
                color: const Color(0xff1CC7C9).withValues(alpha: 0.1),
                blurRadius: 28,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.hub_rounded,
              color: Color(0xffE2C37A), // Altın Logo Kontrastı
              size: 34,
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'SmartKOBİ',
          style: TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'İşletmenizi tek yerden yönetin.',
          style: TextStyle(
            color: Color(0xffCFEFF0), // Çok açık turkuaz/krem
            fontSize: 15,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _GlassAuthPanel extends StatelessWidget {
  const _GlassAuthPanel({
    required this.formKey,
    required this.emailCtrl,
    required this.passCtrl,
    required this.loading,
    required this.obscure,
    required this.onToggleObscure,
    required this.onLogin,
    required this.onResetPassword,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final bool loading;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final VoidCallback onLogin;
  final VoidCallback onResetPassword;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06), // Soft Glass panel
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff031B2D).withValues(alpha: 0.4),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hoş geldiniz',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hesabınıza giriş yaparak işletme verilerinize güvenle erişin.',
              style: TextStyle(
                color: Color(0xff94A3B8), // Daha soluk/nötr açıklama
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            
            _AuthInput(
              controller: emailCtrl,
              hint: 'E-posta adresiniz',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              enabled: !loading,
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'E-posta adresinizi girin';
                if (!value.trim().contains('@') || !value.trim().contains('.')) return 'Geçerli bir e-posta adresi girin';
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            _AuthInput(
              controller: passCtrl,
              hint: 'Şifreniz',
              icon: Icons.lock_outline_rounded,
              obscure: obscure,
              enabled: !loading,
              onToggleObscure: onToggleObscure,
              onFieldSubmitted: (_) => loading ? null : onLogin(),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Şifrenizi girin';
                if (value.length < 6) return 'Şifre en az 6 karakter olmalı';
                return null;
              },
            ),
            const SizedBox(height: 10),
            
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: loading ? null : onResetPassword,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xffCFEFF0),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                ),
                child: const Text(
                  'Şifremi Unuttum',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            _PrimaryLoginButton(
              loading: loading,
              onPressed: onLogin,
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthInput extends StatelessWidget {
  const _AuthInput({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.enabled,
    this.obscure = false,
    this.onToggleObscure,
    this.keyboardType,
    this.validator,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool enabled;
  final bool obscure;
  final VoidCallback? onToggleObscure;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        obscureText: obscure,
        keyboardType: keyboardType,
        validator: validator,
        onFieldSubmitted: onFieldSubmitted,
        style: const TextStyle(
          color: Color(0xff16324A), // Koyu Teal Yazı
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xff6B7C93), fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xff5B6B7F), size: 22),
          suffixIcon: onToggleObscure != null
              ? IconButton(
                  icon: Icon(
                    obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: const Color(0xff5B6B7F),
                    size: 20,
                  ),
                  onPressed: enabled ? onToggleObscure : null,
                )
              : null,
          fillColor: Colors.white,
          filled: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20), // Height ~60
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xff1CC7C9), width: 1.5), // Turkuaz Focus Outline
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xffEF4444), width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xffEF4444), width: 1.5),
          ),
          errorStyle: const TextStyle(
            color: Color(0xffEF4444),
            fontWeight: FontWeight.w600,
            fontSize: 12,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}

class _PrimaryLoginButton extends StatelessWidget {
  const _PrimaryLoginButton({
    required this.loading,
    required this.onPressed,
  });

  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            Color(0xffD9B24C), // Sıcak Mat Altın
            Color(0xffC7962E), // Derin Mat Altın
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xffD9B24C).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.8,
                  color: Color(0xff081A2F),
                ),
              )
            : const Text(
                'Giriş Yap',
                style: TextStyle(
                  color: Color(0xff031B2D), // Çok Koyu Laci Yazı
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }
}

class _BottomAuthLinks extends StatelessWidget {
  const _BottomAuthLinks({
    required this.loading,
    required this.onRegisterTap,
  });

  final bool loading;
  final VoidCallback onRegisterTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.center,
        spacing: 6,
        runSpacing: 4,
        children: [
          const Text(
            'Hesabınız yok mu?',
            style: TextStyle(
              color: Color(0xff94A3B8), // Daha nötr
              fontSize: 14,
            ),
          ),
          TextButton(
            onPressed: loading ? null : onRegisterTap,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xff1CC7C9), // Altın yerine Turkuaz link vurgusu
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            ),
            child: const Text(
              'Kayıt olun',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityNote extends StatelessWidget {
  const _SecurityNote();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(
          Icons.verified_user_outlined,
          color: Color(0xff6B7C93),
          size: 16,
        ),
        SizedBox(width: 8),
        Text(
          'Verileriniz güvenli şekilde korunur.',
          style: TextStyle(
            color: Color(0xff6B7C93),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}