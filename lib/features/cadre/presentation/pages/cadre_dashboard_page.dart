import 'package:flutter/material.dart';
import 'entry_form_page.dart';

class CadreDashboardPage extends StatelessWidget {
  const CadreDashboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beranda Kader'),
        elevation: 0,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Halo, Kader Kesehatan!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Desa Tugas: Langgongsari',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Card(
              color: Colors.blue.shade50,
              child: const ListTile(
                title: Text('Total Laporan Bulan Ini'),
                trailing: Text(
                  '12',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigasi masuk ke form pelaporan jentik
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EntryFormPage()),
          );
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Buat Laporan',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
