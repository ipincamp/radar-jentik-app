import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/local_db/db_helper.dart';
import '../../../cadre/presentation/pages/cadre_report_detail_page.dart';

class SyncDashboardPage extends StatefulWidget {
  const SyncDashboardPage({super.key});

  @override
  State<SyncDashboardPage> createState() => _SyncDashboardPageState();
}

class _SyncDashboardPageState extends State<SyncDashboardPage> {
  final _apiClient = ApiClient();

  List<Map<String, dynamic>> _pendingReports = [];
  bool _isLoading = true;
  bool _isSyncing = false;

  int _successCount = 0;
  int _failCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPendingReports();
  }

  Future<void> _loadPendingReports() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getPendingReports();
    setState(() {
      _pendingReports = data;
      _isLoading = false;
    });
  }

  Future<void> _startSync() async {
    // ========================================================
    // 1. PERBAIKAN CEK KONEKSI INTERNET (Tipe List)
    // ========================================================
    final List<ConnectivityResult> connectivityResult = await (Connectivity()
        .checkConnectivity());
    bool isOffline = connectivityResult.contains(ConnectivityResult.none);

    if (isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tidak ada koneksi internet. Cari sinyal (WiFi/Seluler) terlebih dahulu!',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return; // Hentikan fungsi jika memang tidak ada internet
    }

    setState(() {
      _isSyncing = true;
      _successCount = 0;
      _failCount = 0;
    });

    // 2. Loop semua data di SQLite (FORWARD)
    for (var report in _pendingReports) {
      int id = report['id'];
      String localImagePath = report['local_image_path'] ?? '';
      String payloadJson = report['payload_json'];

      try {
        Map<String, dynamic> payload = jsonDecode(payloadJson);

        // A. Upload Foto JIKA file exist dan path tidak kosong
        if (localImagePath.isNotEmpty) {
          File imageFile = File(localImagePath);
          if (imageFile.existsSync()) {
            String fileName = localImagePath.split('/').last;
            FormData formData = FormData.fromMap({
              "photo": await MultipartFile.fromFile(
                localImagePath,
                filename: fileName,
              ),
            });

            final uploadRes = await _apiClient.dio.post(
              '/uploads',
              data: formData,
            );
            if (uploadRes.statusCode == 200 || uploadRes.statusCode == 201) {
              String photoUrl = uploadRes.data['data']['photo_url'];
              payload["photo_url"] = photoUrl;
            }
          }
        }

        // B. Kirim Laporan ke Backend (Dengan/Tanpa Foto)
        final reportRes = await _apiClient.dio.post('/reports', data: payload);

        if (reportRes.statusCode == 201 || reportRes.statusCode == 200) {
          // C. Jika Berhasil, hapus dari database lokal
          await DatabaseHelper.instance.deletePendingReport(id);
          _successCount++;
        } else {
          _failCount++;
        }
      } catch (e) {
        _failCount++;
      }
    }

    // 3. Selesai Sinkronisasi
    setState(() => _isSyncing = false);
    _loadPendingReports(); // Refresh tampilan

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sinkronisasi Selesai! Berhasil: $_successCount, Gagal: $_failCount',
          ),
          backgroundColor: _failCount == 0 ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Sinkronisasi Data',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFFF6D00), // Warna oranye pembeda
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  width: double.infinity,
                  color: Colors.white,
                  child: Column(
                    children: [
                      Icon(
                        _pendingReports.isEmpty
                            ? Icons.cloud_done
                            : Icons.cloud_off_rounded,
                        size: 80,
                        color: _pendingReports.isEmpty
                            ? Colors.green
                            : Colors.orange,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _pendingReports.isEmpty
                            ? 'Semua Data Telah Tersinkronisasi'
                            : '${_pendingReports.length} Laporan Menunggu Pengiriman',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pastikan Anda berada di area dengan koneksi internet (4G/WiFi) yang stabil sebelum memulai sinkronisasi.',
                        style: TextStyle(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Menampilkan progres jika sedang syncing
                if (_isSyncing)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        const LinearProgressIndicator(color: Color(0xFFFF6D00)),
                        const SizedBox(height: 8),
                        Text(
                          'Mempersiapkan pengiriman data...',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),

                Expanded(
                  child: _pendingReports.isEmpty
                      ? const SizedBox.shrink()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _pendingReports.length,
                          itemBuilder: (context, index) {
                            final report = _pendingReports[index];
                            final payload = jsonDecode(report['payload_json']);
                            final rtRw =
                                'RT ${payload['rt']} / RW ${payload['rw']}';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Colors.orange,
                                  child: Icon(
                                    Icons.upload_file,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  payload['family_head_name'] ?? 'Data Warga',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(rtRw),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: Colors.grey,
                                  size: 16,
                                ), // Ganti Ikon jadi Panah
                                // --- TAMBAHKAN ON TAP DI SINI ---
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CadreReportDetailPage(
                                        reportData:
                                            payload, // Kirim Payload JSON
                                        isOffline:
                                            true, // Beritahu bahwa ini offline (belum sinkron)
                                        localImagePath:
                                            report['local_image_path'], // Kirim jalur fisik gambar di memori HP
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      bottomNavigationBar: _pendingReports.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6D00),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _isSyncing ? null : _startSync,
                icon: _isSyncing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.sync, color: Colors.white),
                label: Text(
                  _isSyncing ? 'MENGIRIM DATA...' : 'SINKRONISASI SEKARANG',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
    );
  }
}
