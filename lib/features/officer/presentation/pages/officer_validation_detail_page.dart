import 'package:flutter/material.dart';

class OfficerValidationDetailPage extends StatelessWidget {
  const OfficerValidationDetailPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Laporan')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const ListTile(
            title: Text('Pelapor: Siti Aminah'),
            subtitle: Text('Desa Kasegeran - RT 01 / RW 02'),
            leading: Icon(Icons.person, size: 40),
          ),
          const Divider(),
          const ListTile(
            title: Text('Koordinat Lokasi'),
            subtitle: Text('Lat: -7.41231, Long: 109.21312'),
            leading: Icon(Icons.location_on, color: Colors.red),
          ),
          const Divider(),
          const ListTile(
            title: Text(
              'Status Jentik Utama',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'POSITIF (+)',
              style: TextStyle(
                color: Colors.red,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(),
          const Text(
            'Rincian Wadah Diperiksa:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          DataTable(
            columns: const [
              DataColumn(label: Text('Wadah')),
              DataColumn(label: Text('Diperiksa')),
              DataColumn(label: Text('Positif')),
            ],
            rows: const [
              DataRow(
                cells: [
                  DataCell(Text('Bak Mandi')),
                  DataCell(Text('2')),
                  DataCell(Text('1')),
                ],
              ),
              DataRow(
                cells: [
                  DataCell(Text('Vas Bunga')),
                  DataCell(Text('3')),
                  DataCell(Text('0')),
                ],
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.red),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Tolak Laporan',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Terima & Validasi'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
