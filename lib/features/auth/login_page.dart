import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_colors.dart';
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
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Şifre sıfırlama bağlantısı e-posta adresinize gönderildi.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (_) {
      _showError('Şifre sıfırlama sırasında bir sorun oluştu. Lütfen tekrar deneyin.');
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      debugPrint(
        'Login denemesi basliyor: email=${_emailCtrl.text}, password=${_passCtrl.text}',
      );
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );
      debugPrint('Supabase login RESPONSE: $response');
      debugPrint('Kullanici: ${response.user}, Session: ${response.session}');

      if (!mounted) {
        return;
      }
      if (response.user != null) {
        debugPrint('Giriş başarılı, kullanıcı id: ${response.user!.id}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Giriş başarılı. Ana sayfa açılıyor...'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) {
          return;
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeShell()),
        );
      }
    } on AuthException catch (e) {
      debugPrint(
        'Supabase AuthException -- code: ${e.statusCode}, message: ${e.message}',
      );
      final msg = e.message.contains('Invalid login credentials')
          ? 'E-posta veya şifre hatalı.'
          : e.message.contains('Email not confirmed')
              ? 'E-posta adresinizi doğrulamanız gerekiyor.'
              : 'Bağlantı sırasında bir sorun oluştu. Lütfen tekrar deneyin.';
      _showError('$msg\n\nHata Detayı: ${e.statusCode} - ${e.message}');
    } catch (e, stack) {
      debugPrint('Diğer hata yakalandı: $e');
      debugPrint('$stack');
      _showError('Bağlantı sırasında bir sorun oluştu.\nHata: $e');
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF9FAFB),
              Color(0xFFF4F6F8),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 980;
              final horizontalPadding = constraints.maxWidth >= 1200
                  ? 48.0
                  : constraints.maxWidth >= 760
                      ? 28.0
                      : 18.0;

              final card = _LoginCardShell(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Giriş Yap',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppColors.navy900,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Hesabınıza giriş yaparak işletme verilerinize güvenle erişin.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: const Color(0xFF5E6B7A),
                              height: 1.5,
                            ),
                      ),
                      const SizedBox(height: 28),
                      _PremiumField(
                        controller: _emailCtrl,
                        label: 'E-posta adresiniz',
                        hint: 'ornek@isletme.com',
                        icon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        autofill: const [
                          AutofillHints.username,
                          AutofillHints.email,
                        ],
                        enabled: !_loading,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'E-posta adresinizi girin';
                          }
                          if (!value.trim().contains('@') ||
                              !value.trim().contains('.')) {
                            return 'Geçerli bir e-posta adresi girin';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      _PremiumPasswordField(
                        controller: _passCtrl,
                        obscure: _obscure,
                        onToggleObscure: () => setState(() => _obscure = !_obscure),
                        enabled: !_loading,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Şifrenizi girin';
                          }
                          if (value.length < 6) {
                            return 'Şifre en az 6 karakter olmalı';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _loading ? null : _login(),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _loading ? null : _resetPassword,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.navy800,
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                          ),
                          child: const Text(
                            'Şifremi Unuttum',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _PrimaryLoginButton(
                        loading: _loading,
                        onPressed: _loading ? null : _login,
                      ),
                      const SizedBox(height: 18),
                      Center(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          alignment: WrapAlignment.center,
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Text(
                              'Hesabınız yok mu?',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFF667387),
                                  ),
                            ),
                            TextButton(
                              onPressed: _loading
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const RegisterPage(),
                                        ),
                                      );
                                    },
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.navy900,
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                              ),
                              child: const Text(
                                'Kayıt olun',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const _SecurityFootnote(),
                    ],
                  ),
                ),
              );

              return Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 24,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(right: 36),
                                  child: _LoginShowcase(),
                                ),
                              ),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 470),
                                child: card,
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              const _CompactBrandBlock(),
                              const SizedBox(height: 24),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 460),
                                child: card,
                              ),
                            ],
                          ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LoginShowcase extends StatelessWidget {
  const _LoginShowcase();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const _BrandBadge(),
        const SizedBox(height: 28),
        Text(
          'SmartKOBİ',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: AppColors.navy900,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 12),
        Text(
          'KOBİ’niz için akıllı yönetim paneli.',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.navy800,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(
            'Finans, cari, stok, nakit akışı ve destek analizlerini tek ekranda yönetin.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF5F6B79),
                  height: 1.7,
                ),
          ),
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: const [
            _InfoPill(
              icon: Icons.shield_outlined,
              title: 'Güvenli Erişim',
              subtitle: 'Verilerinize yalnızca size özel güvenli erişim.',
            ),
            _InfoPill(
              icon: Icons.insights_outlined,
              title: 'Akıllı Özetler',
              subtitle: 'İşletmenizin durumunu hızla anlamanıza yardımcı olur.',
            ),
            _InfoPill(
              icon: Icons.business_center_outlined,
              title: 'Tek Merkez',
              subtitle: 'Finans, cari, stok ve analizlerinizi tek yerden yönetin.',
            ),
          ],
        ),
      ],
    );
  }
}

