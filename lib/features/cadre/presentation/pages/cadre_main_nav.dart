import 'package:flutter/material.dart';

import '../../../home/presentation/pages/home_page.dart';
import 'cadre_history_page.dart';
import 'entry_form_page.dart';
import '../../../gis_map/presentation/pages/zonation_map_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';

class CadreMainNav extends StatefulWidget {
  const CadreMainNav({Key? key}) : super(key: key);

  @override
  State<CadreMainNav> createState() => _CadreMainNavState();
}

class _CadreMainNavState extends State<CadreMainNav> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomePage(
        onNavigateToTab: (index) => setState(() => _currentIndex = index),
      ),
      const CadreHistoryPage(),
      const ZonationMapPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      body: pages[_currentIndex],

      // PERUBAHAN DI SINI: Tombol FAB hanya dirender (ditampilkan) saat berada di tab Beranda (_currentIndex == 0)
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EntryFormPage(),
                  ),
                );
              },
              backgroundColor: Colors.blue,
              shape: const CircleBorder(),
              child: const Icon(
                Icons.assignment_add,
                color: Colors.white,
                size: 28,
              ),
            )
          : null, // Jika bukan di tab Beranda, tombolnya dihilangkan (null)

      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

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
