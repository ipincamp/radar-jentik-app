import 'package:flutter/material.dart';

class CadreHistoryPage extends StatelessWidget {
  const CadreHistoryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Laporan')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: 4,
        itemBuilder: (context, index) {
          // Dummy data logic
          final status = index == 0
              ? 'Pending'
              : (index % 2 == 0 ? 'Ditolak' : 'Diterima');
          final statusColor = status == 'Pending'
              ? Colors.orange
              : (status == 'Diterima' ? Colors.green : Colors.red);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text('Rumah Warga ${index + 1} (RT 01/RW 02)'),
              subtitle: const Text('19 Mei 2026 • Status Jentik: Positif'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
