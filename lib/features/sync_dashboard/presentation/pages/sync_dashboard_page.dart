import 'package:flutter/material.dart';
import '../../../gis_map/data/models/risk_point_model.dart';
import '../../../gis_map/domain/entities/risk_point.dart';
import '../../../report_entry/domain/entities/larvae_report.dart';

class SyncDashboardPage extends StatefulWidget {
  const SyncDashboardPage({super.key});

  @override
  State<SyncDashboardPage> createState() => _SyncDashboardPageState();
}

class _SyncDashboardPageState extends State<SyncDashboardPage> {
  List<LarvaeReport> unsyncedReports = [];
  bool isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      unsyncedReports = MockDatabase.localReports
          .where((r) => !r.isSynced)
          .toList();
    });
  }

  Future<void> _syncData() async {
    if (unsyncedReports.isEmpty) return;
    setState(() => isSyncing = true);

    // Simulasi proses upload
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      for (var report in unsyncedReports) {
        report.isSynced = true; // Tandai sukses
        // Masukkan ke Peta
        MockDatabase.mapData.add(
          RiskPoint(
            latitude: report.latitude,
            longitude: report.longitude,
            value: report.isPositive ? 1.0 : 0.0,
            level: report.isPositive ? RiskLevel.danger : RiskLevel.safe,
            notes: "${report.headOfFamily} - ${report.address}",
            imagePath: report.imagePath,
            timestamp: report.timestamp,
          ),
        );
      }
      isSyncing = false;
      _loadData(); // Refresh UI
    });

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Sinkronisasi Selesai!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Status Sinkronisasi",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF143B59), // Biru gelap
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header Status
          Container(
            color: const Color(0xFF143B59),
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "STATUS SINKRONISASI:\n${unsyncedReports.length} LAPORAN LURING",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                isSyncing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Icon(
                        Icons.cloud_off,
                        color: Colors.tealAccent,
                        size: 40,
                      ),
              ],
            ),
          ),

          // List Laporan
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: unsyncedReports.length,
              itemBuilder: (context, index) {
                final r = unsyncedReports[index];
                final timeStr =
                    "${r.timestamp.hour.toString().padLeft(2, '0')}:${r.timestamp.minute.toString().padLeft(2, '0')} WIB";

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(
                      r.headOfFamily,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Lokasi, Jentik (${r.isPositive ? '+' : '-'})"),
                        const SizedBox(height: 4),
                        Text(
                          timeStr,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    trailing: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Icon(
                          Icons.notifications_off,
                          color: Colors.red,
                          size: 16,
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Belum Terkirim",
                          style: TextStyle(color: Colors.red, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Tombol Sinkronisasi
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6D00), // Warna Orange
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: isSyncing || unsyncedReports.isEmpty
                  ? null
                  : _syncData,
              child: const Text(
                "SINKRONISASI DATA",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
