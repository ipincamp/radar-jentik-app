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
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiClient.dio.post(
        '/auth/login',
        data: {
          'username': _usernameController.text.trim(),
          'password': _passwordController.text,
        },
      );

      // Pastikan status sukses (200 OK atau 201 Created)
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Backend menggunakan format { "success": true, "message": "...", "data": {...} }
        // Kita harus mengakses data melalui response.data['data']
        final responseData = response.data['data'];

        final token = responseData['token'];
        final role = responseData['role'] ?? 'cadre';

        // Simpan keduanya secara terpisah ke dalam secure storage
        await _storage.write(key: 'jwt_token', value: token);
        await _storage.write(key: 'user_role', value: role);

        if (mounted) {
          // Opsional: Tampilkan pesan sukses dari API
          final successMessage = response.data['message'] ?? 'Login Berhasil';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(successMessage),
              backgroundColor: Colors.green,
            ),
          );

          // Navigasi langsung berdasarkan role tanpa parsing token
          if (role == 'officer') {
            Navigator.pushReplacementNamed(context, '/officer');
          } else {
            Navigator.pushReplacementNamed(context, '/cadre');
          }
        }
      }
    } on DioException catch (e) {
      String errorMessage = 'Terjadi kesalahan sistem.';

      if (e.response != null && e.response?.data != null) {
        // Backend mengembalikan pesan error di dalam properti "message"
        errorMessage = e.response?.data['message'] ?? errorMessage;
      } else if (e.response?.statusCode == 401) {
        errorMessage = 'Username atau Password salah';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sistem gagal memproses data: $e'),
            backgroundColor: Colors.red,
          ),
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
                // const Icon(Icons.map_rounded, size: 80, color: Colors.blue),
                // const SizedBox(height: 20),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
