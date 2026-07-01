import 'package:flutter/material.dart';
// IMPORT HOME PAGE YANG BARU
import '../../../home/presentation/pages/home_page.dart';
import 'officer_validation_page.dart';
import 'officer_user_management_page.dart';
import '../../../gis_map/presentation/pages/zonation_map_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';

class OfficerMainNav extends StatefulWidget {
  const OfficerMainNav({Key? key}) : super(key: key);

  @override
  State<OfficerMainNav> createState() => _OfficerMainNavState();
}

class _OfficerMainNavState extends State<OfficerMainNav> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // List _pages dipindah ke dalam build agar bisa membaca setState
    final List<Widget> pages = [
      // MENGGUNAKAN HOME PAGE DI TAB PERTAMA
      HomePage(
        onNavigateToTab: (index) => setState(() => _currentIndex = index),
      ),
      const OfficerValidationPage(),
      const ZonationMapPage(),
      const OfficerUserManagementPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            label: 'Validasi',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Peta'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Kader'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
