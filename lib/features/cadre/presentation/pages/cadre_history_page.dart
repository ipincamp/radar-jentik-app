import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import 'cadre_report_detail_page.dart';
import 'edit_form_page.dart';

class CadreHistoryPage extends StatefulWidget {
  const CadreHistoryPage({super.key});

  @override
  State<CadreHistoryPage> createState() => _CadreHistoryPageState();
}

class _CadreHistoryPageState extends State<CadreHistoryPage> {
  final _apiClient = ApiClient();
  final ScrollController _scrollController = ScrollController();

  Timer? _debounce;
  List<dynamic> _reports = [];
  bool _isLoading = true;
  bool _isFetchingMore = false;
  int _currentPage = 1;
  bool _hasMoreData = true;
  bool _showFilters = false;

  // STATE UNTUK FILTER
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _rtController = TextEditingController();
  final TextEditingController _rwController = TextEditingController();
  DateTime? _selectedDate;

  // STATE UNTUK DROPDOWN DESA
  List<dynamic> _villages = [];
  String? _selectedVillageId;
  bool _isLoadingVillages = true;

  @override
  void initState() {
    super.initState();
    _fetchVillages(); // Ambil master data desa saat halaman dibuka
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

  // FUNGSI AMBIL DATA DESA UNTUK DROPDOWN
  Future<void> _fetchVillages() async {
    try {
      final response = await _apiClient.dio.get('/villages');
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _villages = response.data['data'] ?? [];
            _isLoadingVillages = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingVillages = false);
    }
  }

  // FUNGSI PILIH TANGGAL
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
      _fetchHistory(refresh: true); // Otomatis cari saat tanggal diubah
    }
  }

  // FUNGSI AUTO-SEARCH SAAT KETIK NAMA
  void _onNameChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      _fetchHistory(refresh: true);
    });
  }

  // HELPER UNTUK MENGUMPULKAN PARAMETER PENCARIAN
  Map<String, dynamic> _buildQueryParameters() {
    final params = <String, dynamic>{'page': _currentPage, 'limit': 10};

    if (_nameController.text.trim().isNotEmpty) {
      params['search'] = _nameController.text.trim();
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
    if (_selectedVillageId != null && _selectedVillageId!.isNotEmpty) {
      params['village_id'] = _selectedVillageId;
    }

    return params;
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
        queryParameters: _buildQueryParameters(), // Bawa filter ke API
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List<dynamic>? ?? [];
        final meta = response.data['meta'];

        if (mounted) {
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
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Gagal mengambil riwayat'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
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

        if (mounted) {
          setState(() {
            _reports.addAll(data);
            if (meta != null) {
              _hasMoreData = _currentPage < (meta['total_pages'] ?? 1);
            } else {
              _hasMoreData = false;
            }
          });
        }
      }
    } catch (e) {
      _currentPage--;
    } finally {
      if (mounted) setState(() => _isFetchingMore = false);
    }
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
                // BARIS 1: Cari Nama KK & Tombol Filter
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: TextField(
                          controller: _nameController,
                          onChanged: _onNameChanged,
                          decoration: const InputDecoration(
                            hintText: 'Cari nama KK...',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                            prefixIcon: Icon(Icons.search, size: 20),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _showFilters = !_showFilters;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          side: BorderSide(
                            color: _showFilters
                                ? Colors.blue
                                : Colors.grey.shade600,
                          ),
                        ),
                        icon: Icon(
                          Icons.filter_list,
                          size: 18,
                          color: _showFilters ? Colors.blue : Colors.black87,
                        ),
                        label: Text(
                          'Filter',
                          style: TextStyle(
                            color: _showFilters ? Colors.blue : Colors.black87,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // BARIS 2: Filter Lanjutan (Desa, Tanggal, RT, RW)
                if (_showFilters) ...[
                  const SizedBox(height: 12),

                  // Dropdown Desa
                  SizedBox(
                    height: 48,
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        hintText: _isLoadingVillages
                            ? 'Memuat desa...'
                            : 'Semua Desa',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                      ),
                      value: _selectedVillageId,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text(
                            'Semua Desa',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        ..._villages.map<DropdownMenuItem<String>>((v) {
                          return DropdownMenuItem<String>(
                            value: v['id'].toString(),
                            child: Text(v['name'].toString()),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        setState(() => _selectedVillageId = val);
                        _fetchHistory(refresh: true); // Eksekusi filter
                      },
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Tanggal, RT, RW, dan Tombol Cari
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
                                        _fetchHistory(refresh: true);
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
                      // Tombol Cari
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
                              backgroundColor: Colors.blue[50],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              side: const BorderSide(
                                color: Colors.blue,
                                width: 1.5,
                              ),
                            ),
                            child: const Text(
                              'Terapkan',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 13,
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
                          height: MediaQuery.of(context).size.height * 0.3,
                        ),
                        const Center(
                          child: Text(
                            'Tidak ada laporan yang sesuai filter.',
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
                        if (index == _reports.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final report = _reports[index];
                        final headName =
                            report['family_head_name'] ?? 'Tidak Diketahui';

                        final villageName = report['village'] != null
                            ? report['village']['name']
                            : '-';
                        final rtRw =
                            'RT ${report['rt']}/RW ${report['rw']} - Desa $villageName';
                        final isPositive = report['larvae_status'] == 1;
                        final valStatus =
                            report['validation_status'] ?? 'pending';

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

                                  // TOMBOL EDIT LAPORAN JIKA BELUM DI "ACCEPT"
                                  if (valStatus.toLowerCase() != 'accept') ...[
                                    const SizedBox(height: 12),
                                    const Divider(height: 1),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton.icon(
                                          onPressed: () async {
                                            // Navigasi ke halaman EditFormPage dengan membawa data 'report'
                                            final result = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => EditFormPage(
                                                  reportData: report,
                                                ),
                                              ),
                                            );

                                            // Jika edit berhasil dan kembali ke halaman ini, refresh list-nya
                                            if (result == true) {
                                              _fetchHistory(refresh: true);
                                            }
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
