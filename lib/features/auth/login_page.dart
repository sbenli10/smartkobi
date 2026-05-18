import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../home/home_shell.dart';
import 'register_page.dart';

enum LoginStyle {
  corporateSaaS,   // 💼 temiz, kurumsal, trust-first
  startupModern,   // 🚀 enerjik, gradient, playful
  figmaConcept,    // 🎨 spacing + type scale + premium composition
  glassPremium,    // 🔥 glassmorphism + blur + glow
  darkPro,         // 🌙 koyu, neon accent, high-contrast
}

class LoginPagePremium extends StatefulWidget {
  const LoginPagePremium({super.key, required this.style});
  final LoginStyle style;

  @override
  State<LoginPagePremium> createState() => _LoginPagePremiumState();
}

class _LoginPagePremiumState extends State<LoginPagePremium> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _loading = false;
  bool _obscure = true;

  late final AnimationController _intro;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
    _fade = CurvedAnimation(parent: _intro, curve: Curves.easeOutCubic);
    _slide = Tween(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _intro, curve: Curves.easeOutCubic));
    _intro.forward();
  }

  @override
  void dispose() {
    _intro.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
  final email = _email.text.trim();

  if (email.isEmpty || !email.contains("@")) {
    _showError("Önce geçerli bir e-posta giriniz.");
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
        content: Text("Şifre sıfırlama linki e-posta adresinize gönderildi."),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    _showError("Şifre sıfırlama başarısız.");
  }
}

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );

      if (!mounted) return;

      if (response.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Giriş başarılı. Dashboard yükleniyor..."),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 650));
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomeShell()),
        );
      }
    } on AuthException catch (e) {
      _showError(_mapAuthError(e.message));
    } catch (_) {
      _showError("Beklenmeyen bir sistem hatası oluştu.");
    }

    if (mounted) setState(() => _loading = false);
  }

  String _mapAuthError(String message) {
    if (message.contains("Invalid login credentials")) return "E-posta veya şifre hatalı.";
    if (message.contains("Email not confirmed")) return "E-posta adresinizi doğrulamanız gerekiyor.";
    return message;
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
    final spec = _LoginVisualSpec.of(context, widget.style);

    return Scaffold(
      body: Stack(
        children: [
          _PremiumBackground(spec: spec),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: FadeTransition(
                  opacity: _fade,
                  child: SlideTransition(
                    position: _slide,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: _AuthCard(
                        spec: spec,
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _BrandHeader(spec: spec),
                              const SizedBox(height: 26),

                              TextFormField(
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.username, AutofillHints.email],
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return "E-posta adresinizi giriniz";
                                  if (!v.contains("@")) return "Geçerli bir e-posta giriniz";
                                  return null;
                                },
                                decoration: InputDecoration(
                                  labelText: "E-posta",
                                  prefixIcon: const Icon(Icons.email_outlined),
                                ),
                              ),
                              const SizedBox(height: 16),

                              TextFormField(
                                controller: _password,
                                obscureText: _obscure,
                                autofillHints: const [AutofillHints.password],
                                onFieldSubmitted: (_) => _loading ? null : _login(),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return "Şifre giriniz";
                                  if (v.length < 6) return "Şifre en az 6 karakter olmalı";
                                  return null;
                                },
                                decoration: InputDecoration(
                                  labelText: "Şifre",
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    tooltip: _obscure ? "Şifreyi göster" : "Şifreyi gizle",
                                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                                    onPressed: () => setState(() => _obscure = !_obscure),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 14),
                              _BelowFieldsRow(
                                spec: spec,
                                onForgotPassword: _resetPassword,
                              ),
                              const SizedBox(height: 18),

                              _PrimaryButton(
                                spec: spec,
                                loading: _loading,
                                onPressed: _loading ? null : _login,
                                label: "Giriş Yap",
                              ),

                              const SizedBox(height: 18),
                              _DividerOr(spec: spec),
                              const SizedBox(height: 12),

                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const RegisterPage()),
                                  );
                                },
                                child: Text(
                                  "Hesap oluştur",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: spec.linkColor,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),
                              Text(
                                "🔒 Tüm verileriniz uçtan uca şifreleme ile korunur.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: spec.subtleTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
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

/// ---------- UI Building Blocks ----------

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.spec});
  final _LoginVisualSpec spec;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 74,
          width: 74,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: spec.logoGradient,
            boxShadow: [
              BoxShadow(
                color: spec.glowColor.withOpacity(spec.style == LoginStyle.corporateSaaS ? 0.14 : 0.24),
                blurRadius: 18,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Icon(spec.logoIcon, color: Colors.white, size: 34),
        ),
        const SizedBox(height: 14),
        Text(
          "SmartKOBİ",
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: spec.titleColor,
                letterSpacing: -0.2,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          spec.subtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: spec.subtleTextColor,
                height: 1.35,
              ),
        ),
      ],
    );
  }
}

class _BelowFieldsRow extends StatelessWidget {
  const _BelowFieldsRow({
    required this.spec,
    required this.onForgotPassword,
  });

