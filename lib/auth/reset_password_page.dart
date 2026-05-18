import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../home/home_shell.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _passwordController = TextEditingController();
  bool _loading = false;

  Future<void> _updatePassword() async {
    final password = _passwordController.text.trim();

    if (password.length < 6) {
      _showError("Şifre en az 6 karakter olmalı.");
      return;
    }

    setState(() => _loading = true);

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: password),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Şifre başarıyla güncellendi."),
          backgroundColor: Colors.green,
        ),
      );

      await Future.delayed(const Duration(seconds: 1));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeShell(), // const kaldırdık
        ),
      );
    } catch (e) {
      _showError("Şifre güncellenemedi.");
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Yeni Şifre Oluştur",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Yeni Şifre",
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading ? null : _updatePassword,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text("Şifreyi Güncelle"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}