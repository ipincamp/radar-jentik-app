import 'package:flutter/material.dart';

class EntryFormPage extends StatefulWidget {
  const EntryFormPage({Key? key}) : super(key: key);

  @override
  State<EntryFormPage> createState() => _EntryFormPageState();
}

class _EntryFormPageState extends State<EntryFormPage> {
  bool isPositive = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lapor Pemeriksaan')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Section 1: Lokasi
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.gps_fixed, color: Colors.blue),
                    title: Text(
                      'Lat: -7.4245, Long: 109.2302',
                    ), // Dummy GPS Purwokerto
                    subtitle: Text('Akurasi: 4 meter'),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(labelText: 'RT'),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(labelText: 'RW'),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Nama Kepala Keluarga',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Section 2: Status Utama (Z value IDW)
          Card(
            color: isPositive ? Colors.red.shade50 : Colors.green.shade50,
            child: SwitchListTile(
              title: const Text('Ditemukan Jentik?'),
              subtitle: Text(isPositive ? 'Positif (+)' : 'Negatif (-)'),
              value: isPositive,
              onChanged: (val) => setState(() => isPositive = val),
            ),
          ),
          const SizedBox(height: 16),

          // Section 3: Detail Wadah
          const Text(
            'Detail Wadah (Opsional)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          // Dummy UI untuk 1 item wadah
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const Expanded(
                    flex: 2,
                    child: Text('Bak Mandi'), // Dropdown in real app
                  ),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(labelText: 'Jml'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(labelText: 'Positif'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('Tambah Wadah'),
          ),

          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
            onPressed: () {},
            child: const Text('Kirim Laporan'),
          ),
        ],
      ),
    );
  }
}
