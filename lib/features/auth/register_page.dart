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
  final _businessController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
    void dispose() {
      _businessController.dispose();
      _emailController.dispose();
      _passwordController.dispose();
      super.dispose();
  }


Future<void> _register() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);

  try {
    final supabase = Supabase.instance.client;

    final authResponse = await supabase.auth.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (authResponse.user == null) {
      throw Exception("User oluşturulamadı");
    }

    // 🔥 Artık business logic database tarafında
    await supabase.rpc(
      'create_business_for_user',
      params: {
        'business_name': _businessController.text.trim(),
      },
    );

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeShell()),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Hata: $e")),
    );
  }

  if (mounted) {
    setState(() => _isLoading = false);
  }
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kayıt Ol")),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _businessController,
                    validator: (v) =>
                        v == null || v.isEmpty ? "İşletme adı giriniz" : null,
                    decoration: const InputDecoration(
                      labelText: "İşletme Adı",
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    validator: (v) =>
                        v == null || v.isEmpty ? "E-posta giriniz" : null,
                    decoration: const InputDecoration(
                      labelText: "E-posta",
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    validator: (v) =>
                        v == null || v.length < 6
                            ? "Şifre en az 6 karakter"
                            : null,
                    decoration: const InputDecoration(
                      labelText: "Şifre",
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text("Kayıt Ol"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}