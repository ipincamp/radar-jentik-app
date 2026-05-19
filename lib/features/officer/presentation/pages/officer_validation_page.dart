import 'package:flutter/material.dart';
import 'officer_validation_detail_page.dart';

class OfficerValidationPage extends StatelessWidget {
  const OfficerValidationPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Validasi Laporan Masuk')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.orange,
                child: Icon(Icons.assignment, color: Colors.white),
              ),
              title: const Text(
                'Bpk. Supardi (RT 01/RW 02)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Kader: Siti Aminah • Desa: Kasegeran\n19 Mei 2026, 09:30 WIB',
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OfficerValidationDetailPage(),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
