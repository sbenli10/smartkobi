import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../home/home_shell.dart';
import 'widgets/premium_auth_components.dart';

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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    try {
      final supabase = Supabase.instance.client;
      final authResponse = await supabase.auth.signUp(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );

      final user = authResponse.user;
      if (user != null) {
        await supabase.from('profiles').insert({
          'id': user.id,
          'full_name': _fullNameCtrl.text.trim(),
          'business_name': _businessNameCtrl.text.trim(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kayıt başarılı. SmartKOBİ açılıyor.'),
          backgroundColor: Color(0xff22C55E),
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeShell()),
        (route) => false,
      );
    } on AuthException catch (error) {
      _showError('Kayıt işlemi tamamlanamadı. Lütfen bilgilerinizi kontrol edip tekrar deneyin.');
    } catch (_) {
      _showError('Kayıt sırasında bir sorun oluştu. Lütfen tekrar deneyin.');
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
              const PhoneIllustration(),
              const SizedBox(height: 12),
              const Text(
                'Kayıt ol',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xff2E2E3A),
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'İşletmenizi dijitale taşıyın,\ngelir ve stok takibini hızlıca başlatın.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xff7A7A8C),
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              const FieldLabel('Ad soyad'),
              const SizedBox(height: 8),
              AuthLineField(
                controller: _fullNameCtrl,
                hintText: 'Adınızı ve soyadınızı girin',
                enabled: !_loading,
                validator: (value) {
                  if ((value?.trim() ?? '').isEmpty) {
                    return 'Adınızı ve soyadınızı girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              const FieldLabel('İşletme adı'),
              const SizedBox(height: 8),
              AuthLineField(
                controller: _businessNameCtrl,
                hintText: 'İşletme adını girin',
                enabled: !_loading,
                validator: (value) {
                  if ((value?.trim() ?? '').isEmpty) {
                    return 'İşletme adını girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
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
                controller: _passwordCtrl,
                hintText: 'Şifrenizi girin',
                enabled: !_loading,
                obscureText: _obscure,
                suffixIcon: _obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                onSuffixTap: () => setState(() => _obscure = !_obscure),
                onFieldSubmitted: (_) => _loading ? null : _signUp(),
                validator: (value) {
                  final text = value ?? '';
                  if (text.isEmpty) {
                    return 'Lütfen bir şifre belirleyin';
                  }
                  if (text.length < 6) {
                    return 'Şifre en az 6 karakter olmalı';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              CardActionButton(
                label: 'Kayıt ol',
                filled: true,
                loading: _loading,
                onPressed: _loading ? null : _signUp,
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Zaten hesabınız var mı?',
                    style: TextStyle(
                      color: Color(0xff8E8EA0),
                      fontSize: 14,
                    ),
                  ),
                  TextButton(
                    onPressed: _loading ? null : () => Navigator.pop(context),
                    child: const Text(
                      'Giriş yap',
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
