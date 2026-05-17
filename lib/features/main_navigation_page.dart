import 'package:flutter/material.dart';
import 'home/presentation/pages/home_page.dart';
import 'gis_map/presentation/pages/zonation_map_page.dart';
import 'sync_dashboard/presentation/pages/sync_dashboard_page.dart';
import 'report_entry/presentation/pages/entry_form_page.dart';

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
    // Definisi halaman untuk masing-masing tab (Total 4 Tab)
    final List<Widget> pages = [
      // Tab 0: Home
      HomePage(
        onNavigateToTab: (index) {
          // Penyesuaian index jika tombol cepat di home ditekan
          if (index == 1)
            _navigateToTab(2); // Maps sekarang di index 2
          else if (index == 0)
            _navigateToTab(1); // Sinkronisasi -> kita taruh di Survey (index 1)
        },
      ),

      // Tab 1: Survey (Sementara kita gunakan Sinkronisasi sebagai placeholder)
      const SyncDashboardPage(),

      // Tab 2: Maps
      const ZonationMapPage(),

      // Tab 3: Profile (Halaman Kosong untuk sementara)
      const Center(
        child: Text("Halaman Profile", style: TextStyle(fontSize: 20)),
      ),
    ];

    return Scaffold(
      body: pages[_currentIndex],

      // --- TOMBOL TENGAH (PLUS) ---
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00A000), // Warna Hijau seperti mockup
        shape: const CircleBorder(), // Memastikan bentuknya bulat penuh
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 36),
        onPressed: () {
          // Aksi ketika tombol '+' ditekan (Buka form lapor jentik)
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EntryFormPage()),
          );
        },
      ),
      // Posisikan tombol mengambang di tengah bawah
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // --- BAR NAVIGASI BAWAH ---
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shape:
            const CircularNotchedRectangle(), // Membuat lekukan (notch) untuk tombol +
        notchMargin: 8.0, // Jarak lekukan dengan tombol
        child: SizedBox(
          height: 65, // Tinggi navigation bar
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Bagian Kiri
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildNavItem(
                    icon: Icons.home_rounded,
                    label: "Home",
                    index: 0,
                  ),
                  _buildNavItem(
                    icon: Icons.menu_book_rounded,
                    label: "Survey",
                    index: 1,
                  ),
                ],
              ),
              // Bagian Kanan
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildNavItem(
                    icon: Icons.map_rounded,
                    label: "Maps",
                    index: 2,
                  ),
                  _buildNavItem(
                    icon: Icons.person_rounded,
                    label: "Profile",
                    index: 3,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget Helper untuk membuat tombol masing-masing tab
  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;

    return MaterialButton(
      minWidth: 80, // Memastikan lebar klik proporsional
      onPressed: () => _navigateToTab(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.black : Colors.grey[500],
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.grey[500],
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