  final _LoginVisualSpec spec;
  final VoidCallback onForgotPassword;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.verified_user_outlined,
            size: 16, color: spec.subtleTextColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            spec.trustLine,
            style: TextStyle(
              fontSize: 12.5,
              color: spec.subtleTextColor,
            ),
          ),
        ),
        TextButton(
          onPressed: onForgotPassword,
          child: Text(
            "Şifremi unuttum",
            style: TextStyle(
              color: spec.linkColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _DividerOr extends StatelessWidget {
  const _DividerOr({required this.spec});
  final _LoginVisualSpec spec;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: spec.dividerColor)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text("veya", style: TextStyle(color: spec.subtleTextColor)),
        ),
        Expanded(child: Divider(color: spec.dividerColor)),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.spec,
    required this.loading,
    required this.onPressed,
    required this.label,
  });

  final _LoginVisualSpec spec;
  final bool loading;
  final VoidCallback? onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 120),
      scale: loading ? 0.985 : 1,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: spec.ctaGradient,
          boxShadow: [
            BoxShadow(
              color: spec.glowColor.withOpacity(spec.style == LoginStyle.corporateSaaS ? 0.18 : 0.26),
              blurRadius: 18,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: loading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                )
              : Text(
                  label,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                ),
        ),
      ),
    );
  }
}

class _AuthCard extends StatelessWidget {
  const _AuthCard({required this.spec, required this.child});
  final _LoginVisualSpec spec;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.fromLTRB(26, 26, 26, 22),
      decoration: BoxDecoration(
        color: spec.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: spec.cardBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(spec.style == LoginStyle.corporateSaaS ? 0.10 : 0.16),
            blurRadius: 28,
            offset: const Offset(0, 16),
          )
        ],
      ),
      child: child,
    );

    if (spec.useGlass) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: card,
        ),
      );
    }
    return card;
  }
}

