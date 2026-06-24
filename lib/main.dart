import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'features/auth/presentation/pages/splash_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/register_page.dart';
import 'features/cadre/presentation/pages/cadre_main_nav.dart';
import 'features/officer/presentation/pages/officer_main_nav.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  runApp(const RadarJentikApp());
}

class RadarJentikApp extends StatelessWidget {
  const RadarJentikApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Radar Jentik',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',

      routes: {
        '/': (context) => const SplashPage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/cadre': (context) => const CadreMainNav(),
        '/officer': (context) => const OfficerMainNav(),
      },
    );
  }
}
