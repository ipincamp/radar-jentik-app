import 'package:flutter/material.dart';
import 'gis_map/presentation/pages/zonation_map_page.dart';
import 'sync_dashboard/presentation/pages/sync_dashboard_page.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 1; // Default ke Peta

  final List<Widget> _pages = [
    const SyncDashboardPage(), // Tab 0: Beranda (Sinkronisasi)
    const ZonationMapPage(),   // Tab 1: Peta
    const Center(child: Text("Halaman Profil")), // Tab 2: Profil
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF143B59), // Warna biru gelap mockup
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Beranda"),
          BottomNavigationBarItem(icon: Icon(Icons.location_on), label: "Peta"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
        ],
      ),
    );
  }
}