import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/network/api_client.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  final _apiClient = ApiClient();
  final _storage = const FlutterSecureStorage();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Validasi form sebelum memanggil API
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Tembak API Login
      final response = await _apiClient.dio.post(
        '/auth/login',
        data: {
          'username': _usernameController.text.trim(),
          'password': _passwordController.text,
        },
      );

      if (response.statusCode == 200) {
        // 2. Ambil token dari response
        final token = response.data['token'];

        // 3. Simpan token ke Secure Storage
        await _storage.write(key: 'jwt_token', value: token);

        // 4. Decode JWT Token secara manual untuk mengambil 'role'
        // Token JWT terdiri dari 3 bagian yang dipisah dengan titik (.)
        final parts = token.split('.');
        if (parts.length == 3) {
          final payload = parts[1];
          // Normalisasi base64
          final String normalized = base64Url.normalize(payload);
          // Decode payload JSON
          final String resp = utf8.decode(base64Url.decode(normalized));
          final Map<String, dynamic> payloadMap = json.decode(resp);

          final String role = payloadMap['role'] ?? 'cadre';

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Login Berhasil'),
                backgroundColor: Colors.green,
              ),
            );

            // 5. Arahkan ke halaman yang tepat berdasarkan role
            if (role == 'officer') {
              Navigator.pushReplacementNamed(context, '/officer');
            } else {
              Navigator.pushReplacementNamed(context, '/cadre');
            }
          }
        }
      }
    } on DioException catch (e) {
      String errorMessage = 'Terjadi kesalahan sistem.';
      if (e.response?.statusCode == 401) {
        errorMessage = 'Username atau Password salah';
      } else if (e.response != null && e.response?.data != null) {
        errorMessage = e.response?.data['error'] ?? errorMessage;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          // Agar tidak error overflow saat keyboard muncul
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.map_rounded, size: 80, color: Colors.blue),
                const SizedBox(height: 20),
                const Text(
                  'Radar Jentik',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),

                // Form Username
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Username tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Form Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Tombol Login
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Login', style: TextStyle(fontSize: 16)),
                  ),
                ),

                const SizedBox(height: 16),

                // Tombol Navigasi ke Register
                TextButton(
                  onPressed: () {
                    // Pastikan rute '/register' sudah didaftarkan di main.dart Anda
                    Navigator.pushNamed(context, '/register');
                  },
                  child: const Text('Belum punya akun? Daftar sebagai Kader'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