class _CompactBrandBlock extends StatelessWidget {
  const _CompactBrandBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _BrandBadge(),
        const SizedBox(height: 18),
        Text(
          'SmartKOBİ',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.navy900,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'İşletmenizi tek yerden yönetin.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: const Color(0xFF5F6B79),
              ),
        ),
      ],
    );
  }
}

class _BrandBadge extends StatelessWidget {
  const _BrandBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      width: 74,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE7EBF0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Center(
        child: Container(
          height: 52,
          width: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: AppColors.navy900,
          ),
          child: const Icon(
            Icons.hub_rounded,
            color: AppColors.gold400,
            size: 28,
          ),
        ),
      ),
    );
  }
}

class _LoginCardShell extends StatelessWidget {
  const _LoginCardShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7EBF0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B1B2E).withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PremiumField extends StatelessWidget {
  const _PremiumField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.enabled,
    this.keyboardType,
    this.autofill,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool enabled;
  final TextInputType? keyboardType;
  final List<String>? autofill;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      autofillHints: autofill,
      validator: validator,
      style: const TextStyle(
        color: AppColors.navy900,
        fontWeight: FontWeight.w600,
      ),
      decoration: _inputDecoration(
        label: label,
        hint: hint,
        icon: icon,
      ),
    );
  }
}

class _PremiumPasswordField extends StatelessWidget {
  const _PremiumPasswordField({
    required this.controller,
    required this.obscure,
    required this.onToggleObscure,
    required this.enabled,
    this.validator,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final bool enabled;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: obscure,
      autofillHints: const [AutofillHints.password],
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      style: const TextStyle(
        color: AppColors.navy900,
        fontWeight: FontWeight.w600,
      ),
      decoration: _inputDecoration(
        label: 'Şifreniz',
        hint: 'Şifrenizi girin',
        icon: Icons.lock_outline_rounded,
        suffix: IconButton(
          onPressed: enabled ? onToggleObscure : null,
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: const Color(0xFF5E6B7A),
          ),
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration({
  required String label,
  required String hint,
  required IconData icon,
  Widget? suffix,
}) {
  const borderColor = Color(0xFFD8E0E8);
  return InputDecoration(
    labelText: label,
    hintText: hint,
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    prefixIcon: Icon(icon, color: const Color(0xFF4D5A6B)),
    suffixIcon: suffix,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
    labelStyle: const TextStyle(
      color: Color(0xFF4F5D70),
      fontWeight: FontWeight.w600,
    ),
    hintStyle: const TextStyle(
      color: Color(0xFF97A4B3),
      fontWeight: FontWeight.w500,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: borderColor),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: borderColor),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Colors.redAccent),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: AppColors.navy800, width: 1.3),
    ),
  );
}

class _PrimaryLoginButton extends StatelessWidget {
  const _PrimaryLoginButton({
    required this.loading,
    required this.onPressed,
  });

  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.navy900,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Giriş Yap',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}

class _SecurityFootnote extends StatelessWidget {
  const _SecurityFootnote();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7EBF0)),
      ),
      child: Row(
        children: [
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: AppColors.navy900.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: AppColors.navy900,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Verileriniz güvenli şekilde korunur. İşletme verilerinize yalnızca siz erişebilirsiniz.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF5F6B79),
                    height: 1.5,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 208,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7EBF0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: AppColors.navy900.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.navy900),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.navy900,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF657285),
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}
