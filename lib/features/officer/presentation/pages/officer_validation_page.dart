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

  // STATE UNTUK BULK VALIDATION
  Set<dynamic> _selectedReportIds = {};
  bool _isBulkProcessing = false;

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
        _selectedReportIds.clear(); // Bersihkan pilihan saat refresh
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

  // ==========================================
  // LOGIKA BULK VALIDATION (PILIH BANYAK)
  // ==========================================
  void _toggleSelection(dynamic id) {
    setState(() {
      if (_selectedReportIds.contains(id)) {
        _selectedReportIds.remove(id);
      } else {
        _selectedReportIds.add(id);
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedReportIds.length == _pendingReports.length) {
        // Jika semua yang dilist sudah terpilih, maka batalkan semua
        _selectedReportIds.clear();
      } else {
        // Pilih semua laporan yang ada di memori saat ini
        _selectedReportIds = _pendingReports.map((r) => r['id']).toSet();
      }
    });
  }

  Future<void> _submitBulkValidation(
    String status, {
    String? rejectionReason,
  }) async {
    setState(() => _isBulkProcessing = true);

    try {
      // TODO: BACKEND NANTI
      // Endpoint yang ideal: PUT /reports/bulk-validate
      // Payload: { "report_ids": [1, 2, 3], "status": "accept" / "reject", "rejection_reason": "..." }

      /* CONTOH PANGGILAN API NYATA:
      await _apiClient.dio.put('/reports/bulk-validate', data: {
        'report_ids': _selectedReportIds.toList(),
        'status': status,
        if (status == 'reject') 'rejection_reason': rejectionReason,
      });
      */

      // Simulasi delay request
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_selectedReportIds.length} laporan berhasil divalidasi',
            ),
            backgroundColor: status == 'accept' ? Colors.green : Colors.red,
          ),
        );
        _fetchPendingReports(refresh: true); // Refresh daftar setelah berhasil
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal melakukan validasi massal'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isBulkProcessing = false);
    }
  }

  // ==========================================
  // BOTTOM SHEET KONFIRMASI BULK REJECT
  // ==========================================
  void _showBulkRejectSheet() {
    final TextEditingController reasonController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tolak ${_selectedReportIds.length} Laporan',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Silakan masukkan alasan penolakan untuk laporan-laporan ini:',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Contoh: Foto kurang jelas, data tidak valid...',
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Batal',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        final reason = reasonController.text.trim();
                        if (reason.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Alasan penolakan wajib diisi!'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }
                        Navigator.pop(context);
                        _submitBulkValidation(
                          'reject',
                          rejectionReason: reason,
                        );
                      },
                      child: const Text(
                        'Tolak Semua',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // BOTTOM SHEET KONFIRMASI BULK ACCEPT
  // ==========================================
  void _showBulkAcceptSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Konfirmasi Terima Massal',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Apakah Anda yakin ingin menerima ${_selectedReportIds.length} laporan terpilih ini secara bersamaan?',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Batal',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _submitBulkValidation('accept');
                    },
                    child: const Text(
                      'Ya, Terima Semua',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Mengecek apakah semua item yang di-load sudah terpilih
    bool isAllSelected =
        _pendingReports.isNotEmpty &&
        _selectedReportIds.length == _pendingReports.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Validasi Laporan',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF143B59),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Tombol Pilih Semua (Muncul kalau ada data)
          if (_pendingReports.isNotEmpty)
            Row(
              children: [
                const Text(
                  'Pilih Semua',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
                Checkbox(
                  value: isAllSelected,
                  onChanged: (val) => _toggleSelectAll(),
                  fillColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return Colors.orange; // Warna saat dicentang
                    }
                    return Colors.white; // Warna kotak saat kosong
                  }),
                  checkColor: Colors.white,
                ),
              ],
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _fetchPendingReports(refresh: true),
          ),
        ],
      ),
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => _fetchPendingReports(refresh: true),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _pendingReports.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.4,
                      ),
                      const Center(
                        child: Text(
                          'Tidak ada laporan yang menunggu validasi',
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(
                      top: 12,
                      left: 12,
                      right: 12,
                      bottom: 90,
                    ), // Bottom padding agar tidak tertutup Action Bar
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
                      final reportId = report['id'];
                      final isSelected = _selectedReportIds.contains(reportId);

                      final headName =
                          report['family_head_name'] ?? 'Tidak Diketahui';
                      final villageName = report['village'] != null
                          ? report['village']['name']
                          : '-';
                      final rtRw =
                          'RT ${report['rt']}/RW ${report['rw']} - Desa $villageName';

                      String dateStr = '-';
                      if (report['inspected_at'] != null) {
                        try {
                          final parsed = DateTime.parse(
                            report['inspected_at'],
                          ).toLocal();
                          dateStr =
                              "${parsed.day}/${parsed.month}/${parsed.year}";
                        } catch (_) {}
                      }

                      return Card(
                        elevation: isSelected ? 4 : 1,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected
                                ? Colors.orange
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          // Tap biasa -> Buka Detail
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    OfficerValidationDetailPage(
                                      reportData: report,
                                    ),
                              ),
                            );
                            if (result == true) {
                              _fetchPendingReports(refresh: true);
                            }
                          },
                          // Long Press -> Pilih (Select)
                          onLongPress: () => _toggleSelection(reportId),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                // Checkbox di sebelah kiri
                                Checkbox(
                                  value: isSelected,
                                  onChanged: (val) =>
                                      _toggleSelection(reportId),
                                  activeColor: Colors.orange,
                                ),
                                // Konten Laporan
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
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Tanggal: $dateStr',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                  ),
                                  child: Icon(
                                    Icons.chevron_right,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // ==========================================
          // BOTTOM BULK ACTION BAR
          // ==========================================
          if (_selectedReportIds.isNotEmpty)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      // Indikator Jumlah Terpilih
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${_selectedReportIds.length}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Tombol Tolak
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: _isBulkProcessing
                              ? null
                              : _showBulkRejectSheet,
                          child: const Text('Tolak'),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Tombol Terima
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: _isBulkProcessing
                              ? null
                              : _showBulkAcceptSheet,
                          child: _isBulkProcessing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Terima',
                                  style: TextStyle(color: Colors.white),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
