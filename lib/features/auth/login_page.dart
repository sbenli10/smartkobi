import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../home/home_shell.dart';
import 'register_page.dart';
import 'widgets/premium_auth_components.dart';

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
          backgroundColor: Color(0xff22C55E),
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
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );

      if (!mounted) {
        return;
      }

      if (response.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Giriş başarılı. Ana ekran açılıyor.'),
            backgroundColor: Color(0xff22C55E),
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
      final msg = e.message.contains('Invalid login credentials')
          ? 'E-posta adresiniz veya şifreniz hatalı.'
          : e.message.contains('Email not confirmed')
              ? 'E-posta adresinizi doğrulamanız gerekiyor.'
              : 'Bağlantı sırasında bir sorun oluştu. Lütfen tekrar deneyin.';
      _showError(msg);
    } catch (e) {
      _showError('Bağlantı sırasında bir sorun oluştu. Lütfen tekrar deneyin.');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
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
    return PremiumAuthScaffold(
      child: PremiumAuthCard(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: _loading ? null : () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Color(0xff5A54D6),
                    size: 20,
                  ),
                ),
              ),
              const DoorIllustration(),
              const SizedBox(height: 12),
              const Text(
                'Giriş',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xff2E2E3A),
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Hesabınıza giriş yapın ve işletmenizi\ntek panelden yönetmeye devam edin.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xff7A7A8C),
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              const FieldLabel('E-posta'),
              const SizedBox(height: 8),
              AuthLineField(
                controller: _emailCtrl,
                hintText: 'ornek@smartkobi.com',
                enabled: !_loading,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) {
                    return 'E-posta adresinizi girin';
                  }
                  if (!text.contains('@') || !text.contains('.')) {
                    return 'Geçerli bir e-posta adresi girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              const FieldLabel('Şifre'),
              const SizedBox(height: 8),
              AuthLineField(
                controller: _passCtrl,
                hintText: 'Şifreniz',
                enabled: !_loading,
                obscureText: _obscure,
                suffixIcon: _obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                onSuffixTap: () => setState(() => _obscure = !_obscure),
                onFieldSubmitted: (_) => _loading ? null : _login(),
                validator: (value) {
                  final text = value ?? '';
                  if (text.isEmpty) {
                    return 'Şifrenizi girin';
                  }
                  if (text.length < 6) {
                    return 'Şifre en az 6 karakter olmalı';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _loading ? null : _resetPassword,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xff5A54D6),
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Şifremi unuttum?',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              CardActionButton(
                label: 'Giriş yap',
                filled: true,
                loading: _loading,
                onPressed: _loading ? null : _login,
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Hesabınız yok mu?',
                    style: TextStyle(
                      color: Color(0xff8E8EA0),
                      fontSize: 14,
                    ),
                  ),
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const RegisterPage()),
                            );
                          },
                    child: const Text(
                      'Kayıt ol',
                      style: TextStyle(
                        color: Color(0xff5A54D6),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
