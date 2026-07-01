import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
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

  void _showRejectDialog() {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tolak Laporan', style: TextStyle(color: Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
              'Tolak Laporan',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showAcceptDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Terima'),
        content: const Text(
          'Apakah Anda yakin ingin menerima laporan ini? Data akan diverifikasi secara permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              Navigator.pop(context);
              _validateReport('accept');
            },
            child: const Text(
              'Ya, Terima',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.reportData;
    final containers = report['container_details'] as List<dynamic>? ?? [];
    final isPositive = report['larvae_status'] == 1;
    final photoUrl = report['photo_url'];

    final villageName = report['village'] != null
        ? report['village']['name']
        : '-';

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
                  // FOTO BUKTI (SEKARANG BISA DI-KLIK)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Foto Bukti',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (photoUrl != null && photoUrl.toString().isNotEmpty)
                        const Text(
                          'Ketuk foto untuk perbesar',
                          style: TextStyle(fontSize: 12, color: Colors.blue),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Container(
                    width: double.infinity,
                    height: 250,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: photoUrl != null && photoUrl.toString().isNotEmpty
                          // Gunakan Material & InkWell agar ada efek saat diklik
                          ? Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  // Navigasi ke halaman FullScreen
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => FullScreenImageViewer(
                                        imageUrl: photoUrl.toString(),
                                      ),
                                    ),
                                  );
                                },
                                // Hero Animation agar foto membesar dengan mulus
                                child: Hero(
                                  tag: 'photo_$photoUrl',
                                  child: Image.network(
                                    photoUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, stack) =>
                                        const Center(
                                          child: Text(
                                            'Gagal memuat gambar',
                                            style: TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                  ),
                                ),
                              ),
                            )
                          : const Center(
                              child: Text(
                                'Tidak ada foto terlampir',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
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
                          _buildDetailRow(
                            'Koordinat',
                            '${report['latitude']}, ${report['longitude']}',
                          ),
                          _buildDetailRow('Tanggal Survei', dateStr),
                          _buildDetailRow(
                            'Status Jentik',
                            isPositive
                                ? 'POSITIF (Ditemukan)'
                                : 'NEGATIF (Bebas Jentik)',
                            valueColor: isPositive ? Colors.red : Colors.green,
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
                      'Tidak ada rincian wadah dilaporkan.',
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
                          onPressed: _showRejectDialog,
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
                          onPressed: _showAcceptDialog,
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

// =========================================================================
// WIDGET BARU: HALAMAN UNTUK MELIHAT FOTO UKURAN PENUH (FULL SCREEN)
// =========================================================================
class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;

  const FullScreenImageViewer({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Latar belakang hitam untuk fokus ke foto
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Center(
        // InteractiveViewer memungkinkan pengguna untuk zoom in/out (cubit) & geser
        child: InteractiveViewer(
          panEnabled: true, // Bisa digeser-geser saat di-zoom
          minScale: 0.5,
          maxScale: 4.0, // Batas maksimal zoom
          child: Hero(
            tag: 'photo_$imageUrl',
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain, // Pastikan seluruh gambar muat di layar
              errorBuilder: (ctx, err, stack) => const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, color: Colors.white54, size: 50),
                  SizedBox(height: 10),
                  Text(
                    'Gagal memuat gambar',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
