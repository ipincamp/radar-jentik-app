import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../report_entry/presentation/pages/entry_form_page.dart';
import '../../domain/entities/risk_point.dart';
import '../../data/repositories/gis_repository_impl.dart';

class ZonationMapPage extends StatefulWidget {
  const ZonationMapPage({super.key});

  @override
  State<ZonationMapPage> createState() => _ZonationMapPageState();
}

class _ZonationMapPageState extends State<ZonationMapPage> {
  // Instance Repository
  // TODO di-inject pakai GetIt/Provider
  final repository = GisRepositoryImpl();

  // Variable untuk menampung Future
  late Future<List<RiskPoint>> _zonationDataFuture;

  @override
  void initState() {
    super.initState();
    // Memanggil fungsi getZonationData saat halaman pertama dibuka
    _zonationDataFuture = repository.getZonationData();
  }

  // Helper: Mengubah RiskLevel (Enum) menjadi Warna UI
  Color _getColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.danger:
        return const Color(0xFFE53935).withOpacity(0.7); // Merah Transparan
      case RiskLevel.warning:
        return const Color(0xFFFFB300).withOpacity(0.7); // Kuning Transparan
      case RiskLevel.safe:
        return const Color(0xFF43A047).withOpacity(0.7); // Hijau Transparan
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Peta Zonasi DBD Cilongok'),
        backgroundColor: Colors.teal,
      ),
      body: FutureBuilder<List<RiskPoint>>(
        future: _zonationDataFuture,
        builder: (context, snapshot) {
          // 1. Tampilkan Loading jika data belum siap (Simulasi delay 2 detik)
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Memuat Peta Risiko..."),
                ],
              ),
            );
          }

          // 2. Tampilkan Error jika gagal
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          // 3. Tampilkan Peta jika data siap
          final riskPoints = snapshot.data ?? [];

          // GUNAKAN STACK AGAR LEGENDA BISA MENGAMBANG DI ATAS PETA
          return Stack(
            children: [
              FlutterMap(
                options: const MapOptions(
                  initialCenter: LatLng(-7.4025, 109.1670),
                  initialZoom: 15.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.radarjentik.app',
                  ),
                  CircleLayer(
                    circles: riskPoints.map((point) {
                      return CircleMarker(
                        point: LatLng(point.latitude, point.longitude),
                        color: _getColor(point.level),
                        radius: 40,
                        useRadiusInMeter: true,
                        borderColor: Colors.white,
                        borderStrokeWidth: 1,
                      );
                    }).toList(),
                  ),
                  RichAttributionWidget(
                    alignment: AttributionAlignment.bottomLeft,
                    attributions: [
                      TextSourceAttribution(
                        'OpenStreetMap',
                        onTap: () => launchUrl(
                          Uri.parse('https://openstreetmap.org/copyright'),
                          mode: LaunchMode.externalApplication,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // --- UI LEGENDA KERAPATAN JENTIK ---
              Positioned(
                top: 16,
                right: 16,
                child: Card(
                  elevation: 4,
                  color: Colors.white.withOpacity(0.9),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Legenda Risiko DBD",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildLegendItem(
                          const Color(0xFFE53935).withOpacity(0.7),
                          "Bahaya (Ada Jentik)",
                        ),
                        const SizedBox(height: 6),
                        _buildLegendItem(
                          const Color(0xFFFFB300).withOpacity(0.7),
                          "Waspada (Rawan)",
                        ),
                        const SizedBox(height: 6),
                        _buildLegendItem(
                          const Color(0xFF43A047).withOpacity(0.7),
                          "Aman (Bebas Jentik)",
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // AWAIT: Tunggu sampai form laporan selesai dan ditutup (Navigator.pop)
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EntryFormPage()),
          );

          // REFRESH PETA: Ambil ulang data dari MockDatabase agar titik baru muncul
          setState(() {
            _zonationDataFuture = repository.getZonationData();
          });
        },
        label: const Text("Lapor Jentik"),
        icon: const Icon(Icons.add_location_alt),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
    );
  }

  // Widget Bantuan untuk merender setiap baris legenda
  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
