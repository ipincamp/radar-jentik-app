import 'package:flutter/material.dart';

class OfficerDashboardPage extends StatelessWidget {
  const OfficerDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Puskesmas')),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          const Text(
            'Selamat Datang,',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const Text(
            'Petugas Puskesmas',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),

          // Card Pintasan Informasi
          Card(
            color: Colors.blue[50],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 30),
                  SizedBox(height: 12),
                  Text(
                    'Status Sistem Pemantauan',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Sistem Radar Jentik saat ini beroperasi normal. Silakan periksa tab "Validasi" secara berkala untuk menyetujui laporan terbaru dari kader di lapangan.',
                    style: TextStyle(color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),
          // Tambahkan widget lain di sini jika kedepannya ada API Statistik
        ],
      ),
    );
  }
}