class _PremiumBackground extends StatelessWidget {
  const _PremiumBackground({required this.spec});
  final _LoginVisualSpec spec;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: spec.backgroundGradient),
      child: Stack(
        children: [
          // light blobs
          Positioned(
            top: -120,
            right: -90,
            child: _Blob(color: Colors.white.withOpacity(spec.blobOpacityA), size: 260),
          ),
          Positioned(
            bottom: -140,
            left: -110,
            child: _Blob(color: Colors.white.withOpacity(spec.blobOpacityB), size: 320),
          ),
          if (spec.style == LoginStyle.figmaConcept || spec.style == LoginStyle.startupModern)
            Positioned(
              top: 120,
              left: -60,
              child: _Blob(color: Colors.white.withOpacity(0.05), size: 180),
            ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

/// ---------- Visual Spec (5 Style) ----------

class _LoginVisualSpec {
  _LoginVisualSpec({
    required this.style,
    required this.backgroundGradient,
    required this.cardColor,
    required this.cardBorderColor,
    required this.titleColor,
    required this.subtleTextColor,
    required this.linkColor,
    required this.dividerColor,
    required this.ctaGradient,
    required this.logoGradient,
    required this.glowColor,
    required this.logoIcon,
    required this.subtitle,
    required this.trustLine,
    required this.useGlass,
    required this.blobOpacityA,
    required this.blobOpacityB,
    required this.snackColor,
  });

  final LoginStyle style;

  final Gradient backgroundGradient;
  final Color cardColor;
  final Color cardBorderColor;

  final Color titleColor;
  final Color subtleTextColor;
  final Color linkColor;
  final Color dividerColor;

  final Gradient ctaGradient;
  final Gradient logoGradient;

  final Color glowColor;
  final IconData logoIcon;

  final String subtitle;
  final String trustLine;

  final bool useGlass;
  final double blobOpacityA;
  final double blobOpacityB;

  final Color snackColor;

  static _LoginVisualSpec of(BuildContext context, LoginStyle style) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // defaults (theme-aware)
    Color title = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    Color subtle = isDark ? Colors.white.withOpacity(0.70) : Colors.black.withOpacity(0.55);
    Color divider = isDark ? Colors.white.withOpacity(0.10) : Colors.black.withOpacity(0.08);

    switch (style) {
      case LoginStyle.corporateSaaS:
        return _LoginVisualSpec(
          style: style,
          backgroundGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF6F7FB), Color(0xFFEEF2FF)],
          ),
          cardColor: isDark ? const Color(0xFF0F1A30) : Colors.white,
          cardBorderColor: isDark ? Colors.white.withOpacity(0.10) : Colors.black.withOpacity(0.06),
          titleColor: title,
          subtleTextColor: subtle,
          linkColor: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E3A8A),
          dividerColor: divider,
          ctaGradient: const LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)]),
          logoGradient: const LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF60A5FA)]),
          glowColor: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
          logoIcon: Icons.business_center_outlined,
          subtitle: "İşletmenizi güvenle yönetin.\nKurumsal, hızlı ve güvenilir.",
          trustLine: "Kurumsal güvenlik standartları (SOC2/ISO uyumlu altyapı).",
          useGlass: false,
          blobOpacityA: 0.10,
          blobOpacityB: 0.08,
          snackColor: isDark ? const Color(0xFF1F2937) : const Color(0xFF0F172A),
        );

      case LoginStyle.startupModern:
        return _LoginVisualSpec(
          style: style,
          backgroundGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [Color(0xFF0B1220), Color(0xFF111C3A), Color(0xFF1B2A55)]
                : const [Color(0xFFEEF2FF), Color(0xFFE0E7FF), Color(0xFFDBEAFE)],
          ),
          cardColor: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
          cardBorderColor: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.06),
          titleColor: title,
          subtleTextColor: subtle,
          linkColor: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4F46E5),
          dividerColor: divider,
          ctaGradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF06B6D4)]),
          logoGradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF06B6D4)]),
          glowColor: const Color(0xFF06B6D4),
          logoIcon: Icons.auto_graph_outlined,
          subtitle: "KOBİ’ler için modern finans ve operasyon yönetimi.\nDakikalar içinde başlayın.",
          trustLine: "Güvenli oturum + şifrelenmiş iletişim (TLS/HTTPS).",
          useGlass: isDark, // dark’ta glass çok iyi duruyor
          blobOpacityA: isDark ? 0.08 : 0.12,
          blobOpacityB: isDark ? 0.06 : 0.10,
          snackColor: isDark ? const Color(0xFF111827) : const Color(0xFF0F172A),
        );

      case LoginStyle.figmaConcept:
        return _LoginVisualSpec(
          style: style,
          backgroundGradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [Color(0xFF071023), Color(0xFF0B1633), Color(0xFF0E2047)]
                : const [Color(0xFFF8FAFF), Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
          ),
          cardColor: isDark ? Colors.white.withOpacity(0.07) : Colors.white,
          cardBorderColor: isDark ? Colors.white.withOpacity(0.14) : Colors.black.withOpacity(0.06),
          titleColor: title,
          subtleTextColor: subtle,
          linkColor: isDark ? const Color(0xFF67E8F9) : const Color(0xFF2563EB),
          dividerColor: divider,
          ctaGradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF7C3AED)]),
          logoGradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF7C3AED)]),
          glowColor: const Color(0xFF7C3AED),
          logoIcon: Icons.shield_outlined,
          subtitle: "Premium deneyim: net tipografi, doğru boşluklar,\nparlak CTA ve güven mesajı.",
          trustLine: "Oturum açma işlemleri denetlenir ve anomali tespiti yapılır.",
          useGlass: true,
          blobOpacityA: isDark ? 0.09 : 0.12,
          blobOpacityB: isDark ? 0.07 : 0.10,
          snackColor: isDark ? const Color(0xFF0B1220) : const Color(0xFF0F172A),
        );

      case LoginStyle.glassPremium:
        return _LoginVisualSpec(
          style: style,
          backgroundGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B1220), Color(0xFF121D3D), Color(0xFF1B2A55)],
          ),
          cardColor: Colors.white.withOpacity(0.08),
          cardBorderColor: Colors.white.withOpacity(0.14),
          titleColor: const Color(0xFFF8FAFC),
          subtleTextColor: Colors.white.withOpacity(0.72),
          linkColor: const Color(0xFF67E8F9),
          dividerColor: Colors.white.withOpacity(0.12),
          ctaGradient: const LinearGradient(colors: [Color(0xFF22D3EE), Color(0xFF6366F1)]),
          logoGradient: const LinearGradient(colors: [Color(0xFF22D3EE), Color(0xFF6366F1)]),
          glowColor: const Color(0xFF22D3EE),
          logoIcon: Icons.diamond_outlined,
          subtitle: "Cam efekti + blur + glow.\nDaha premium bir ilk izlenim.",
          trustLine: "Güvenli oturum, cihaz bazlı güvenlik kontrolü.",
          useGlass: true,
          blobOpacityA: 0.10,
          blobOpacityB: 0.08,
          snackColor: const Color(0xFF0B1220),
        );

      case LoginStyle.darkPro:
        return _LoginVisualSpec(
          style: style,
          backgroundGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF050816), Color(0xFF0B1220), Color(0xFF111C3A)],
          ),
          cardColor: const Color(0xFF0F1A30),
          cardBorderColor: Colors.white.withOpacity(0.12),
          titleColor: const Color(0xFFF8FAFC),
          subtleTextColor: Colors.white.withOpacity(0.70),
          linkColor: const Color(0xFFA78BFA),
          dividerColor: Colors.white.withOpacity(0.12),
          ctaGradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFFEC4899)]),
          logoGradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFFEC4899)]),
          glowColor: const Color(0xFFEC4899),
          logoIcon: Icons.nightlight_round,
          subtitle: "Koyu tema, yüksek kontrast.\nProfesyonel ve güçlü bir his.",
          trustLine: "Şifreleme + güvenli oturum + rate limit koruması.",
          useGlass: false,
          blobOpacityA: 0.06,
          blobOpacityB: 0.05,
          snackColor: const Color(0xFF111827),
        );
    }
  }
}
