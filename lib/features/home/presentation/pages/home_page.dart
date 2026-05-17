import 'package:flutter/material.dart';
import '../../../gis_map/data/models/risk_point_model.dart';
import '../../../gis_map/domain/entities/risk_point.dart';
import 'package:app/features/report_entry/presentation/pages/entry_form_page.dart';

class HomePage extends StatefulWidget {
  final Function(int) onNavigateToTab; // Untuk berpindah tab via tombol shortcut

  const HomePage({super.key, required this.onNavigateToTab});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int totalDanger = 0;
  int totalSafe = 0;
  int unsyncedCount = 0;

  @override
  void initState() {
    super.initState();
    _calculateStats();
  }

  void _calculateStats() {
    setState(() {
      // Menghitung statistik dari database simulasi
      totalDanger = MockDatabase.mapData.where((p) => p.level == RiskLevel.danger).length;
      totalSafe = MockDatabase.mapData.where((p) => p.level == RiskLevel.safe).length;
      unsyncedCount = MockDatabase.localReports.where((r) => !r.isSynced).length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: RefreshIndicator(
        onRefresh: () async {
          _calculateStats();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER BANNER ---
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFF143B59), // Konsisten dengan tema biru gelap utama
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Radar Jentik",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Halo, Nur Arifin", // Menyapa pengguna secara personal
                          style: TextStyle(
                            color: Colors.tealAccent[100],
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person, color: Colors.white, size: 32),
                    )
                  ],
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
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF143B59)),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Card Positif Jentik
                        Expanded(
                          child: _buildStatCard(
                            title: "Positif Jentik",
                            value: "$totalDanger",
                            color: const Color(0xFFE53935),
                            icon: Icons.warning_amber_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Card Bebas Jentik
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

              // --- SEKSI MENU AKS CEPAT (QUICK ACTIONS) ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Menu Pintar",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF143B59)),
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
                              MaterialPageRoute(builder: (context) => const EntryFormPage()),
                            );
                            _calculateStats();
                          },
                        ),
                        _buildMenuButton(
                          icon: Icons.map_rounded,
                          label: "Peta Zonasi",
                          color: const Color(0xFF143B59),
                          onTap: () => widget.onNavigateToTab(1), // Navigasi ke Tab Peta
                        ),
                        _buildMenuButton(
                          icon: Icons.sync_rounded,
                          label: "Sinkronisasi",
                          color: const Color(0xFFFF6D00), // Warna orange khas tombol sinkronisasi
                          badge: unsyncedCount > 0 ? "$unsyncedCount" : null,
                          onTap: () => widget.onNavigateToTab(0), // Navigasi ke Tab Sinkronisasi
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // --- SEKSI TAMPILAN INFORMASI EDUKASI / FEED ---
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
                        Icon(Icons.health_and_safety_rounded, color: Colors.teal[700], size: 40),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Tips Gerakan 3M Plus",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Pastikan menguras bak mandi secara berkala seminggu sekali untuk memutus siklus hidup nyamuk.",
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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

  Widget _buildStatCard({required String title, required String value, required Color color, required IconData icon}) {
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
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Text(
                  title == "Positif Jentik" ? "Rawan" : "Aman",
                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500),
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
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
            ],
          ),
          if (badge != null)
            Positioned(
              top: 12,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text(
                  badge,
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}