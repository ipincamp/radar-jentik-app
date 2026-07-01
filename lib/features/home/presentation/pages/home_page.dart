import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

import '../../../../core/network/api_client.dart';
import '../../../gis_map/data/models/risk_point_model.dart';
import '../../../gis_map/domain/entities/risk_point.dart';
import 'package:app/features/report_entry/presentation/pages/entry_form_page.dart';

class HomePage extends StatefulWidget {
  final Function(int) onNavigateToTab;

  const HomePage({super.key, required this.onNavigateToTab});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _apiClient = ApiClient();
  final _storage = const FlutterSecureStorage();

  // Variabel Data Pengguna
  String _role = 'cadre';
  String _fullName = 'Memuat...';

  // Variabel State
  bool _isDownloading = false;
  int totalDanger = 0;
  int totalSafe = 0;
  int unsyncedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _calculateStats();
  }

  // ==========================================
  // 1. Memuat Data User & Role
  // ==========================================
  Future<void> _loadUserData() async {
    // Ambil Role dari Storage
    String? storedRole = await _storage.read(key: 'user_role');
    if (storedRole != null) {
      setState(() => _role = storedRole);
    }

    // Ambil Nama dari API Backend
    try {
      final response = await _apiClient.dio.get('/users/me');
      if (response.statusCode == 200) {
        setState(() {
          _fullName = response.data['data']['full_name'] ?? 'Pengguna';
        });
      }
    } catch (e) {
      setState(() => _fullName = 'Pengguna Jentik');
    }
  }

  // ==========================================
  // 2. Fungsi Unduh Excel (Khusus Officer)
  // ==========================================
  Future<void> _downloadRekapExcel() async {
    setState(() => _isDownloading = true);

    try {
      final response = await _apiClient.dio.get(
        '/reports/export',
        options: Options(responseType: ResponseType.bytes),
      );

      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String filePath = '${directory?.path}/Rekap_Jentik_$timestamp.xlsx';

      File file = File(filePath);
      await file.writeAsBytes(response.data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berhasil diunduh ke: $filePath'),
            backgroundColor: Colors.green,
          ),
        );
      }

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
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  // ==========================================
  // 3. Kalkulasi Statistik Peta (Mock Database / Real Nanti)
  // ==========================================
  void _calculateStats() {
    setState(() {
      totalDanger = MockDatabase.mapData
          .where((p) => p.level == RiskLevel.danger)
          .length;
      totalSafe = MockDatabase.mapData
          .where((p) => p.level == RiskLevel.safe)
          .length;
      unsyncedCount = MockDatabase.localReports
          .where((r) => !r.isSynced)
          .length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      // MENGGUNAKAN APPBAR AGAR TOMBOL DOWNLOAD EXCEL RAPI DI POJOK KANAN
      appBar: AppBar(
        backgroundColor: const Color(0xFF143B59),
        elevation: 0,
        toolbarHeight: 70,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Radar Jentik",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Halo, $_fullName", // Dinamis dari API
              style: TextStyle(color: Colors.tealAccent[100], fontSize: 14),
            ),
          ],
        ),
        actions: [
          // LOGIKA FILTER: HANYA TAMPIL JIKA ROLE == OFFICER
          if (_role == 'officer')
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                icon: _isDownloading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Icon(
                        Icons.download_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                tooltip: 'Download Rekap Excel',
                onPressed: _isDownloading ? null : _downloadRekapExcel,
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadUserData();
          _calculateStats();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Lengkungan bawah warna biru sisa dari AppBar
              Container(
                width: double.infinity,
                height: 30,
                decoration: const BoxDecoration(
                  color: Color(0xFF143B59),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // --- SEKSI RINGKASAN STATISTIK ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Ringkasan Wilayah",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF143B59),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            title: "Positif Jentik",
                            value: "$totalDanger",
                            color: const Color(0xFFE53935),
                            icon: Icons.warning_amber_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            title: "Bebas Jentik",
                            value: "$totalSafe",
                            color: const Color(0xFF43A047),
                            icon: Icons.gpp_good_rounded,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // --- SEKSI MENU AKSES CEPAT ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Menu Pintar",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF143B59),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildMenuButton(
                          icon: Icons.add_location_alt_rounded,
                          label: "Lapor Jentik",
                          color: Colors.teal,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EntryFormPage(),
                              ),
                            );
                            _calculateStats();
                          },
                        ),
                        _buildMenuButton(
                          icon: Icons.map_rounded,
                          label: "Peta Zonasi",
                          color: const Color(0xFF143B59),
                          onTap: () => widget.onNavigateToTab(1),
                        ),

                        // Menu Khusus Kader: Sinkronisasi Offline (Contoh)
                        if (_role == 'cadre')
                          _buildMenuButton(
                            icon: Icons.sync_rounded,
                            label: "Sinkronisasi",
                            color: const Color(0xFFFF6D00),
                            badge: unsyncedCount > 0 ? "$unsyncedCount" : null,
                            onTap: () => widget.onNavigateToTab(0),
                          ),

                        // Menu Khusus Officer: Validasi Laporan
                        if (_role == 'officer')
                          _buildMenuButton(
                            icon: Icons.checklist_rtl_rounded,
                            label: "Validasi",
                            color: Colors.orange,
                            onTap: () => widget.onNavigateToTab(
                              0,
                            ), // Asumsi Tab 0 adalah Validasi di Officer Nav
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // --- FEED EDUKASI ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.health_and_safety_rounded,
                          color: Colors.teal[700],
                          size: 40,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Tips Gerakan 3M Plus",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Pastikan menguras bak mandi secara berkala seminggu sekali untuk memutus siklus hidup nyamuk.",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 28),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  title == "Positif Jentik" ? "Rawan" : "Aman",
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    String? badge,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          if (badge != null)
            Positioned(
              top: 12,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
