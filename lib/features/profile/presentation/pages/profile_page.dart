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

  String _role = 'Pengguna';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    String? role = await _storage.read(key: 'user_role');
    setState(() {
      _role = role == 'officer' ? 'Petugas Puskesmas' : 'Kader Kesehatan';
    });
  }

  Future<void> _handleLogout() async {
    setState(() => _isLoading = true);
    try {
      // (Opsional) Beritahu backend bahwa kita logout
      await _apiClient.dio.post('/auth/logout');
    } catch (e) {
      // Abaikan error jika backend menolak, yang penting hapus token lokal
    } finally {
      // 1. Bersihkan memori aplikasi
      await _storage.deleteAll();

      if (mounted) {
        // 2. Arahkan kembali ke Halaman Login dan hapus seluruh tumpukan navigasi
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil Saya')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 60,
                backgroundColor: Colors.blue,
                child: Icon(Icons.person, size: 80, color: Colors.white),
              ),
              const SizedBox(height: 24),
              const Text(
                'Akun Aktif',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _role.contains('Petugas')
                      ? Colors.orange[100]
                      : Colors.green[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _role,
                  style: TextStyle(
                    color: _role.contains('Petugas')
                        ? Colors.orange[800]
                        : Colors.green[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  onPressed: _isLoading ? null : _handleLogout,
                  icon: _isLoading
                      ? const CircularProgressIndicator()
                      : const Icon(Icons.logout),
                  label: const Text(
                    'Keluar (Logout)',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
