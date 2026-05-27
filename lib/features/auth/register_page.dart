import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../home/home_shell.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _businessNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _businessNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final supabase = Supabase.instance.client;
      
      // 1. Supabase Kimlik Doğrulama (Auth) Kaydı
      final authResponse = await supabase.auth.signUp(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );

      final user = authResponse.user;
      if (user != null) {
        // 2. Kullanıcı Profil ve İşletme Bilgilerini Veritabanına Yazma
        await supabase.from('profiles').insert({
          'id': user.id,
          'full_name': _fullNameCtrl.text.trim(),
          'business_name': _businessNameCtrl.text.trim(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeShell()),
        (route) => false,
      );
    } on AuthException catch (error) {
      _showError(error.message);
    } catch (error) {
      _showError('Kayıt esnasında bir hata oluştu. Lütfen tekrar deneyin.');
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xff1CC7C9), size: 14),
                                SizedBox(width: 6),
                                Text(
                                  'Geri Dön',
                                  style: TextStyle(
                                    color: Color(0xff1CC7C9),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _GlassRegisterPanel(
                        formKey: _formKey,
                        fullNameCtrl: _fullNameCtrl,
                        businessNameCtrl: _businessNameCtrl,
                        emailCtrl: _emailCtrl,
                        passCtrl: _passwordCtrl,
                        loading: _loading,
                        obscure: _obscure,
                        onToggleObscure: () => setState(() => _obscure = !_obscure),
                        onSignUp: _signUp,
                      ),
                      const SizedBox(height: 32),
                      _BottomLoginLink(
                        loading: _loading,
                        onLoginTap: () => Navigator.pop(context),
                      ),
                      const SizedBox(height: 24),
                      const _PrivacyNote(),
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
// HELPER WIDGETS FOR PREMIUM TURQUOISE FINTECH DESIGN (REGISTER)
// ============================================================================

class _TurquoiseAuthBackground extends StatelessWidget {
  const _TurquoiseAuthBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
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

class _GlassRegisterPanel extends StatelessWidget {
  const _GlassRegisterPanel({
    required this.formKey,
    required this.fullNameCtrl,
    required this.businessNameCtrl,
    required this.emailCtrl,
    required this.passCtrl,
    required this.loading,
    required this.obscure,
    required this.onToggleObscure,
    required this.onSignUp,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController fullNameCtrl;
  final TextEditingController businessNameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final bool loading;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final VoidCallback onSignUp;

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
              'SmartKOBİ’ye katılın',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'İşletmenizi dijital olarak takip etmeye bugün başlayın.',
              style: TextStyle(
                color: Color(0xff94A3B8),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            
            _AuthInput(
              controller: fullNameCtrl,
              hint: 'Ad Soyad',
              icon: Icons.person_outline_rounded,
              enabled: !loading,
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Adınızı ve soyadınızı girin';
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            _AuthInput(
              controller: businessNameCtrl,
              hint: 'İşletme adı',
              icon: Icons.business_outlined,
              enabled: !loading,
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'İşletmenizin adını girin';
                return null;
              },
            ),
            const SizedBox(height: 16),
            
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
              validator: (value) {
                if (value == null || value.isEmpty) return 'Lütfen bir şifre belirleyin';
                if (value.length < 6) return 'Şifre en az 6 karakter olmalı';
                return null;
              },
              onFieldSubmitted: (_) => loading ? null : onSignUp(),
            ),
            const SizedBox(height: 32),
            
            _PrimaryRegisterButton(
              label: 'Kayıt Ol',
              loading: loading,
              onPressed: onSignUp,
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
          color: Color(0xff16324A),
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
            borderSide: const BorderSide(color: Color(0xff1CC7C9), width: 1.5),
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

class _PrimaryRegisterButton extends StatelessWidget {
  const _PrimaryRegisterButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  final String label;
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
            : Text(
                label,
                style: const TextStyle(
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

class _BottomLoginLink extends StatelessWidget {
  const _BottomLoginLink({
    required this.loading,
    required this.onLoginTap,
  });

  final bool loading;
  final VoidCallback onLoginTap;

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
            'Zaten hesabınız var mı?',
            style: TextStyle(
              color: Color(0xff94A3B8),
              fontSize: 14,
            ),
          ),
          TextButton(
            onPressed: loading ? null : onLoginTap,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xff1CC7C9), // Turkuaz link
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            ),
            child: const Text(
              'Giriş yapın',
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

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        Icon(
          Icons.verified_user_outlined,
          color: Color(0xff5B6B7F),
          size: 20,
        ),
        SizedBox(height: 10),
        Text(
          'Kayıt olarak işletme bilgilerinizin güvenli şekilde\nsaklanmasını ve işlenmesini kabul etmiş olursunuz.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xff6B7C93),
            fontSize: 11,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}