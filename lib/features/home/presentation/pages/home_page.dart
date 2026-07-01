import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/local_db/db_helper.dart';
import '../../../sync_dashboard/presentation/pages/sync_dashboard_page.dart';
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

  // Variabel State Loading
  bool _isDownloading = false;
  bool _isLoadingStats = true;

  // Variabel Statistik Nyata (Real API + SQLite)
  int _totalDanger = 0;
  int _totalSafe = 0;
  int _myTotalReports = 0;
  int _pendingValidations = 0;

  // TAMBAHAN: Variabel untuk antrean sinkronisasi
  int _unsyncedCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
  }

  // ==========================================
  // Inisialisasi Berurutan
  // ==========================================
  Future<void> _initializeDashboard() async {
    setState(() => _isLoadingStats = true);
    await _loadUserData();
    await _fetchStats();
    setState(() => _isLoadingStats = false);
  }

  // ==========================================
  // 1. Memuat Data User & Role
  // ==========================================
  Future<void> _loadUserData() async {
    String? storedRole = await _storage.read(key: 'user_role');
    if (storedRole != null) {
      setState(() => _role = storedRole);
    }

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
  // 2. Fungsi Hitung Statistik (API Asli + SQLite)
  // ==========================================
  Future<void> _fetchStats() async {
    try {
      // --- Hitung Antrean Lokal SQFLITE ---
      final localReports = await DatabaseHelper.instance.getPendingReports();
      if (mounted) {
        setState(() {
          _unsyncedCount = localReports.length;
        });
      }

      // A. Statistik Wilayah (Berdasarkan Data Peta Zonasi / Validasi 'accept')
      final mapResponse = await _apiClient.dio.get('/reports/map');
      if (mapResponse.statusCode == 200) {
        final List<dynamic> mapData = mapResponse.data['data'] ?? [];
        int danger = 0;
        int safe = 0;

        for (var report in mapData) {
          if (report['larvae_status'] == 1) {
            danger++;
          } else {
            safe++;
          }
        }
        if (mounted) {
          setState(() {
            _totalDanger = danger;
            _totalSafe = safe;
          });
        }
      }

      // B. Statistik Kinerja berdasarkan Role
      if (_role == 'cadre') {
        final historyResponse = await _apiClient.dio.get(
          '/reports/history',
          queryParameters: {'page': 1, 'limit': 1},
        );
        if (historyResponse.statusCode == 200) {
          if (mounted) {
            setState(() {
              _myTotalReports =
                  historyResponse.data['meta']?['total_items'] ?? 0;
            });
          }
        }
      } else if (_role == 'officer') {
        final pendingResponse = await _apiClient.dio.get(
          '/reports/pending',
          queryParameters: {'page': 1, 'limit': 1},
        );
        if (pendingResponse.statusCode == 200) {
          if (mounted) {
            setState(() {
              _pendingValidations =
                  pendingResponse.data['meta']?['total_items'] ?? 0;
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Gagal memuat statistik: $e");
    }
  }

  // ==========================================
  // 3. Fungsi Unduh Excel (Khusus Officer)
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
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
              "Halo, $_fullName",
              style: TextStyle(color: Colors.tealAccent[100], fontSize: 14),
            ),
          ],
        ),
        actions: [
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
        onRefresh: _initializeDashboard,
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

              // --- SEKSI RINGKASAN STATISTIK WILAYAH ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Ringkasan Wilayah (Valid)",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF143B59),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_isLoadingStats)
                      const Center(child: CircularProgressIndicator())
                    else ...[
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              title: "Positif Jentik",
                              value: "$_totalDanger",
                              color: const Color(0xFFE53935),
                              icon: Icons.warning_amber_rounded,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              title: "Bebas Jentik",
                              value: "$_totalSafe",
                              color: const Color(0xFF43A047),
                              icon: Icons.gpp_good_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // --- STATISTIK KINERJA SESUAI ROLE ---
                      if (_role == 'cadre')
                        _buildFullWidthStatCard(
                          title: "Total Laporan Saya",
                          value: "$_myTotalReports Laporan",
                          color: Colors.blue,
                          icon: Icons.history_edu_rounded,
                        ),

                      if (_role == 'officer')
                        _buildFullWidthStatCard(
                          title: "Antrean Validasi Laporan",
                          value: "$_pendingValidations Menunggu",
                          color: Colors.orange,
                          icon: Icons.pending_actions_rounded,
                        ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // --- SEKSI MENU PINTAR ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Pintasan",
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
                        /*
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
                            _initializeDashboard(); // Refresh stats setelah melapor
                          },
                        ),
                        _buildMenuButton(
                          icon: Icons.map_rounded,
                          label: "Peta Zonasi",
                          color: const Color(0xFF143B59),
                          onTap: () => widget.onNavigateToTab(1),
                        ),
                        */

                        // ===========================================
                        // MENU KHUSUS KADER (Sinkronisasi & Riwayat)
                        // ===========================================
                        if (_role == 'cadre') ...[
                          _buildMenuButton(
                            icon: Icons.sync_rounded,
                            label: "Sinkronisasi",
                            color: const Color(0xFFFF6D00),
                            // Munculkan notifikasi angka (badge) jika ada antrean
                            badge: _unsyncedCount > 0
                                ? "$_unsyncedCount"
                                : null,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const SyncDashboardPage(),
                                ),
                              );
                              _initializeDashboard(); // Refresh angka antrean setelah sinkronisasi
                            },
                          ),
                          /*
                          _buildMenuButton(
                            icon: Icons.history_rounded,
                            label: "Riwayat",
                            color: Colors.blue,
                            onTap: () => widget.onNavigateToTab(
                              1,
                            ), // Arahkan ke Tab Riwayat
                          ),
                          */
                        ],

                        // ===========================================
                        // MENU KHUSUS OFFICER (Validasi)
                        // ===========================================
                        /*
                        if (_role == 'officer')
                          _buildMenuButton(
                            icon: Icons.checklist_rtl_rounded,
                            label: "Validasi",
                            color: Colors.orange,
                            onTap: () => widget.onNavigateToTab(0),
                          ),
                          */
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

  // UI Helper: Kartu Setengah Lebar Layar
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

  // UI Helper: Kartu Panjang Penuh Layar
  Widget _buildFullWidthStatCard({
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
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
