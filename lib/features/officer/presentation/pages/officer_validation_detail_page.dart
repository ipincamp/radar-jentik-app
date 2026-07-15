import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/network/api_client.dart';

class OfficerValidationDetailPage extends StatefulWidget {
  final Map<String, dynamic> reportData;

  const OfficerValidationDetailPage({super.key, required this.reportData});

  @override
  State<OfficerValidationDetailPage> createState() =>
      _OfficerValidationDetailPageState();
}

class _OfficerValidationDetailPageState
    extends State<OfficerValidationDetailPage> {
  final _apiClient = ApiClient();
  bool _isLoading = false;

  Future<void> _validateReport(String status, {String? rejectionReason}) async {
    setState(() => _isLoading = true);
    try {
      final reportId = widget.reportData['id'];
      final Map<String, dynamic> payload = {'status': status};

      if (status == 'reject' &&
          rejectionReason != null &&
          rejectionReason.isNotEmpty) {
        payload['rejection_reason'] = rejectionReason;
      }

      final response = await _apiClient.dio.put(
        '/reports/$reportId/validate',
        data: payload,
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response.data['message'] ?? 'Laporan berhasil divalidasi',
              ),
              backgroundColor: status == 'accept' ? Colors.green : Colors.red,
            ),
          );
          Navigator.pop(context, true);
        }
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Gagal memvalidasi laporan'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ==========================================
  // BOTTOM SHEET: TOLAK LAPORAN
  // ==========================================
  void _showRejectBottomSheet() {
    final TextEditingController reasonController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Container(
              //   padding: const EdgeInsets.all(16),
              //   decoration: BoxDecoration(
              //     color: Colors.red[50],
              //     shape: BoxShape.circle,
              //   ),
              //   child: const Icon(
              //     Icons.cancel_outlined,
              //     color: Colors.red,
              //     size: 48,
              //   ),
              // ),
              // const SizedBox(height: 16),
              const Text(
                'Tolak Laporan',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Silakan masukkan alasan penolakan laporan ini:'),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Contoh: Foto kurang jelas, lokasi salah...',
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Batal',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        final reason = reasonController.text.trim();
                        if (reason.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Alasan penolakan wajib diisi!'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }
                        Navigator.pop(context);
                        _validateReport('reject', rejectionReason: reason);
                      },
                      child: const Text(
                        'Tolak',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // BOTTOM SHEET: TERIMA LAPORAN
  // ==========================================
  void _showAcceptBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Container(
            //   padding: const EdgeInsets.all(16),
            //   decoration: BoxDecoration(
            //     color: Colors.green[50],
            //     shape: BoxShape.circle,
            //   ),
            //   child: const Icon(
            //     Icons.check_circle_outline,
            //     color: Colors.green,
            //     size: 48,
            //   ),
            // ),
            // const SizedBox(height: 16),
            const Text(
              'Konfirmasi Terima',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Apakah Anda yakin ingin menerima laporan ini? Data akan diverifikasi secara permanen.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Batal',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _validateReport('accept');
                    },
                    child: const Text(
                      'Ya, Terima',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // DIALOG PREVIEW LOKASI DI PETA
  // ==========================================
  void _showLocationOnMap(BuildContext context, double lat, double lng) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 400,
            child: Column(
              children: [
                AppBar(
                  title: const Text(
                    'Lokasi Laporan',
                    style: TextStyle(fontSize: 16),
                  ),
                  automaticallyImplyLeading: false,
                  elevation: 0,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Expanded(
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(lat, lng),
                      initialZoom: 17.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.radarjentik.app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(lat, lng),
                            width: 50,
                            height: 50,
                            alignment: Alignment.topCenter,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 50,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.reportData;

    // Filter wadah: Hanya tampilkan wadah yang jumlah diperiksa atau positif lebih dari 0
    final rawContainers = report['container_details'] as List<dynamic>? ?? [];
    final containers = rawContainers.where((c) {
      final inspected = c['inspected_count'] ?? 0;
      final positive = c['positive_count'] ?? 0;
      return inspected > 0 || positive > 0;
    }).toList();

    final isPositive = report['larvae_status'] == 1;
    final photoUrl = report['photo_url'];
    final villageName = report['village'] != null
        ? report['village']['name']
        : '-';

    // Parsing Koordinat
    final lat = double.tryParse(report['latitude']?.toString() ?? '0') ?? 0.0;
    final lng = double.tryParse(report['longitude']?.toString() ?? '0') ?? 0.0;

    String dateStr = '-';
    if (report['inspected_at'] != null) {
      try {
        final parsed = DateTime.parse(report['inspected_at']).toLocal();
        dateStr =
            "${parsed.day}/${parsed.month}/${parsed.year} ${parsed.hour}:${parsed.minute.toString().padLeft(2, '0')}";
      } catch (_) {}
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detail Validasi',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF143B59),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // FOTO BUKTI (MENGGUNAKAN POP-UP PREVIEW)
                  const Text(
                    'Foto Bukti',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.blue[50],
                        foregroundColor: Colors.blue,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.blue.shade200),
                        ),
                      ),
                      icon: const Icon(Icons.image),
                      label: const Text(
                        'Lihat Preview Foto',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        if (photoUrl != null &&
                            photoUrl.toString().isNotEmpty) {
                          showDialog(
                            context: context,
                            builder: (_) => Dialog(
                              backgroundColor: Colors.transparent,
                              insetPadding: const EdgeInsets.all(16),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: InteractiveViewer(
                                  panEnabled: true,
                                  minScale: 0.5,
                                  maxScale: 4.0,
                                  child: Image.network(
                                    photoUrl,
                                    fit: BoxFit.contain,
                                    errorBuilder: (ctx, err, stack) =>
                                        Container(
                                          color: Colors.white,
                                          padding: const EdgeInsets.all(32.0),
                                          child: const Text(
                                            'Gagal memuat gambar',
                                            style: TextStyle(
                                              color: Colors.grey,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Tidak ada foto terlampir'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // KARTU INFORMASI LOKASI & STATUS
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Informasi Laporan',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(),
                          _buildDetailRow(
                            'Kepala Keluarga',
                            report['family_head_name'] ?? '-',
                          ),
                          _buildDetailRow('Desa', villageName),
                          _buildDetailRow(
                            'Alamat',
                            'RT ${report['rt']} / RW ${report['rw']}',
                          ),
                          _buildDetailRow('Koordinat', '$lat, $lng'),
                          _buildDetailRow('Tanggal Survei', dateStr),
                          _buildDetailRow(
                            'Status Jentik',
                            isPositive
                                ? 'POSITIF (Ditemukan)'
                                : 'NEGATIF (Bebas Jentik)',
                            valueColor: isPositive ? Colors.red : Colors.green,
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _showLocationOnMap(context, lat, lng),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              icon: const Icon(Icons.map, color: Colors.blue),
                              label: const Text('Lihat Lokasi di Peta'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // KARTU RINCIAN WADAH
                  const Text(
                    'Rincian Wadah Air',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  if (containers.isEmpty)
                    const Text(
                      'Tidak ada rincian wadah yang diisi.',
                      style: TextStyle(color: Colors.grey),
                    )
                  else
                    ...containers.map((c) {
                      String defaultName = 'Wadah Lainnya';
                      if (c['container_type'] != null) {
                        defaultName =
                            c['container_type']['name'] ?? defaultName;
                      }
                      final customName = c['custom_name'];
                      if (customName != null &&
                          customName.toString().isNotEmpty) {
                        defaultName = '$defaultName - $customName';
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue[50],
                            child: const Icon(
                              Icons.water_drop,
                              color: Colors.blue,
                            ),
                          ),
                          title: Text(
                            defaultName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Diperiksa: ${c['inspected_count']} | Positif Jentik: ${c['positive_count']}',
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 40),

                  // TOMBOL AKSI
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: const Icon(Icons.close),
                          label: const Text(
                            'Tolak',
                            style: TextStyle(fontSize: 16),
                          ),
                          onPressed: _showRejectBottomSheet,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: const Icon(Icons.check, color: Colors.white),
                          label: const Text(
                            'Terima',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                          onPressed: _showAcceptBottomSheet,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
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
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
