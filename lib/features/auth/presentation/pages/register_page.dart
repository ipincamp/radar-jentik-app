import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  final _apiClient = ApiClient();

  bool _obscurePassword = true;
  bool _isLoading = false;

  // State untuk data desa
  List<dynamic> _villages = [];
  String? _selectedVillageId;
  bool _isLoadingVillages = true;

  @override
  void initState() {
    super.initState();
    _fetchVillages(); // Ambil data desa dari backend saat halaman dibuka
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Fungsi mengambil daftar desa untuk Dropdown
  Future<void> _fetchVillages() async {
    try {
      final response = await _apiClient.dio.get('/villages');
      if (response.statusCode == 200) {
        setState(() {
          _villages = response.data['data'];
          _isLoadingVillages = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingVillages = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Gagal mengambil data desa. Pastikan server menyala.",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Fungsi submit pendaftaran kader
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedVillageId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap pilih desa penugasan Anda'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiClient.dio.post(
        '/auth/register',
        data: {
          'full_name': _nameController.text.trim(),
          'username': _usernameController.text.trim(),
          'password': _passwordController.text,
          'role':
              'cadre', // Default pendaftaran mandiri dari aplikasi sebagai Kader
          'village_id': _selectedVillageId,
        },
      );

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Registrasi akun kader berhasil! Silakan Sign In."),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context); // Kembali ke halaman Login
        }
      }
    } on DioException catch (e) {
      String errorMessage = "Gagal mendaftarkan akun.";
      if (e.response != null && e.response?.data != null) {
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
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                // Icon Aplikasi pengganti Placeholder
                Container(
                  width: 90,
                  height: 90,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.app_registration,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  "Sign Up",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Daftar akun baru sebagai Kader Kesehatan",
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 32),

                // Input Nama Lengkap
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "Nama Lengkap",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Nama lengkap wajib diisi'
                      : null,
                ),
                const SizedBox(height: 16),

                // Input Username
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: "Username",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.account_circle_outlined),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Username wajib diisi'
                      : null,
                ),
                const SizedBox(height: 16),

                // Input Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: "Password",
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    fillColor: Colors.white,
                    filled: true,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Password wajib diisi';
                    if (value.length < 6) return 'Password minimal 6 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Dropdown Pilihan Desa Wilayah Kerja
                _isLoadingVillages
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: CircularProgressIndicator(),
                      )
                    : DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Desa Penugasan / Wilayah Tugas',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_city_outlined),
                          fillColor: Colors.white,
                          filled: true,
                        ),
                        value: _selectedVillageId,
                        items: _villages.map<DropdownMenuItem<String>>((
                          dynamic village,
                        ) {
                          return DropdownMenuItem<String>(
                            value: village['id'].toString(),
                            child: Text(village['name'].toString()),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedVillageId = newValue;
                          });
                        },
                        validator: (value) => value == null
                            ? 'Harap pilih desa penugasan Anda'
                            : null,
                      ),
                const SizedBox(height: 32),

                // Tombol Sign Up
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(
                        0xFF38D44A,
                      ), // Tetap menggunakan warna hijau terang
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _isLoading ? null : _handleRegister,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Sign Up",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Navigasi Kembali ke Sign In
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Sudah memiliki akun? Sign In"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
