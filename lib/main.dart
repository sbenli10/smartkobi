import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);
  await dotenv.load();
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? 'https://xxx.supabase.co',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '....',
  );
  runApp(const SmartKobiApp());
}

class SmartKobiApp extends StatelessWidget {
  const SmartKobiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartKOBİ',
      theme: AppTheme.darkTheme,
      home: const LoginPagePremium(),
    );
  }
}
