import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import 'officer_validation_detail_page.dart';

class OfficerValidationPage extends StatefulWidget {
  const OfficerValidationPage({super.key});

  @override
  State<OfficerValidationPage> createState() => _OfficerValidationPageState();
}

class _OfficerValidationPageState extends State<OfficerValidationPage> {
  final _apiClient = ApiClient();
  bool _isLoading = true;
  List<dynamic> _pendingReports = [];

  @override
  void initState() {
    super.initState();
    _fetchPendingReports();
  }

  // Mengambil daftar laporan pending dari Golang API
  Future<void> _fetchPendingReports() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiClient.dio.get('/reports/pending');
      if (response.statusCode == 200) {
        setState(() {
          _pendingReports = response.data['data'] ?? [];
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil data: ${e.message}')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Validasi Laporan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPendingReports,
          ),
        ],
      ),
      backgroundColor: Colors.grey[200],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingReports.isEmpty
          ? const Center(
              child: Text(
                'Tidak ada laporan yang menunggu validasi 🎉',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _pendingReports.length,
              itemBuilder: (context, index) {
                final report = _pendingReports[index];

                // Ekstrak data untuk UI
                final headName =
                    report['family_head_name'] ?? 'Tidak Diketahui';
                final rtRw = 'RT ${report['rt']}/RW ${report['rw']}';
                final date =
                    report['inspected_at']?.toString().split('T')[0] ?? '-';

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.orange,
                      child: Icon(Icons.pending_actions, color: Colors.white),
                    ),
                    title: Text(
                      headName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('$rtRw • Tanggal: $date'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      // 1. Navigasi ke halaman detail dengan melempar data laporan (report)
                      // 2. Tunggu hasil kembalian (result) dari halaman detail
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              OfficerValidationDetailPage(reportData: report),
                        ),
                      );

                      // 3. Jika halaman detail mengembalikan 'true' (laporan berhasil diproses),
                      // maka secara otomatis refresh daftar pending ini.
                      if (result == true) {
                        _fetchPendingReports();
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}
