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
