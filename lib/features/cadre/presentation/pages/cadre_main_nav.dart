import 'package:flutter/material.dart';
import 'cadre_dashboard_page.dart';
import 'cadre_history_page.dart';
import '../../../gis_map/presentation/pages/zonation_map_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';

class CadreMainNav extends StatefulWidget {
  const CadreMainNav({Key? key}) : super(key: key);

  @override
  State<CadreMainNav> createState() => _CadreMainNavState();
}

class _CadreMainNavState extends State<CadreMainNav> {
  int _currentIndex = 0;

  // Menghubungkan class halaman asli ke masing-masing tab
  final List<Widget> _pages = [
    const CadreDashboardPage(),
    const CadreHistoryPage(),
    const ZonationMapPage(), // Menampilkan peta wilayah
    const ProfilePage(), // Menampilkan profil & tombol logout
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Peta'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
