import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    await Future.delayed(const Duration(seconds: 2));

    try {
      String? token = await _storage.read(key: 'jwt_token');
      String? role = await _storage.read(key: 'user_role');

      // Jika salah satu komponen sesi kosong, wajib masuk ke halaman login
      if (token == null || token.isEmpty || role == null || role.isEmpty) {
        _navigateTo('/login');
        return;
      }

      // Alokasikan navigasi halaman utama berdasarkan role
      if (role == 'officer') {
        _navigateTo('/officer');
      } else {
        _navigateTo('/cadre');
      }
    } catch (e) {
      _navigateTo('/login');
    }
  }

  void _navigateTo(String routeName) {
    if (mounted) {
      Navigator.pushReplacementNamed(context, routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF11234B),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Gambar logo
            Image.asset(
              'assets/logo.png',
              width: 150,
              height: 150,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Tampilan cadangan jika gambar gagal dimuat
                return const Icon(
                  Icons.map_rounded,
                  size: 100,
                  color: Colors.white,
                );
              },
            ),
            const SizedBox(height: 24),
            // Teks Judul
            const Text(
              'Radar Jentik',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            // Teks Subjudul
            Text(
              'Puskesmas Cilongok II',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.7),
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
