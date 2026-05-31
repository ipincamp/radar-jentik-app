import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
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
  List<Polygon> _idwPolygons = [];
  List<Polygon> _villageBorders = []; // Menyimpan garis batas 9 desa

  // Variabel Bounding Box dinamis dari GeoJSON
  double _minLat = 90.0;
  double _maxLat = -90.0;
  double _minLon = 180.0;
  double _maxLon = -180.0;

  final double _gridResolution = 0.002;

  // Daftar 9 Desa target di Puskesmas II Cilongok
  final List<String> _targetVillages = [
    'langgongsari',
    'pejogol',
    'pageraji',
    'sudimara',
    'cipete',
    'batuanten',
    'kasegeran',
    'jatisaba',
    'panusupan',
  ];

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  // Fungsi utama untuk menjalankan urutan proses
  Future<void> _initializeApp() async {
    setState(() => _isLoading = true);

    // 1. Baca GeoJSON & Hitung Bounding Box Dulu
    await _loadGeoJsonAndCalculateBounds();

    // 2. Jika Bounding Box sudah dapat, panggil data Marker & Hitung IDW
    await Future.wait([_fetchMarkerData(), _fetchIDWData()]);

    setState(() => _isLoading = false);
  }

  // 1. Membaca GeoJSON, Memfilter 9 Desa, dan Menghitung Bounding Box
  Future<void> _loadGeoJsonAndCalculateBounds() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/33.02_kelurahan.geojson',
      );
      final Map<String, dynamic> data = json.decode(jsonString);

      List<Polygon> borders = [];

      for (var feature in data['features']) {
        final properties = feature['properties'];
        final String villageName = (properties['nm_kelurahan'] ?? '')
            .toString()
            .toLowerCase();

        // Hanya proses jika nama desa ada di dalam list target
        if (_targetVillages.contains(villageName)) {
          final geometry = feature['geometry'];
          List<dynamic> polygonsData = [];

          // Parsing tipe Polygon atau MultiPolygon
          if (geometry['type'] == 'Polygon') {
            polygonsData = [geometry['coordinates']];
          } else if (geometry['type'] == 'MultiPolygon') {
            polygonsData = geometry['coordinates'];
          }

          // Ekstrak koordinat untuk digambar dan dihitung min/max-nya
          for (var poly in polygonsData) {
            List<LatLng> points = [];
            // Ambil outer ring (batas luar polygon)
            for (var coord in poly[0]) {
              double lon = (coord[0] as num).toDouble();
              double lat = (coord[1] as num).toDouble();

              points.add(LatLng(lat, lon));

              // Kalkulasi Bounding Box Area
              if (lat < _minLat) _minLat = lat;
              if (lat > _maxLat) _maxLat = lat;
              if (lon < _minLon) _minLon = lon;
              if (lon > _maxLon) _maxLon = lon;
            }

            // Tambahkan sebagai layer batas desa di peta
            borders.add(
              Polygon(
                points: points,
                color: Colors.transparent, // Transparan karena ini cuma garis batas
                borderColor: Colors.blueAccent, // Warna batas desa
                borderStrokeWidth: 2.0,
              ),
            );
          }
        }
      }

      setState(() {
        _villageBorders = borders;
      });
      debugPrint(
        "Bounding Box Didapat: MinLat:$_minLat, MaxLat:$_maxLat, MinLon:$_minLon, MaxLon:$_maxLon",
      );
    } catch (e) {
      debugPrint('Gagal memuat GeoJSON: $e');
    }
  }

  // 2. Mengambil data titik inspeksi (Marker asli)
  Future<void> _fetchMarkerData() async {
    try {
      final response = await _apiClient.dio.get('/reports/map');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        _markers = data.map((report) {
          final lat = double.tryParse(report['latitude'].toString()) ?? 0.0;
          final lng = double.tryParse(report['longitude'].toString()) ?? 0.0;
          final isPositive = report['larvae_status'] == 1;

          return Marker(
            point: LatLng(lat, lng),
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () => _showMarkerInfo(
                report['family_head_name'] ?? 'Warga',
                'RT ${report['rt']}/RW ${report['rw']}',
                isPositive,
              ),
              child: Icon(
                Icons.location_on,
                color: isPositive ? Colors.red : Colors.green,
                size: 40,
              ),
            ),
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('Gagal memuat marker: $e');
    }
  }

  // 3. Meminta Backend menghitung IDW menggunakan Bounding Box Dinamis
  Future<void> _fetchIDWData() async {
    try {
      // Bounding box ini didapat secara otomatis dari fungsi _loadGeoJsonAndCalculateBounds
      final payload = {
        "min_lat": _minLat,
        "max_lat": _maxLat,
        "min_lon": _minLon,
        "max_lon": _maxLon,
        "resolution": _gridResolution,
        "power": 2,
      };

      final response = await _apiClient.dio.post(
        '/idw/calculate',
        data: payload,
      );

      if (response.statusCode == 200) {
        final List<dynamic> gridData = response.data['data'] ?? [];
        final List<Polygon> tempPolygons = [];
        final halfRes = _gridResolution / 2;

        for (var point in gridData) {
          final lat = double.tryParse(point['Lat'].toString()) ?? 0.0;
          final lon = double.tryParse(point['Lon'].toString()) ?? 0.0;
          final value =
              double.tryParse(point['EstimatedValue'].toString()) ?? 0.0;

          Color? gridColor = Color.lerp(Colors.green, Colors.red, value / 100);

          tempPolygons.add(
            Polygon(
              points: [
                LatLng(lat - halfRes, lon - halfRes),
                LatLng(lat - halfRes, lon + halfRes),
                LatLng(lat + halfRes, lon + halfRes),
                LatLng(lat + halfRes, lon - halfRes),
              ],
              color: gridColor?.withOpacity(0.4) ?? Colors.transparent,
              borderStrokeWidth: 0,
            ),
          );
        }

        _idwPolygons = tempPolygons;
      }
    } catch (e) {
      debugPrint('Gagal memuat peta IDW: $e');
    }
  }

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
    // Menghitung titik tengah peta secara otomatis berdasarkan Bounding Box
    LatLng mapCenter = LatLng((_minLat + _maxLat) / 2, (_minLon + _maxLon) / 2);
    // Jika data belum diload, set fallback lokasi Purwokerto
    if (_minLat == 90.0) mapCenter = const LatLng(-7.4245, 109.2302);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Peta Zonasi IDW Puskesmas II Cilongok'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializeApp,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 4))
          : FlutterMap(
              options: MapOptions(
                initialCenter: mapCenter,
                initialZoom: 13.0, // Diperkecil sedikit agar 9 desa terlihat
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.ipincamp.radar_jentik',
                ),
                // 1. Layer IDW Grid
                PolygonLayer(polygons: _idwPolygons),
                // 2. Layer Garis Batas 9 Desa (di atas warna IDW)
                PolygonLayer(polygons: _villageBorders),
                // 3. Layer Marker
                MarkerLayer(markers: _markers),
              ],
            ),
    );
  }
}
