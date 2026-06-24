import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../../../../core/network/api_client.dart';

class OfficerDashboardPage extends StatefulWidget {
  const OfficerDashboardPage({super.key});

  @override
  State<OfficerDashboardPage> createState() => _OfficerDashboardPageState();
}

class _OfficerDashboardPageState extends State<OfficerDashboardPage> {
  final _apiClient = ApiClient();
  bool _isDownloading = false;

  // Fungsi untuk mengunduh dan membuka file Excel
  Future<void> _downloadRekapExcel() async {
    setState(() {
      _isDownloading = true;
    });

    try {
      // 1. Tembak API Backend dengan ResponseType.bytes
      final response = await _apiClient.dio.get(
        '/reports/export',
        options: Options(
          responseType:
              ResponseType.bytes, // Wajib agar tidak dibaca sebagai JSON
        ),
      );

      // 2. Cari direktori penyimpanan di HP
      Directory? directory;
      if (Platform.isAndroid) {
        // Untuk Android, taruh di folder eksternal agar mudah ditemukan
        directory = await getExternalStorageDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      // 3. Tentukan nama dan lokasi file
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String filePath = '${directory?.path}/Rekap_Jentik_$timestamp.xlsx';

      // 4. Tulis data biner dari server ke dalam file fisik di HP
      File file = File(filePath);
      await file.writeAsBytes(response.data);

      // 5. Beri tahu pengguna
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berhasil diunduh ke: $filePath'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // 6. Buka file menggunakan aplikasi Excel/WPS di HP pengguna
      await OpenFile.open(filePath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengunduh Excel: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Puskesmas'),
        actions: [
          // Tombol Export Excel
          IconButton(
            icon: _isDownloading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.blue, // Sesuaikan dengan warna tema AppBar
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.download_rounded),
            tooltip: 'Download Rekap Excel',
            onPressed: _isDownloading ? null : _downloadRekapExcel,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          const Text(
            'Selamat Datang,',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const Text(
            'Petugas Puskesmas',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),

          // Card Pintasan Informasi
          Card(
            color: Colors.blue[50],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 30),
                  SizedBox(height: 12),
                  Text(
                    'Status Sistem Pemantauan',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Sistem Radar Jentik saat ini beroperasi normal. Silakan periksa tab "Validasi" secara berkala untuk menyetujui laporan terbaru dari kader di lapangan.',
                    style: TextStyle(color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),
          // Tambahkan widget lain di sini jika kedepannya ada API Statistik
        ],
      ),
    );
  }
}
