import 'package:flutter/material.dart';
import 'features/auth/presentation/pages/splash_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/cadre/presentation/pages/cadre_main_nav.dart';
import 'features/officer/presentation/pages/officer_main_nav.dart';

void main() {
  runApp(const RadarJentikApp());
}

class RadarJentikApp extends StatelessWidget {
  const RadarJentikApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Radar Jentik',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[50],
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashPage(),
        '/login': (context) => const LoginPage(),
        '/cadre': (context) => const CadreMainNav(),
        '/officer': (context) => const OfficerMainNav(),
      },
    );
  }
}