import 'package:flutter/material.dart';

// Model sederhana untuk mengelola *state* setiap wadah
class ContainerItem {
  final String name;
  final TextEditingController inspectedCtrl;
  final TextEditingController positiveCtrl;

  ContainerItem(this.name)
    // Nilai awal di-set '0' agar kader tidak perlu repot mengetik 0
    // untuk wadah yang memang tidak ada di rumah tersebut.
    : inspectedCtrl = TextEditingController(text: '0'),
      positiveCtrl = TextEditingController(text: '0');
}

class EntryFormPage extends StatefulWidget {
  const EntryFormPage({Key? key}) : super(key: key);

  @override
  State<EntryFormPage> createState() => _EntryFormPageState();
}

class _EntryFormPageState extends State<EntryFormPage> {
  // Status Jentik Utama
  bool isPositive = false;

  // Daftar statis parameter wadah sesuai formulir rekapitulasi PSN
  final List<ContainerItem> containers = [
    ContainerItem('Bak Kamar Mandi'),
    ContainerItem('Tempayan'),
    ContainerItem('Pecahan Botol / Air Kemasan'),
    ContainerItem('Barang Bekas'),
    ContainerItem('Kulkas / Dispenser'),
    ContainerItem('Tandon Air'),
    ContainerItem('Vas Bunga'),
    ContainerItem('Pot Bunga'),
    ContainerItem('Lain-lain'),
  ];

  @override
  void dispose() {
    // Pastikan untuk membersihkan controller saat halaman ditutup untuk mencegah memory leak
    for (var c in containers) {
      c.inspectedCtrl.dispose();
      c.positiveCtrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lapor Pemeriksaan'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Form(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // ==========================================
            // BAGIAN 1: IDENTITAS & LOKASI
            // ==========================================
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '1. Identitas & Lokasi',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.gps_fixed, color: Colors.blue),
                      title: Text('Lat: -7.4245, Long: 109.2302'), // Dummy GPS
                      subtitle: Text('Akurasi: 4 meter'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'RT',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'RW',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Nama Kepala Keluarga',
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ==========================================
            // BAGIAN 2: STATUS JENTIK UTAMA (NILAI Z)
            // ==========================================
            Card(
              elevation: 2,
              color: isPositive ? Colors.red.shade50 : Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: SwitchListTile(
                  title: const Text(
                    '2. Apakah ditemukan jentik?',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    isPositive
                        ? 'POSITIF (+) Terdapat Jentik'
                        : 'NEGATIF (-) Bebas Jentik',
                    style: TextStyle(
                      color: isPositive ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  value: isPositive,
                  activeColor: Colors.red,
                  onChanged: (val) => setState(() => isPositive = val),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ==========================================
            // BAGIAN 3: RINCIAN WADAH
            // ==========================================
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
              child: Text(
                '3. Rincian Wadah / Kontainer',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),

            // Generate List UI Wadah secara otomatis
            ...containers.map((container) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8.0),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      // Nama Wadah (Memakan ruang lebih besar)
                      Expanded(
                        flex: 5,
                        child: Text(
                          container.name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Input Jumlah Diperiksa (Jml)
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: container.inspectedCtrl,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            labelText: 'Diperiksa',
                            isDense: true,
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 8,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Input Jumlah Positif Jentik (+)
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: container.positiveCtrl,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            labelText: 'Positif (+)',
                            isDense: true,
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),

            const SizedBox(height: 32),

            // TOMBOL KIRIM
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                // Di sini Anda bisa mengambil nilai dari controllers nanti, misalnya:
                // String nilaiKamarMandi = containers[0].inspectedCtrl.text;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Laporan berhasil dikirim ke Puskesmas!'),
                  ),
                );
                Navigator.pop(context); // Kembali ke dashboard
              },
              child: const Text(
                'KIRIM LAPORAN',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
