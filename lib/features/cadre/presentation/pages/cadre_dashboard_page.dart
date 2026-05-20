import 'package:flutter/material.dart';

class CadreDashboardPage extends StatelessWidget {
  const CadreDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Beranda Kader')),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          const Text(
            'Halo,',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const Text(
            'Pahlawan Jentik!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 30),

          Card(
            color: Colors.green[50],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.health_and_safety, color: Colors.green, size: 30),
                  SizedBox(height: 12),
                  Text(
                    'Mari Basmi Demam Berdarah',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Gunakan menu "Lapor" di bagian bawah untuk mengirimkan data hasil pantauan jentik di rumah warga sekitar Anda.',
                    style: TextStyle(color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
