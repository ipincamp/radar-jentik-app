import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import 'cadre_report_detail_page.dart';

class CadreHistoryPage extends StatefulWidget {
  const CadreHistoryPage({super.key});

  @override
  State<CadreHistoryPage> createState() => _CadreHistoryPageState();
}

class _CadreHistoryPageState extends State<CadreHistoryPage> {
  final _apiClient = ApiClient();
  final ScrollController _scrollController = ScrollController();

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _searchQuery = '';

  List<dynamic> _reports = [];
  bool _isLoading = true;
  bool _isFetchingMore = false;

  int _currentPage = 1;
  bool _hasMoreData = true;

  bool _showFilters = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _rtController = TextEditingController();
  final TextEditingController _rwController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _fetchHistory(refresh: true);

    // Dengarkan event scroll untuk memicu pagination (infinite scroll)
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 50) {
        if (!_isLoading && !_isFetchingMore && _hasMoreData) {
          _fetchMoreHistory();
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dateController.dispose();
    _rtController.dispose();
    _rwController.dispose();
    _debounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  // --- FUNGSI PILIH TANGGAL ---
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        // Format YYYY-MM-DD
        _dateController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  // --- FUNGSI AUTO-SEARCH SAAT KETIK NAMA (OPSIONAL) ---
  void _onNameChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      _fetchHistory(refresh: true);
    });
  }

  // Fungsi Fetch Pertama Kali / Refresh
  Future<void> _fetchHistory({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
        _hasMoreData = true;
        _reports.clear();
      });
    }

    try {
      final response = await _apiClient.dio.get(
        '/reports/history',
        queryParameters:
            _buildQueryParameters(), // Gunakan helper pembentuk parameter
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List<dynamic>? ?? [];
        final meta = response.data['meta'];
        setState(() {
          _reports.addAll(data);
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
          SnackBar(content: Text(e.message ?? 'Gagal mengambil riwayat')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  // Fungsi Fetch Halaman Selanjutnya (Scroll ke Bawah)
  Future<void> _fetchMoreHistory() async {
    setState(() => _isFetchingMore = true);
    _currentPage++;
    try {
      final response = await _apiClient.dio.get(
        '/reports/history',
        queryParameters: _buildQueryParameters(),
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List<dynamic>? ?? [];
        final meta = response.data['meta'];
        setState(() {
          _reports.addAll(data);
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

  // --- HELPER UNTUK MENGUMPULKAN PARAMETER PENCARIAN ---
  Map<String, dynamic> _buildQueryParameters() {
    final params = <String, dynamic>{'page': _currentPage, 'limit': 10};
    if (_nameController.text.trim().isNotEmpty) {
      params['search'] = _nameController.text
          .trim(); // atau sesuaikan key API (misal: 'name')
    }
    if (_dateController.text.isNotEmpty) {
      params['date'] = _dateController.text;
    }
    if (_rtController.text.trim().isNotEmpty) {
      params['rt'] = _rtController.text.trim();
    }
    if (_rwController.text.trim().isNotEmpty) {
      params['rw'] = _rwController.text.trim();
    }
    return params;
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = query;
      });
      _fetchHistory(
        refresh: true,
      ); // Panggil ulang data dari awal setiap kali search
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accept':
        return Colors.green;
      case 'reject':
        return Colors.red;
      default:
        return Colors.orange; // pending
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'accept':
        return 'DITERIMA';
      case 'reject':
        return 'DITOLAK';
      default:
        return 'MENUNGGU';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Riwayat Laporan Saya',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF143B59),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // BAGIAN SEARCH & FILTER
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // BARIS 1: Cari Nama & Tombol Filter
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: TextField(
                          controller: _nameController,
                          onChanged: _onNameChanged,
                          decoration: const InputDecoration(
                            hintText: 'Cari nama',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _showFilters = !_showFilters;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          side: const BorderSide(color: Colors.black87),
                        ),
                        child: const Text(
                          'Filter',
                          style: TextStyle(color: Colors.black87, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),

                // BARIS 2: Filter Lanjutan (Tanggal, RT, RW, Cari)
                if (_showFilters) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Field Tanggal
                      Expanded(
                        flex: 4,
                        child: SizedBox(
                          height: 48,
                          child: TextField(
                            controller: _dateController,
                            readOnly: true,
                            onTap: () => _selectDate(context),
                            decoration: InputDecoration(
                              hintText: 'Tanggal',
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              suffixIcon: _dateController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close, size: 16),
                                      onPressed: () {
                                        setState(() {
                                          _dateController.clear();
                                          _selectedDate = null;
                                        });
                                      },
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Field RT
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 48,
                          child: TextField(
                            controller: _rtController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: 'RT',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Field RW
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 48,
                          child: TextField(
                            controller: _rwController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: 'RW',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Tombol Cari (Border Biru)
                      Expanded(
                        flex: 3,
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () {
                              FocusScope.of(
                                context,
                              ).unfocus(); // Tutup keyboard
                              _fetchHistory(
                                refresh: true,
                              ); // Eksekusi pencarian
                            },
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              side: const BorderSide(
                                color: Colors.blue,
                                width: 2,
                              ),
                            ),
                            child: const Text(
                              'Cari',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // AREA LIST RIWAYAT LAPORAN
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _fetchHistory(refresh: true),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _reports.isEmpty
                  ? ListView(
                      // ListView kosong agar RefreshIndicator tetap berfungsi
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.4,
                        ),
                        const Center(
                          child: Text(
                            'Belum ada riwayat laporan.',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _reports.length + (_hasMoreData ? 1 : 0),
                      itemBuilder: (context, index) {
                        // Jika mencapai indeks terakhir dan masih ada data, tampilkan loading kecil
                        if (index == _reports.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final report = _reports[index];
                        final headName =
                            report['family_head_name'] ?? 'Tidak Diketahui';

                        // Mengambil nama desa dari relasi object Village
                        final villageName = report['village'] != null
                            ? report['village']['name']
                            : '-';
                        final rtRw =
                            'RT ${report['rt']}/RW ${report['rw']} - Desa $villageName';

                        final isPositive = report['larvae_status'] == 1;
                        final valStatus =
                            report['validation_status'] ?? 'pending';
                        // final rejectionReason = report['rejection_reason'];

                        // Parsing Format Tanggal API (ISO 8601)
                        String dateStr = '-';
                        if (report['inspected_at'] != null) {
                          try {
                            final parsedDate = DateTime.parse(
                              report['inspected_at'],
                            ).toLocal();
                            dateStr =
                                "${parsedDate.day}/${parsedDate.month}/${parsedDate.year} ${parsedDate.hour}:${parsedDate.minute.toString().padLeft(2, '0')}";
                          } catch (_) {}
                        }

                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CadreReportDetailPage(
                                    reportData: report,
                                    isOffline: false,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: isPositive
                                              ? Colors.red[50]
                                              : Colors.green[50],
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          isPositive
                                              ? Icons.bug_report
                                              : Icons.health_and_safety,
                                          color: isPositive
                                              ? Colors.red
                                              : Colors.green,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              headName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              rtRw,
                                              style: TextStyle(
                                                color: Colors.grey[700],
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              dateStr,
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(valStatus),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          _getStatusLabel(valStatus),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  // TOMBOL EDIT LAPORAN
                                  if (valStatus.toLowerCase() != 'accept') ...[
                                    const SizedBox(height: 12),
                                    const Divider(height: 1),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton.icon(
                                          onPressed: () {
                                            // TODO: Navigasikan ke halaman form untuk Mode Edit
                                            // Saat ini EntryFormPage belum mendukung passing data edit,
                                            // jadi tampilkan SnackBar dulu buat sementara.
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Fitur edit form akan segera tersedia.',
                                                ),
                                                backgroundColor: Colors.blue,
                                              ),
                                            );
                                          },
                                          icon: const Icon(
                                            Icons.edit_rounded,
                                            size: 18,
                                          ),
                                          label: const Text('Edit Laporan'),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.blue,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
