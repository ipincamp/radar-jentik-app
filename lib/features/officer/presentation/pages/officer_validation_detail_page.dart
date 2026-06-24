import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

class OfficerValidationDetailPage extends StatefulWidget {
  // Menampung data laporan yang dilempar dari ListView sebelumnya
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

  // Fungsi untuk mengeksekusi PUT /reports/:id/validate
  Future<void> _validateReport(String status, {String? rejectionReason}) async {
    setState(() => _isLoading = true);

    try {
      final reportId = widget.reportData['id'];

      // Siapkan payload
      final Map<String, dynamic> payload = {'status': status};

      // Jika ditolak dan ada alasannya, masukkan ke payload
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
                'Laporan berhasil di${status == 'accept' ? 'terima' : 'tolak'}',
              ),
              backgroundColor: status == 'accept' ? Colors.green : Colors.red,
            ),
          );
          // Kembali ke halaman sebelumnya dengan membawa nilai 'true' (agar list me-refresh dirinya)
          Navigator.pop(context, true);
        }
      }
    } on DioException catch (e) {
      String errMsg = 'Gagal memvalidasi laporan';
      if (e.response != null && e.response?.data != null) {
        errMsg = e.response?.data['error'] ?? errMsg;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errMsg), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Dialog khusus untuk PENOLAKAN (dengan input teks)
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
                hintText: 'Contoh: Foto kurang jelas, data RT/RW salah...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Tutup dialog
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                // Cegah petugas submit jika alasan masih kosong
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Alasan penolakan wajib diisi!'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              Navigator.pop(context); // Tutup dialog
              _validateReport(
                'reject',
                rejectionReason: reason,
              ); // Eksekusi tolak
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

  // Dialog khusus untuk PENERIMAAN (hanya konfirmasi Yes/No)
  void _showAcceptDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Terima'),
        content: const Text(
          'Apakah Anda yakin ingin menerima laporan ini? Data akan masuk ke dalam rekapitulasi Puskesmas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Tutup dialog
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              Navigator.pop(context); // Tutup dialog
              _validateReport('accept'); // Eksekusi terima
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

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Validasi')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Card Info Utama
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
                          _buildDetailRow(
                            'Alamat',
                            'RT ${report['rt']} / RW ${report['rw']}',
                          ),
                          _buildDetailRow(
                            'Koordinat',
                            '${report['latitude']}, ${report['longitude']}',
                          ),
                          _buildDetailRow(
                            'Tanggal Survei',
                            report['inspected_at']?.toString().split('T')[0] ??
                                '-',
                          ),
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

                  // 2. Card Rincian Wadah Air
                  const Text(
                    'Rincian Wadah Air',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  if (containers.isEmpty)
                    const Text(
                      'Tidak ada data rincian wadah.',
                      style: TextStyle(color: Colors.grey),
                    )
                  else
                    ...containers.map(
                      (c) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(
                            Icons.water_drop,
                            color: Colors.blue,
                          ),
                          title: Text(c['container_type'] ?? 'Wadah'),
                          subtitle: Text(
                            'Diperiksa: ${c['inspected_count']} | Positif Jentik: ${c['positive_count']}',
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 40),

                  // 3. Tombol Aksi Terima/Tolak
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          // PANGGIL FUNGSI REJECT DI SINI
                          onPressed: _showRejectDialog,
                          child: const Text(
                            'Tolak Laporan',
                            style: TextStyle(fontSize: 16),
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
                          // PANGGIL FUNGSI ACCEPT DI SINI
                          onPressed: _showAcceptDialog,
                          child: const Text(
                            'Terima Laporan',
                            style: TextStyle(fontSize: 16, color: Colors.white),
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

  // Fungsi helper untuk UI Row
  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
