import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

class CadreHistoryPage extends StatefulWidget {
  const CadreHistoryPage({super.key});

  @override
  State<CadreHistoryPage> createState() => _CadreHistoryPageState();
}

class _CadreHistoryPageState extends State<CadreHistoryPage> {
  final _apiClient = ApiClient();
  bool _isLoading = true;
  List<dynamic> _reports = [];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final response = await _apiClient.dio.get('/reports/history');
      if (response.statusCode == 200) {
        setState(() {
          _reports = response.data['data'] ?? [];
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

  // Fungsi helper untuk mewarnai label status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'accept':
        return Colors.green;
      case 'reject':
        return Colors.red;
      default:
        return Colors.orange; // pending
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Laporan Saya'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchHistory();
            },
          ),
        ],
      ),
      backgroundColor: Colors.grey[200],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reports.isEmpty
          ? const Center(child: Text('Belum ada laporan yang dikirim.'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _reports.length,
              itemBuilder: (context, index) {
                final report = _reports[index];

                // Ekstrak data
                final headName =
                    report['family_head_name'] ?? 'Tidak Diketahui';
                final rtRw = 'RT ${report['rt']}/RW ${report['rw']}';
                final isPositive = report['larvae_status'] == 1;
                final valStatus = report['validation_status'] ?? 'pending';
                final date =
                    report['inspected_at']?.toString().split('T')[0] ?? '-';

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: isPositive
                          ? Colors.red[100]
                          : Colors.green[100],
                      child: Icon(
                        isPositive ? Icons.bug_report : Icons.check_circle,
                        color: isPositive ? Colors.red : Colors.green,
                      ),
                    ),
                    title: Text(
                      headName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('$rtRw • Tanggal: $date'),
                        const SizedBox(height: 4),
                        // Label Status Validasi
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(valStatus).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: _getStatusColor(valStatus),
                            ),
                          ),
                          child: Text(
                            valStatus.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              color: _getStatusColor(valStatus),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Navigasi ke Halaman Detail (Opsional)
                    },
                  ),
                );
              },
            ),
    );
  }
}
