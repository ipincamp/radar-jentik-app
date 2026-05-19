import 'package:flutter/material.dart';
import 'officer_dashboard_page.dart';
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

  final List<Widget> _pages = [
    const OfficerDashboardPage(),
    const OfficerValidationPage(),
    const ZonationMapPage(), // Peta Global Puskesmas
    const OfficerUserManagementPage(),
    const ProfilePage(),
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
