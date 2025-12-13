import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'features/gis_map/presentation/pages/zonation_map_page.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mobile GIS-IDW Cilongok',
      debugShowCheckedModeBanner: kDebugMode,

      // Konfigurasi Tema
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
          foregroundColor: Colors.white,
        ),
      ),

      // Halaman yang pertama kali dibuka
      home: const ZonationMapPage(),
    );
  }
}
