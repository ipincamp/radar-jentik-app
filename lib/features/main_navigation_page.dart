import 'package:flutter/material.dart';
import 'home/presentation/pages/home_page.dart';
import 'gis_map/presentation/pages/zonation_map_page.dart';
import 'sync_dashboard/presentation/pages/sync_dashboard_page.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  // Fungsi callback agar halaman Home bisa memicu pindah tab navigasi bawah
  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // List halaman disesuaikan agar menampung susunan navigasi baru
    final List<Widget> pages = [
      HomePage(
        onNavigateToTab: _navigateToTab,
      ), // Tab 0: Dashboard Beranda Utama
      const ZonationMapPage(), // Tab 1: Peta Visualisasi Zonasi
      const SyncDashboardPage(), // Tab 2: Halaman Sinkronisasi & Riwayat Luring
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(
          0xFF143B59,
        ), // Konsisten menggunakan warna biru mockup utama
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: "Beranda",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.map_rounded), label: "Peta"),
          BottomNavigationBarItem(
            icon: Icon(Icons.cloud_sync_rounded),
            label: "Sinkronisasi",
          ),
        ],
      ),
    );
  }
}
