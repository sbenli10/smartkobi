import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../home/home_shell.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _businessController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _businessController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _getAuthErrorMessage(Object error) {
    if (error is AuthException) {
      switch (error.statusCode) {
        case '400':
          if (error.message.contains('password')) {
            return 'Girilen şifre çok zayıf veya geçersiz.';
          }
          return 'Geçersiz e-posta veya şifre biçimi.';
        case '422':
          return 'E-posta adresi biçimi hatalı.';
        case '429':
          return 'Çok fazla istek yapıldı. Lütfen biraz bekleyin.';
        default:
          if (error.message.contains('already registered') ||
              error.message.contains('unique_user_business')) {
            return 'Bu e-posta adresi ile zaten bir hesap var.';
          }
          return error.message;
      }
    } else if (error is PostgrestException) {
      if (error.code == '23505') {
        return 'Bu bilgilere ait kayıt zaten mevcut.';
      }
      return 'Veritabanı bağlantı hatası oluştu. Lütfen tekrar deneyin.';
    }
    final errStr = error.toString().toLowerCase();
    if (errStr.contains('socketexception') || errStr.contains('network')) {
      return 'İnternet bağlantısı kurulamadı. Bağlantınızı kontrol edin.';
    }
    return 'Beklenmedik bir hata oluştu: ${error.toString()}';
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final authResponse = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {
          'business_name': _businessController.text.trim(),
        },
      );
      if (authResponse.user == null) {
        throw const AuthException(
          'Kullanıcı profili oluşturulamadı, lütfen tekrar deneyin.',
        );
      }
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Hesabınız ve işletmeniz başarıyla oluşturuldu!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeShell()),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(_getAuthErrorMessage(error))),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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

              final card = _RegisterCardShell(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Hesap Oluştur',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppColors.navy900,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'SmartKOBİ’ye katılarak işletmenizi daha düzenli ve güvenli şekilde yönetin.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: const Color(0xFF5E6B7A),
                              height: 1.5,
                            ),
                      ),
                      const SizedBox(height: 28),
                      _RegisterTextField(
                        controller: _businessController,
                        label: 'İşletme Adı',
                        hint: 'İşletme veya firma adınızı girin',
                        icon: Icons.business_outlined,
                        enabled: !_isLoading,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'İşletme adını girin';
                          }
                          if (value.trim().length < 3) {
                            return 'İşletme adı en az 3 karakter olmalı';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      _RegisterTextField(
                        controller: _emailController,
                        label: 'E-posta adresiniz',
                        hint: 'ornek@isletme.com',
                        icon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !_isLoading,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'E-posta adresinizi girin';
                          }
                          if (!RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(value.trim())) {
                            return 'Geçerli bir e-posta adresi girin';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      _RegisterPasswordField(
                        controller: _passwordController,
                        obscure: _obscure,
                        onToggleObscure: () => setState(() => _obscure = !_obscure),
                        enabled: !_isLoading,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Şifrenizi girin';
                          }
                          if (value.length < 6) {
                            return 'Şifre en az 6 karakter olmalı';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      _PrimaryRegisterButton(
                        loading: _isLoading,
                        onPressed: _isLoading ? null : _register,
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
                              'Zaten hesabınız var mı?',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFF667387),
                                  ),
                            ),
                            TextButton(
                              onPressed: _isLoading ? null : () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.navy900,
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                              ),
                              child: const Text(
                                'Giriş yapın',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const _RegisterSecurityNote(),
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
                                  child: _RegisterShowcase(),
                                ),
                              ),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 480),
                                child: card,
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              const _CompactRegisterBrandBlock(),
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

class _RegisterShowcase extends StatelessWidget {
  const _RegisterShowcase();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const _RegisterBrandBadge(),
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
            _FeatureCard(
              icon: Icons.shield_outlined,
              title: 'Güvenli Erişim',
              subtitle: 'İşletme verileriniz yalnızca size aittir.',
            ),
            _FeatureCard(
              icon: Icons.auto_graph_outlined,
              title: 'Akıllı Başlangıç',
              subtitle: 'İşletme profilinizi tamamladıkça analizleriniz güçlenir.',
            ),
            _FeatureCard(
              icon: Icons.business_center_outlined,
              title: 'Tek Merkez',
              subtitle: 'Finans, cari, stok ve destek süreçlerinizi tek yerden yönetin.',
            ),
          ],
        ),
      ],
    );
  }
}

class _CompactRegisterBrandBlock extends StatelessWidget {
  const _CompactRegisterBrandBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _RegisterBrandBadge(),
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
          'KOBİ’niz için akıllı yönetim paneli.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: const Color(0xFF5F6B79),
              ),
        ),
      ],
    );
  }
}

class _RegisterBrandBadge extends StatelessWidget {
  const _RegisterBrandBadge();

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

class _RegisterCardShell extends StatelessWidget {
  const _RegisterCardShell({required this.child});

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

class _RegisterTextField extends StatelessWidget {
  const _RegisterTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.enabled,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool enabled;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
        color: AppColors.navy900,
        fontWeight: FontWeight.w600,
      ),
      decoration: _registerInputDecoration(
        label: label,
        hint: hint,
        icon: icon,
      ),
    );
  }
}

class _RegisterPasswordField extends StatelessWidget {
  const _RegisterPasswordField({
    required this.controller,
    required this.obscure,
    required this.onToggleObscure,
    required this.enabled,
    this.validator,
  });

  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final bool enabled;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: obscure,
      validator: validator,
      autofillHints: const [AutofillHints.password],
      style: const TextStyle(
        color: AppColors.navy900,
        fontWeight: FontWeight.w600,
      ),
      decoration: _registerInputDecoration(
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

InputDecoration _registerInputDecoration({
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

class _PrimaryRegisterButton extends StatelessWidget {
  const _PrimaryRegisterButton({
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
                'Hesap Oluştur',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}

class _RegisterSecurityNote extends StatelessWidget {
  const _RegisterSecurityNote();

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

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
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
