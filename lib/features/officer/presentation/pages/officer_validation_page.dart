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
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  bool _isFetchingMore = false;
  List<dynamic> _pendingReports = [];

  int _currentPage = 1;
  bool _hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _fetchPendingReports(refresh: true);

    // Infinite Scroll Listener
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 50) {
        if (!_isLoading && !_isFetchingMore && _hasMoreData) {
          _fetchMorePendingReports();
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchPendingReports({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
        _hasMoreData = true;
        _pendingReports.clear();
      });
    }

    try {
      final response = await _apiClient.dio.get(
        '/reports/pending',
        queryParameters: {'page': _currentPage, 'limit': 10},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List<dynamic>? ?? [];
        final meta = response.data['meta'];

        setState(() {
          _pendingReports.addAll(data);
          _isLoading = false;
          if (meta != null) {
            _hasMoreData = _currentPage < (meta['total_pages'] ?? 1);
          } else {
            _hasMoreData = false;
          }
        });
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Gagal mengambil data')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchMorePendingReports() async {
    setState(() => _isFetchingMore = true);
    _currentPage++;

    try {
      final response = await _apiClient.dio.get(
        '/reports/pending',
        queryParameters: {'page': _currentPage, 'limit': 10},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List<dynamic>? ?? [];
        final meta = response.data['meta'];

        setState(() {
          _pendingReports.addAll(data);
          if (meta != null) {
            _hasMoreData = _currentPage < (meta['total_pages'] ?? 1);
          } else {
            _hasMoreData = false;
          }
        });
      }
    } catch (e) {
      _currentPage--;
    } finally {
      setState(() => _isFetchingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Validasi Laporan',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF143B59),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _fetchPendingReports(refresh: true),
          ),
        ],
      ),
      backgroundColor: Colors.grey[100],
      body: RefreshIndicator(
        onRefresh: () => _fetchPendingReports(refresh: true),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _pendingReports.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.4),
                  const Center(
                    child: Text(
                      'Tidak ada laporan yang menunggu validasi 🎉',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _pendingReports.length + (_hasMoreData ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _pendingReports.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final report = _pendingReports[index];
                  final headName =
                      report['family_head_name'] ?? 'Tidak Diketahui';

                  final villageName = report['village'] != null
                      ? report['village']['name']
                      : '-';
                  final rtRw =
                      'RT ${report['rt']}/RW ${report['rw']} - Desa $villageName';

                  // Format Tanggal
                  String dateStr = '-';
                  if (report['inspected_at'] != null) {
                    try {
                      final parsed = DateTime.parse(
                        report['inspected_at'],
                      ).toLocal();
                      dateStr = "${parsed.day}/${parsed.month}/${parsed.year}";
                    } catch (_) {}
                  }

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
                        backgroundColor: Colors.orange[100],
                        child: const Icon(
                          Icons.pending_actions,
                          color: Colors.orange,
                        ),
                      ),
                      title: Text(
                        headName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text('$rtRw\nTanggal: $dateStr'),
                      ),
                      isThreeLine: true,
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                      ),
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                OfficerValidationDetailPage(reportData: report),
                          ),
                        );

                        if (result == true) {
                          _fetchPendingReports(refresh: true);
                        }
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
