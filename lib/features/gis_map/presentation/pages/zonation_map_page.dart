import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
  final repository = GisRepositoryImpl();
  late Future<List<RiskPoint>> _zonationDataFuture;

  @override
  void initState() {
    super.initState();
    _zonationDataFuture = repository.getZonationData();
  }

  Color _getColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.danger:
        return const Color(0xFFE53935).withOpacity(0.7);
      case RiskLevel.warning:
        return const Color(0xFFFFB300).withOpacity(0.7);
      case RiskLevel.safe:
        return const Color(0xFF43A047).withOpacity(0.7);
    }
  }

  // --- FUNGSI BARU: Memunculkan Pop-up Detail Laporan ---
  void _showMarkerDetails(RiskPoint point) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    point.level == RiskLevel.danger
                        ? "🚨 POSITIF Jentik"
                        : "✅ NEGATIF Jentik",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: point.level == RiskLevel.danger
                          ? Colors.red
                          : Colors.green,
                    ),
                  ),
                  Text(
                    point.timestamp != null
                        ? "${point.timestamp!.day}/${point.timestamp!.month}/${point.timestamp!.year}"
                        : "Waktu tidak diketahui",
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),

              // Detail Koordinat
              const Text(
                "📍 Koordinat Lokasi:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                "${point.latitude}, ${point.longitude}",
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),

              // Detail Catatan
              const Text(
                "📝 Catatan Lapangan:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                (point.notes == null || point.notes!.isEmpty)
                    ? "Tidak ada catatan."
                    : point.notes!,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),

              // Detail Foto
              const Text(
                "📸 Lampiran Foto:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: point.imagePath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: kIsWeb
                            ? Image.network(point.imagePath!, fit: BoxFit.cover)
                            : Image.file(
                                File(point.imagePath!),
                                fit: BoxFit.cover,
                              ),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_not_supported,
                            size: 40,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Tidak ada foto dilampirkan",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final riskPoints = snapshot.data ?? [];

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

                  // LAYER 1: Lingkaran Radius GIS (Warna Transparan)
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

                  // --- LAYER 2 BARU: PIN MARKER INTERAKTIF ---
                  MarkerLayer(
                    markers: riskPoints.map((point) {
                      return Marker(
                        point: LatLng(point.latitude, point.longitude),
                        width: 40,
                        height: 40,
                        child: GestureDetector(
                          onTap: () => _showMarkerDetails(point),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.black87,
                            size: 30,
                          ),
                        ),
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

              // UI Legenda (Tetap Sama)
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
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EntryFormPage()),
          );
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
