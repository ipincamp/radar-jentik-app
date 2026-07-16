import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  Marker? _tappedMarker;
  List<Polygon> _idwPolygons = [];
  List<Polygon> _villageBorders = []; // Menyimpan garis batas 9 desa

  // Variabel Bounding Box dinamis dari GeoJSON
  double _minLat = 90.0;
  double _maxLat = -90.0;
  double _minLon = 180.0;
  double _maxLon = -180.0;

  // supaya lebih halus
  final double _gridResolution = 0.001; // 4000 kotak

  // Daftar 9 Desa target di Puskesmas Cilongok II
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

  Color _getZonationColor(double value) {
    double score = (value <= 1.0 && value > 0.0) ? (value * 100) : value;
    if (score <= 33.33) {
      return Colors.green; // Kategori 1: Aman
    } else if (score <= 66.66) {
      return Colors.orange; // Kategori 2: Rawan / Waspada
    } else {
      return Colors.red; // Kategori 3: Bahaya
    }
  }

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
                color: Colors
                    .transparent, // Transparan karena ini cuma garis batas
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
              onTap: () =>
                  _showMarkerInfo(report), // Kirim seluruh data laporan
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
      final payload = {
        "min_lat": _minLat,
        "max_lat": _maxLat,
        "min_lon": _minLon,
        "max_lon": _maxLon,
        "resolution": _gridResolution,
        "power": 2,
      };

      final response = await _apiClient.dio.post(
        '/estimations/idw',
        data: payload,
      );

      if (response.statusCode == 200) {
        final List<dynamic> gridData = response.data['data'] ?? [];
        final List<Polygon> tempPolygons = [];

        double actualBoxSize = _gridResolution;
        if (gridData.length > 1) {
          final lat1 =
              double.tryParse(
                (gridData[0]['Lat'] ?? gridData[0]['lat']).toString(),
              ) ??
              0.0;
          final lon1 =
              double.tryParse(
                (gridData[0]['Lon'] ?? gridData[0]['lon']).toString(),
              ) ??
              0.0;
          final lat2 =
              double.tryParse(
                (gridData[1]['Lat'] ?? gridData[1]['lat']).toString(),
              ) ??
              0.0;
          final lon2 =
              double.tryParse(
                (gridData[1]['Lon'] ?? gridData[1]['lon']).toString(),
              ) ??
              0.0;

          final diffLat = (lat1 - lat2).abs();
          final diffLon = (lon1 - lon2).abs();

          if (diffLon > 0)
            actualBoxSize = diffLon;
          else if (diffLat > 0)
            actualBoxSize = diffLat;
        }

        final halfRes = (actualBoxSize / 2) * 1.05;

        if (gridData.isEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Info: Data Zonasi kosong dari server'),
            ),
          );
          return;
        }

        for (var point in gridData) {
          final lat =
              double.tryParse((point['Lat'] ?? point['lat']).toString()) ?? 0.0;
          final lon =
              double.tryParse((point['Lon'] ?? point['lon']).toString()) ?? 0.0;
          final value =
              double.tryParse(
                (point['estimated_value'] ??
                        point['EstimatedValue'] ??
                        point['value'])
                    .toString(),
              ) ??
              0.0;

          if (lat == 0.0 && lon == 0.0) continue;

          Color gridColor = _getZonationColor(value);

          tempPolygons.add(
            Polygon(
              points: [
                LatLng(lat - halfRes, lon - halfRes),
                LatLng(lat - halfRes, lon + halfRes),
                LatLng(lat + halfRes, lon + halfRes),
                LatLng(lat + halfRes, lon - halfRes),
              ],
              color: gridColor.withValues(alpha: 0.5),
              borderStrokeWidth: 0,
            ),
          );
        }

        setState(() {
          _idwPolygons = tempPolygons;
        });
      }
    } catch (e) {
      debugPrint('Gagal memuat peta IDW: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat peta IDW: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // Fungsi untuk menembak API prediksi saat peta diklik
  Future<void> _predictPoint(double lat, double lon) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await _apiClient.dio.post(
        '/estimations/idw/predict-point',
        data: {"lat": lat, "lon": lon},
      );

      if (mounted) Navigator.pop(context);

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final status = data['status'].toString();
        double value = double.tryParse(data['value'].toString()) ?? 0.0;

        if (value <= 1.0 && value > 0.0) {
          value = value * 100; // Konversi ke skala 100
        }

        _showPredictionInfo(lat, lon, status, value);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memprediksi titik: $e')));
      }
    }
  }

  // Fungsi untuk memunculkan BottomSheet hasil prediksi
  void _showPredictionInfo(
    double lat,
    double lon,
    String status,
    double value,
  ) {
    Color statusColor;
    IconData statusIcon;

    if (status == 'Bahaya') {
      statusColor = Colors.red;
      statusIcon = Icons.cancel_rounded;
    } else if (status == 'Waspada') {
      statusColor = Colors.orange;
      statusIcon = Icons.warning_rounded;
    } else {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle_rounded;
    }

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
                Icon(statusIcon, color: statusColor, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Prediksi Zona $status',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 30),
            Text(
              'Titik Klik: ${lat.toStringAsFixed(5)}, ${lon.toStringAsFixed(5)}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'Skor Kerawanan Jentik: ',
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  value.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const Text(' / 100', style: TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '*(Algoritma IDW mengkalkulasi jarak titik ini terhadap seluruh laporan kader di sekitarnya)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
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
    ).whenComplete(() {
      if (mounted) {
        setState(() {
          _tappedMarker = null;
        });
      }
    });
  }

  // Fungsi Modifikasi untuk BottomSheet Marker Informasi Real Kader
  void _showMarkerInfo(Map<String, dynamic> report) {
    final name = report['family_head_name'] ?? 'Warga';
    final rtRw = 'RT ${report['rt']} / RW ${report['rw']}';
    final isPositive = report['larvae_status'] == 1;
    final lat = double.tryParse(report['latitude'].toString()) ?? 0.0;
    final lng = double.tryParse(report['longitude'].toString()) ?? 0.0;

    String villageName = '-';
    if (report['village'] != null && report['village']['name'] != null) {
      // 1. Coba baca dari relasi objek (seperti di History/Validation)
      villageName = report['village']['name'].toString();
    } else if (report['village_name'] != null) {
      // 2. Fallback: Coba baca dari key flat jika backend mengirimkannya secara langsung
      villageName = report['village_name'].toString();
    }

    String dateStr = '-';
    if (report['inspected_at'] != null) {
      try {
        final parsed = DateTime.parse(report['inspected_at']).toLocal();
        dateStr =
            "${parsed.day}/${parsed.month}/${parsed.year} ${parsed.hour}:${parsed.minute.toString().padLeft(2, '0')}";
      } catch (_) {}
    }

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
            // Header
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
                    name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 30),

            // Detail Data
            _buildDetailText('Desa', villageName),
            _buildDetailText('Alamat', rtRw),
            _buildDetailText('Tanggal Inspeksi', dateStr),

            const SizedBox(height: 8),

            // Baris Koordinat & Tombol Salin
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  width: 130,
                  child: Text(
                    'Koordinat',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
                const Text(': ', style: TextStyle(color: Colors.grey)),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$lat, $lng',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: '$lat, $lng'));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Koordinat disalin ke clipboard!'),
                              duration: Duration(seconds: 2),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Icon(Icons.copy, size: 20, color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Status Pemeriksaan
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isPositive ? Colors.red[50] : Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isPositive
                      ? Colors.red.shade200
                      : Colors.green.shade200,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Status: ', style: TextStyle(fontSize: 16)),
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
            ),
            const SizedBox(height: 24),

            // Tombol Tutup
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
    ).whenComplete(() {
      if (mounted) {
        setState(() {
          _tappedMarker = null; // Hapus marker prediksi
        });
      }
    });
  }

  // Widget Bantuan untuk Teks Detail
  Widget _buildDetailText(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
          const Text(': ', style: TextStyle(color: Colors.grey)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    LatLng mapCenter = LatLng((_minLat + _maxLat) / 2, (_minLon + _maxLon) / 2);
    if (_minLat == 90.0) mapCenter = const LatLng(-7.4245, 109.2302);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Peta Zonasi IDW Puskesmas Cilongok II'),
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
                initialZoom: 13.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
                onTap: (tapPosition, point) {
                  setState(() {
                    _tappedMarker = Marker(
                      point: point,
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.location_searching_rounded,
                        color: Colors.blueAccent,
                        size: 45,
                      ),
                    );
                  });
                  _predictPoint(point.latitude, point.longitude);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.ipincamp.radar_jentik',
                ),
                PolygonLayer(polygons: _idwPolygons),
                PolygonLayer(polygons: _villageBorders),
                MarkerLayer(
                  markers: [
                    ..._markers,
                    if (_tappedMarker != null) _tappedMarker!,
                  ],
                ),
              ],
            ),
    );
  }
}
