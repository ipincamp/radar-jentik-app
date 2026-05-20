import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/network/api_client.dart';

class ZonationMapPage extends StatefulWidget {
  const ZonationMapPage({super.key});

  @override
  State<ZonationMapPage> createState() => _ZonationMapPageState();
}

class _ZonationMapPageState extends State<ZonationMapPage> {
  final _apiClient = ApiClient();
  bool _isLoading = true;
  List<Marker> _markers = [];

  // Koordinat tengah default (Misal: Tengah wilayah Puskesmas / Banyumas)
  final LatLng _defaultCenter = const LatLng(-7.4245, 109.2302);

  @override
  void initState() {
    super.initState();
    _fetchMapData();
  }

  // Mengambil data koordinat dari backend
  Future<void> _fetchMapData() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiClient.dio.get('/reports/map');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];

        // Memetakan JSON menjadi list Marker Peta
        final List<Marker> fetchedMarkers = data.map((report) {
          final lat = double.tryParse(report['latitude'].toString()) ?? 0.0;
          final lng = double.tryParse(report['longitude'].toString()) ?? 0.0;
          final isPositive = report['larvae_status'] == 1; // 1 = Positif
          final headName = report['family_head_name'] ?? 'Warga';
          final rtRw = 'RT ${report['rt']}/RW ${report['rw']}';

          return Marker(
            point: LatLng(lat, lng),
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () {
                _showMarkerInfo(headName, rtRw, isPositive);
              },
              child: Icon(
                Icons.location_on,
                color: isPositive ? Colors.red : Colors.green,
                size: 40,
              ),
            ),
          );
        }).toList();

        setState(() {
          _markers = fetchedMarkers;
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat titik peta: ${e.message}')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  // Memunculkan Jendela Info saat Marker ditekan (UX)
  void _showMarkerInfo(String name, String rtRw, bool isPositive) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isPositive ? Icons.warning_rounded : Icons.verified_rounded,
                  color: isPositive ? Colors.red : Colors.green,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Rumah $name',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 30),
            Text('Alamat: $rtRw', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'Status Pemeriksaan: ',
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  isPositive ? 'POSITIF JENTIK' : 'BEBAS JENTIK',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isPositive ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Tutup',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Peta Persebaran Jentik'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchMapData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              options: MapOptions(
                initialCenter: _defaultCenter,
                initialZoom: 14.0, // Zoom yang pas untuk cakupan desa
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all, // Mengizinkan zoom, pan, cubit
                ),
              ),
              children: [
                // Layer Gambar Peta Dasar (Satelit / Jalan)
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.ipincamp.radar_jentik',
                ),
                // Layer Titik Laporan
                MarkerLayer(markers: _markers),
              ],
            ),
    );
  }
}
