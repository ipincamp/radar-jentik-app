import 'dart:io';
import 'package:flutter/material.dart';

class CadreReportDetailPage extends StatelessWidget {
  final Map<String, dynamic> reportData;
  final bool isOffline;
  final String? localImagePath;

  const CadreReportDetailPage({
    super.key,
    required this.reportData,
    this.isOffline = false,
    this.localImagePath,
  });

  @override
  Widget build(BuildContext context) {
    // --- PARSING DATA (BISA DARI API ATAU SQLITE LOKAL) ---

    // 1. Lokasi & Waktu
    final headName = reportData['family_head_name'] ?? '-';
    final rtRw = 'RT ${reportData['rt']} / RW ${reportData['rw']}';

    String villageName = '-';
    if (!isOffline && reportData['village'] != null) {
      villageName = reportData['village']['name'] ?? '-';
    } else if (isOffline) {
      villageName = 'Menunggu Sinkronisasi'; // Offline belum preload nama desa
    }

    String dateStr = '-';
    if (reportData['inspected_at'] != null) {
      try {
        final parsed = DateTime.parse(reportData['inspected_at']).toLocal();
        dateStr =
            "${parsed.day}/${parsed.month}/${parsed.year} ${parsed.hour}:${parsed.minute.toString().padLeft(2, '0')}";
      } catch (_) {}
    }

    // 2. Status Jentik
    bool isPositive = false;
    if (!isOffline) {
      isPositive = reportData['larvae_status'] == 1;
    } else {
      // Jika offline, hitung manual dari jumlah wadah positif
      final containers = reportData['containers'] as List<dynamic>? ?? [];
      isPositive = containers.any((c) => (c['positive_count'] ?? 0) > 0);
    }

    // 3. Status Validasi
    String statusLabel = 'Menunggu Sinkronisasi';
    Color statusColor = Colors.orange;
    String? rejectionReason;

    if (!isOffline) {
      final valStatus = reportData['validation_status'] ?? 'pending';
      rejectionReason = reportData['rejection_reason'];

      if (valStatus == 'accept') {
        statusLabel = 'Diterima Petugas';
        statusColor = Colors.green;
      } else if (valStatus == 'reject') {
        statusLabel = 'Ditolak';
        statusColor = Colors.red;
      } else {
        statusLabel = 'Menunggu Validasi';
        statusColor = Colors.orange;
      }
    }

    // 4. Data Wadah (Difilter hanya yang memiliki nilai > 0)
    final rawContainersList = isOffline
        ? (reportData['containers'] as List<dynamic>? ?? [])
        : (reportData['container_details'] as List<dynamic>? ?? []);

    final containersList = rawContainersList.where((c) {
      final inspected =
          int.tryParse(c['inspected_count']?.toString() ?? '0') ?? 0;
      final positive =
          int.tryParse(c['positive_count']?.toString() ?? '0') ?? 0;
      return inspected > 0 || positive > 0;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Detail Laporan',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF143B59),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================
            // STATUS LAPORAN (HEADER)
            // ==========================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        statusColor == Colors.green
                            ? Icons.check_circle
                            : statusColor == Colors.red
                            ? Icons.cancel
                            : Icons.pending_actions,
                        color: statusColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                  if (rejectionReason != null &&
                      rejectionReason.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Alasan Penolakan:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rejectionReason,
                      style: TextStyle(fontSize: 14, color: Colors.red[900]),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ==========================================
            // FOTO BUKTI (MENGGUNAKAN POP-UP PREVIEW)
            // ==========================================
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
                  // Cek apakah ada foto lokal atau foto dari server
                  if (isOffline && localImagePath != null) {
                    _showPhotoDialog(
                      context,
                      isLocal: true,
                      path: localImagePath!,
                    );
                  } else if (reportData['photo_url'] != null &&
                      reportData['photo_url'].toString().isNotEmpty) {
                    _showPhotoDialog(
                      context,
                      isLocal: false,
                      path: reportData['photo_url'],
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

            // ==========================================
            // INFORMASI LOKASI
            // ==========================================
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informasi Wilayah',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    _buildDetailRow('Kepala Keluarga', headName),
                    _buildDetailRow('Alamat', rtRw),
                    _buildDetailRow('Desa', villageName),
                    _buildDetailRow('Tanggal Lapor', dateStr),
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

            // ==========================================
            // RINCIAN WADAH
            // ==========================================
            const Text(
              'Rincian Wadah Air',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (containersList.isEmpty)
              const Text(
                'Tidak ada rincian wadah yang diisi.',
                style: TextStyle(color: Colors.grey),
              )
            else
              ...containersList.map((c) {
                // Menentukan nama wadah baik saat online / offline
                String name = 'Wadah';
                if (!isOffline && c['container_type'] != null) {
                  name = c['container_type']['name'] ?? 'Wadah Standar';
                }

                final customName = c['custom_name'];
                if (customName != null && customName.toString().isNotEmpty) {
                  name = isOffline ? customName : '$name - $customName';
                } else if (isOffline) {
                  name = 'Data Wadah Tersimpan';
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue[50],
                      child: const Icon(Icons.water_drop, color: Colors.blue),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Diperiksa: ${c['inspected_count']} | Positif Jentik: ${c['positive_count']}',
                    ),
                  ),
                );
              }),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Helper untuk menampilkan dialog pop-up foto
  void _showPhotoDialog(
    BuildContext context, {
    required bool isLocal,
    required String path,
  }) {
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
            child: isLocal
                ? Image.file(
                    File(path),
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, err, stack) => _buildErrorImage(),
                  )
                : Image.network(
                    path,
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, err, stack) => _buildErrorImage(),
                  ),
          ),
        ),
      ),
    );
  }

  // Widget fallback jika gagal memuat gambar
  Widget _buildErrorImage() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(32.0),
      child: const Text(
        'Gagal memuat gambar',
        style: TextStyle(color: Colors.grey),
        textAlign: TextAlign.center,
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
