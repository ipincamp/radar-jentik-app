import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

class OfficerUserManagementPage extends StatefulWidget {
  const OfficerUserManagementPage({super.key});

  @override
  State<OfficerUserManagementPage> createState() =>
      _OfficerUserManagementPageState();
}

class _OfficerUserManagementPageState extends State<OfficerUserManagementPage> {
  final _apiClient = ApiClient();
  bool _isLoading = true;
  List<dynamic> _users = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiClient.dio.get('/auth/users');
      if (response.statusCode == 200) {
        setState(() {
          // Filter hanya yang role-nya 'cadre' jika backend mengembalikan semua user
          final allUsers = response.data['data'] as List<dynamic>? ?? [];
          _users = allUsers.where((u) => u['role'] == 'cadre').toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat data kader')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Kader'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchUsers),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
          ? const Center(child: Text('Belum ada kader terdaftar.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.green,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(
                      user['full_name'] ?? 'Kader',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Username: ${user['username']}'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                );
              },
            ),
    );
  }
}
