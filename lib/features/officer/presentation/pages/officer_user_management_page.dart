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
  final ScrollController _scrollController = ScrollController();

  List<dynamic> _cadres = [];
  List<dynamic> _villages = [];

  bool _isLoading = true;
  bool _isFetchingMore = false;
  int _currentPage = 1;
  bool _hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _fetchVillages();
    _fetchCadres(refresh: true);

    // Infinite Scroll
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 50) {
        if (!_isLoading && !_isFetchingMore && _hasMoreData) {
          _fetchMoreCadres();
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ==========================================
  // Ambil Data Desa untuk Dropdown
  // ==========================================
  Future<void> _fetchVillages() async {
    try {
      final response = await _apiClient.dio.get('/villages');
      if (response.statusCode == 200) {
        final rawData = response.data['data'] ?? response.data;
        if (rawData is Iterable) {
          setState(() => _villages = List<dynamic>.from(rawData));
        }
      }
    } catch (e) {
      setState(() => _villages = []);
    }
  }

  // ==========================================
  // READ: Ambil Data Kader (Dengan Paginasi & Filter)
  // ==========================================
  Future<void> _fetchCadres({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
        _hasMoreData = true;
        _cadres.clear();
      });
    }

    try {
      final response = await _apiClient.dio.get(
        '/users',
        // Jika API backend Go Anda mendukung filter by query params,
        // Anda juga bisa menambahkan 'role': 'cadre' di bawah ini:
        queryParameters: {'page': _currentPage, 'limit': 15},
      );
      if (response.statusCode == 200) {
        final rawList = response.data['data'] as List<dynamic>? ?? [];
        final meta = response.data['meta'];

        // --- TAMBAHAN FILTER DI SINI ---
        // Saring data: pastikan role-nya bukan 'officer'
        final filteredData = rawList.where((user) {
          final role = user['role']?.toString().toLowerCase() ?? '';
          return role != 'officer'; // Hanya ambil yang bukan officer
        }).toList();

        setState(() {
          _cadres.addAll(filteredData);
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
          SnackBar(
            content: Text(e.message ?? 'Gagal memuat data kader'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchMoreCadres() async {
    setState(() => _isFetchingMore = true);
    _currentPage++;

    try {
      final response = await _apiClient.dio.get(
        '/auth/users',
        queryParameters: {'page': _currentPage, 'limit': 15},
      );
      if (response.statusCode == 200) {
        final rawList = response.data['data'] as List<dynamic>? ?? [];
        final meta = response.data['meta'];

        // --- TAMBAHAN FILTER DI SINI ---
        // Saring data: pastikan role-nya bukan 'officer'
        final filteredData = rawList.where((user) {
          final role = user['role']?.toString().toLowerCase() ?? '';
          return role != 'officer'; // Hanya ambil yang bukan officer
        }).toList();

        setState(() {
          _cadres.addAll(filteredData);
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
  // BOTTOM SHEET: FORM TAMBAH / EDIT KADER
  // ==========================================
  void _showCadreBottomSheet({Map<String, dynamic>? cadreData}) {
    final bool isEditMode = cadreData != null;

    final formKey = GlobalKey<FormState>();
    final fullNameCtrl = TextEditingController(
      text: isEditMode ? cadreData['full_name'] : '',
    );
    final usernameCtrl = TextEditingController(
      text: isEditMode ? cadreData['username'] : '',
    );
    final passwordCtrl = TextEditingController();

    String? selectedVillageId = isEditMode
        ? cadreData['village_id']?.toString()
        : null;

    if (isEditMode) {
      bool isVillageExist = _villages.any(
        (v) => v['id']?.toString() == selectedVillageId,
      );
      if (!isVillageExist) selectedVillageId = null;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        bool isSheetLoading = false;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> saveCadre() async {
              if (!formKey.currentState!.validate()) return;
              setSheetState(() => isSheetLoading = true);

              try {
                final payload = {
                  "full_name": fullNameCtrl.text.trim(),
                  "username": usernameCtrl.text.trim(),
                  "village_id": selectedVillageId,
                };

                if (!isEditMode) {
                  payload["role"] = "cadre"; // Set default role sebagai cadre
                  payload["password"] = passwordCtrl.text;
                } else if (passwordCtrl.text.isNotEmpty) {
                  payload["password"] = passwordCtrl.text;
                }

                Response response;
                if (isEditMode) {
                  response = await _apiClient.dio.put(
                    '/users/${cadreData['id']}',
                    data: payload,
                  );
                } else {
                  response = await _apiClient.dio.post('/users', data: payload);
                }

                if (response.statusCode == 200 || response.statusCode == 201) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isEditMode
                              ? 'Akun diperbarui!'
                              : 'Akun berhasil dibuat!',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.pop(context);
                    _fetchCadres(refresh: true);
                  }
                }
              } on DioException catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.message ?? 'Gagal menyimpan data'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                setSheetState(() => isSheetLoading = false);
              }
            }

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 12,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    Text(
                      isEditMode ? 'Edit Akun Kader' : 'Tambah Akun Kader',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF143B59),
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (isSheetLoading)
                      const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else
                      Form(
                        key: formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: fullNameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Nama Lengkap',
                                prefixIcon: Icon(Icons.person),
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Wajib diisi' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: usernameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Username',
                                prefixIcon: Icon(Icons.account_circle),
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Wajib diisi' : null,
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Desa Penugasan',
                                prefixIcon: Icon(Icons.location_city),
                                border: OutlineInputBorder(),
                              ),
                              value: selectedVillageId,
                              items: _villages.map<DropdownMenuItem<String>>((
                                v,
                              ) {
                                return DropdownMenuItem<String>(
                                  value: v['id']?.toString(),
                                  child: Text(v['name']?.toString() ?? '-'),
                                );
                              }).toList(),
                              onChanged: (val) =>
                                  setSheetState(() => selectedVillageId = val),
                              validator: (val) =>
                                  val == null ? 'Harap pilih desa' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: passwordCtrl,
                              decoration: InputDecoration(
                                labelText: isEditMode
                                    ? 'Password Baru (Opsional)'
                                    : 'Password Default',
                                prefixIcon: const Icon(Icons.lock),
                                border: const OutlineInputBorder(),
                              ),
                              obscureText: true,
                              validator: (v) {
                                if (!isEditMode && (v == null || v.isEmpty))
                                  return 'Wajib diisi';
                                if (v != null && v.isNotEmpty && v.length < 6)
                                  return 'Minimal 6 karakter';
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                    ),
                                    child: const Text(
                                      'Batal',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: saveCadre,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF143B59),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                    ),
                                    child: const Text(
                                      'Simpan',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // BOTTOM SHEET: KONFIRMASI HAPUS KADER
  // ==========================================
  void _showDeleteBottomSheet(dynamic cadreId, String name) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Hapus Akun Kader?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Apakah Anda yakin ingin menghapus akun "$name"? Tindakan ini tidak dapat dibatalkan.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
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
                      onPressed: () async {
                        Navigator.pop(context);
                        await _deleteCadre(cadreId);
                      },
                      child: const Text(
                        'Hapus',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteCadre(dynamic cadreId) async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiClient.dio.delete('/users/$cadreId');
      if (response.statusCode == 200 || response.statusCode == 204) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Akun Kader berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
          _fetchCadres(refresh: true);
        }
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Gagal menghapus akun'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Manajemen Kader',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF143B59),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchCadres(refresh: true),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _cadres.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.4),
                  const Center(
                    child: Text(
                      'Belum ada data kader terdaftar.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _cadres.length + (_hasMoreData ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _cadres.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final cadre = _cadres[index];
                  final fullName =
                      cadre['full_name']?.toString() ?? 'Tanpa Nama';

                  String villageName = 'Belum Ditugaskan';
                  if (cadre['village'] != null &&
                      cadre['village']['name'] != null) {
                    villageName = cadre['village']['name'];
                  } else if (cadre['village_name'] != null) {
                    villageName = cadre['village_name'];
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
                        backgroundColor: const Color(
                          0xFF143B59,
                        ).withOpacity(0.1),
                        child: const Icon(
                          Icons.person,
                          color: Color(0xFF143B59),
                        ),
                      ),
                      title: Text(
                        fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_city,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Desa $villageName',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.edit_rounded,
                              color: Colors.blue,
                            ),
                            onPressed: () =>
                                _showCadreBottomSheet(cadreData: cadre),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_rounded,
                              color: Colors.red,
                            ),
                            onPressed: () =>
                                _showDeleteBottomSheet(cadre['id'], fullName),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCadreBottomSheet(),
        backgroundColor: const Color(0xFF143B59),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Kader Baru',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
