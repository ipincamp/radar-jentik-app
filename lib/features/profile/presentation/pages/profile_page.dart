import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _storage = const FlutterSecureStorage();
  final _apiClient = ApiClient();

  // Variabel penampung data profil
  bool _isLoadingProfile = true;
  bool _isLoggingOut = false;

  String _fullName = 'Memuat...';
  String _username = '-';
  String _role = '-';
  String _rawRole = '';
  String? _villageName;

  @override
  void initState() {
    super.initState();
    _fetchMyProfile();
  }

  // ==========================================
  // Fungsi Mengambil Data Profil dari Backend
  // ==========================================
  Future<void> _fetchMyProfile() async {
    setState(() => _isLoadingProfile = true);
    try {
      // Memanggil endpoint GetMe di Go
      final response = await _apiClient.dio.get('/users/me');

      if (response.statusCode == 200) {
        final data = response.data['data'];

        setState(() {
          _fullName = data['full_name'] ?? 'Pengguna Tanpa Nama';
          _username = data['username'] ?? '-';
          _rawRole = data['role'] ?? 'cadre';

          // Format nama role agar lebih enak dibaca
          _role = _rawRole == 'officer'
              ? 'Petugas Puskesmas'
              : 'Kader Kesehatan';

          // Opsional: Jika backend melakukan Preload relasi Village
          if (data['village'] != null && data['village']['name'] != null) {
            _villageName = data['village']['name'];
          }
        });
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Gagal memuat profil'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingProfile = false);
      }
    }
  }

  // ==========================================
  // Fungsi Logout
  // ==========================================
  Future<void> _handleLogout() async {
    setState(() => _isLoggingOut = true);
    try {
      // Beritahu backend bahwa kita logout (Endpoint Logout di auth_handler.go)
      await _apiClient.dio.post('/auth/logout');
    } catch (e) {
      // Abaikan error jika API menolak, yang penting hapus token lokal
    } finally {
      // 1. Bersihkan seluruh token & sesi lokal
      await _storage.deleteAll();

      if (mounted) {
        // 2. Arahkan kembali ke LoginPage dan bersihkan tumpukan navigasi
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Profil Saya', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF143B59),
        elevation: 0,
      ),
      body: _isLoadingProfile
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Bagian Header Profil (Latar Biru dengan Avatar)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(bottom: 30, top: 20),
                    decoration: const BoxDecoration(
                      color: Color(0xFF143B59),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.person,
                            size: 70,
                            color: Color(0xFF143B59),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _fullName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '@$_username',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.blue[100],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Bagian Kartu Informasi Detail
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        // Card Status Role
                        _buildInfoCard(
                          icon: _rawRole == 'officer'
                              ? Icons.admin_panel_settings
                              : Icons.health_and_safety,
                          iconColor: _rawRole == 'officer'
                              ? Colors.orange
                              : Colors.green,
                          title: 'Peran Akun',
                          value: _role,
                        ),
                        const SizedBox(height: 16),

                        // Card Desa (Hanya muncul jika relasi desa tersedia)
                        if (_villageName != null) ...[
                          _buildInfoCard(
                            icon: Icons.location_city,
                            iconColor: Colors.blue,
                            title: 'Wilayah Penugasan',
                            value: 'Desa $_villageName',
                          ),
                          const SizedBox(height: 16),
                        ],

                        const SizedBox(height: 30),

                        // Tombol Keluar (Logout)
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(
                                color: Colors.red,
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _isLoggingOut ? null : _handleLogout,
                            icon: _isLoggingOut
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.red,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.logout),
                            label: const Text(
                              'Keluar (Logout)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Helper Widget untuk membuat Kartu Info (Informasi Profil)
  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
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
}
