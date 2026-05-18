// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth/reset_password_page.dart';
import 'features/auth/login_page.dart';
import 'home/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://mgeenfliuqqrbizqndnu.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1nZWVuZmxpdXFxcmJpenFuZG51Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI3NjQ4NDcsImV4cCI6MjA3ODM0MDg0N30.2cg3Rt_MJlbOkF21FM_vWKjMMrkwNj_KAh1h-zCThis',
  );

  runApp(const SmartKobiApp());
}

class SmartKobiApp extends StatelessWidget {
  const SmartKobiApp({super.key});

  static const _seedColor = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartKobi ERP',

      theme: _AppTheme.light(_seedColor),
      darkTheme: _AppTheme.dark(_seedColor),
      themeMode: ThemeMode.system,

      routes: {
        '/reset-password': (_) => const ResetPasswordPage(),
        '/login': (_) =>
            LoginPagePremium(style: LoginStyle.figmaConcept),
      },

      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      return const HomeShell();
    }

    // Burada istediğin stile geçebilirsin
    return LoginPagePremium(style: LoginStyle.figmaConcept);
  }
}

class _AppTheme {
  static ThemeData light(Color seed) {
    const surface = Color(0xFFF6F7FB);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: surface,

      // ✅ DOĞRU YER: ThemeData içinde olmalı
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        },
      ),

      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.06)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.06)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: seed, width: 1.6),
        ),
      ),

      textTheme: const TextTheme(
        headlineSmall: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        bodyMedium: TextStyle(fontSize: 14),
      ),
    );
  }

  static ThemeData dark(Color seed) {
    const background = Color(0xFF0B1220);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: background,

      // ✅ DOĞRU YER: ThemeData içinde olmalı
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        },
      ),

      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: seed, width: 1.6),
        ),
      ),

      textTheme: const TextTheme(
        headlineSmall: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        bodyMedium: TextStyle(fontSize: 14),
      ),
    );
  }
}
