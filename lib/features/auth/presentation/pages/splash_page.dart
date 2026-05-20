import 'dart:convert';
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
    // Memberikan jeda visual 2 detik untuk menampilkan logo aplikasi
    await Future.delayed(const Duration(seconds: 2));

    try {
      // Baca token yang tersimpan di memori perangkat
      String? token = await _storage.read(key: 'jwt_token');

      if (token == null || token.isEmpty) {
        // Jika tidak ada token, arahkan ke Halaman Login biasa
        _navigateTo('/login');
        return;
      }

      // Jika ada token, bongkar isi payload JWT untuk membaca role pengguna
      final parts = token.split('.');
      if (parts.length == 3) {
        final payload = parts[1];
        final String normalized = base64Url.normalize(payload);
        final String decodedString = utf8.decode(base64Url.decode(normalized));
        final Map<String, dynamic> payloadMap = json.decode(decodedString);

        final String role = payloadMap['role'] ?? 'cadre';

        // Arahkan otomatis tanpa melewati login screen lagi
        if (role == 'officer') {
          _navigateTo('/officer');
        } else {
          _navigateTo('/cadre');
        }
      } else {
        // Token korup/rusak, bersihkan memori dan arahkan ke login
        await _storage.delete(key: 'jwt_token');
        _navigateTo('/login');
      }
    } catch (e) {
      // Jika terjadi kesalahan parsing, lempar ke halaman login aman
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
    return const Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_rounded, size: 100, color: Colors.white),
            SizedBox(height: 20),
            Text(
              'Radar Jentik',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Puskesmas II Cilongok',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
