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
  bool _isLoading = false;
  List<dynamic> _cadres = [];
  List<dynamic> _villages = [];

  @override
  void initState() {
    super.initState();
    _fetchCadres();
    _fetchVillages();
  }

  // ==========================================
  // Mengambil data list desa untuk Dropdown
  // ==========================================
  Future<void> _fetchVillages() async {
    try {
      final response = await _apiClient.dio.get('/villages');
      if (response.statusCode == 200) {
        setState(() {
          // FIX FLUTTER WEB: Handle JSArray API response
          dynamic rawData;
          if (response.data is Map && response.data.containsKey('data')) {
            rawData = response.data['data'];
          } else if (response.data is List) {
            rawData = response.data;
          }

          if (rawData != null && rawData is Iterable) {
            // Memaksa konversi ke Dart List murni
            _villages = List<dynamic>.from(rawData);
          } else {
            _villages = [];
          }
        });
      }
    } catch (e) {
      setState(() => _villages = []);
    }
  }

  // ==========================================
  // 1. READ: Mengambil data list kader
  // ==========================================
  Future<void> _fetchCadres() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiClient.dio.get('/auth/users');
      if (response.statusCode == 200) {
        setState(() {
          // FIX FLUTTER WEB: Handle JSArray API response
          dynamic rawData;
          if (response.data is Map && response.data.containsKey('data')) {
            rawData = response.data['data'];
          } else if (response.data is List) {
            rawData = response.data;
          }

          if (rawData != null && rawData is Iterable) {
            // Memaksa konversi ke Dart List murni
            _cadres = List<dynamic>.from(rawData);
          } else {
            _cadres = [];
          }
        });
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.response?.data['error'] ?? 'Gagal memuat data kader',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ==========================================
  // 2. CREATE: Tampilkan Dialog Tambah Kader
  // ==========================================
  void _showAddCadreDialog() {
    final formKey = GlobalKey<FormState>();
    final fullNameCtrl = TextEditingController();
    final usernameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    String? selectedVillageId;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool isDialogLoading = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> createUser() async {
              if (!formKey.currentState!.validate()) return;

              setDialogState(() => isDialogLoading = true);
              try {
                final payload = {
                  "full_name": fullNameCtrl.text.trim(),
                  "username": usernameCtrl.text.trim(),
                  "password": passwordCtrl.text,
                  "role": "cadre",
                  "village_id": selectedVillageId,
                };

                final response = await _apiClient.dio.post(
                  '/users',
                  data: payload,
                );

                if (response.statusCode == 201 || response.statusCode == 200) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Akun Kader berhasil dibuat!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.pop(context);
                    _fetchCadres();
                  }
                }
              } on DioException catch (e) {
                String errMsg =
                    e.response?.data['error'] ?? 'Gagal membuat akun kader';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(errMsg), backgroundColor: Colors.red),
                );
              } finally {
                setDialogState(() => isDialogLoading = false);
              }
            }

            return _buildFormDialog(
              title: 'Tambah Akun Kader',
              formKey: formKey,
              isDialogLoading: isDialogLoading,
              fullNameCtrl: fullNameCtrl,
              usernameCtrl: usernameCtrl,
              passwordCtrl: passwordCtrl,
              selectedVillageId: selectedVillageId,
              onVillageChanged: (val) =>
                  setDialogState(() => selectedVillageId = val),
              onCancel: () => Navigator.pop(context),
              onSave: createUser,
            );
          },
        );
      },
    );
  }

  // ==========================================
  // 3. UPDATE: Tampilkan Dialog Edit Kader
  // ==========================================
  void _showEditCadreDialog(Map<String, dynamic> cadre) {
    final formKey = GlobalKey<FormState>();
    final fullNameCtrl = TextEditingController(
      text: cadre['full_name']?.toString(),
    );
    final usernameCtrl = TextEditingController(
      text: cadre['username']?.toString(),
    );
    final passwordCtrl = TextEditingController();

    String? selectedVillageId = cadre['village_id']?.toString();

    // Validasi Pencegah Crash Dropdown:
    // Cek apakah ID desa yang terpasang di kader benar-benar ada di daftar _villages
    bool isVillageExist = _villages.any(
      (v) => v['id']?.toString() == selectedVillageId,
    );
    if (!isVillageExist) {
      selectedVillageId = null;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool isDialogLoading = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> updateUser() async {
              if (!formKey.currentState!.validate()) return;

              setDialogState(() => isDialogLoading = true);
              try {
                final payload = {
                  "full_name": fullNameCtrl.text.trim(),
                  "username": usernameCtrl.text.trim(),
                  "village_id": selectedVillageId,
                  if (passwordCtrl.text.isNotEmpty)
                    "password": passwordCtrl.text,
                };

                final response = await _apiClient.dio.put(
                  '/users/${cadre['id']}',
                  data: payload,
                );

                if (response.statusCode == 200) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Data Kader berhasil diperbarui!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.pop(context);
                    _fetchCadres();
                  }
                }
              } on DioException catch (e) {
                String errMsg =
                    e.response?.data['error'] ?? 'Gagal memperbarui akun kader';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(errMsg), backgroundColor: Colors.red),
                );
              } finally {
                setDialogState(() => isDialogLoading = false);
              }
            }

            return _buildFormDialog(
              title: 'Edit Akun Kader',
              formKey: formKey,
              isDialogLoading: isDialogLoading,
              fullNameCtrl: fullNameCtrl,
              usernameCtrl: usernameCtrl,
              passwordCtrl: passwordCtrl,
              selectedVillageId: selectedVillageId,
              onVillageChanged: (val) =>
                  setDialogState(() => selectedVillageId = val),
              isEditMode: true,
              onCancel: () => Navigator.pop(context),
              onSave: updateUser,
            );
          },
        );
      },
    );
  }

  // ==========================================
  // 4. DELETE: Konfirmasi & Hapus Kader
  // ==========================================
  void _confirmDeleteCadre(dynamic cadreId, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Akun'),
        content: Text(
          'Apakah Anda yakin ingin menghapus akun kader "$name"? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              _deleteCadre(cadreId);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
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
          _fetchCadres();
        }
      }
    } on DioException catch (e) {
      if (mounted) {
        String errMsg =
            e.response?.data['error'] ?? 'Gagal menghapus akun kader';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errMsg), backgroundColor: Colors.red),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  // ==========================================
  // Helper: Widget Dialog Form
  // ==========================================
  Widget _buildFormDialog({
    required String title,
    required GlobalKey<FormState> formKey,
    required bool isDialogLoading,
    required TextEditingController fullNameCtrl,
    required TextEditingController usernameCtrl,
    required TextEditingController passwordCtrl,
    required String? selectedVillageId,
    required ValueChanged<String?> onVillageChanged,
    bool isEditMode = false,
    required VoidCallback onCancel,
    required VoidCallback onSave,
  }) {
    // Memastikan Dropdown item list benar-benar List yang aman
    final List<dynamic> safeVillages = _villages;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF143B59),
        ),
      ),
      content: isDialogLoading
          ? const SizedBox(
              height: 150,
              child: Center(child: CircularProgressIndicator()),
            )
          : Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                      // Mapping yang sudah dijamin berupa list dart aman
                      items: safeVillages.map<DropdownMenuItem<String>>((
                        dynamic village,
                      ) {
                        return DropdownMenuItem<String>(
                          value: village['id']?.toString(),
                          child: Text(village['name']?.toString() ?? '-'),
                        );
                      }).toList(),
                      onChanged: onVillageChanged,
                      validator: (value) =>
                          value == null ? 'Harap pilih desa' : null,
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
                  ],
                ),
              ),
            ),
      actions: [
        TextButton(
          onPressed: isDialogLoading ? null : onCancel,
          child: const Text('Batal', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: isDialogLoading ? null : onSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF143B59),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Simpan', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Manajemen Akun Kader',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF143B59),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cadres.isEmpty
          ? const Center(
              child: Text(
                'Belum ada data kader.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _cadres.length,
              itemBuilder: (context, index) {
                final cadre = _cadres[index];
                final fullName = cadre['full_name']?.toString() ?? 'Tanpa Nama';
                final villageName =
                    cadre['village_name']?.toString() ?? 'Belum Ditugaskan';

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
                      backgroundColor: const Color(0xFF143B59).withOpacity(0.1),
                      child: const Icon(Icons.person, color: Color(0xFF143B59)),
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
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Desa: $villageName',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 13,
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
                          onPressed: () => _showEditCadreDialog(cadre),
                          tooltip: 'Edit Kader',
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_rounded,
                            color: Colors.red,
                          ),
                          onPressed: () =>
                              _confirmDeleteCadre(cadre['id'], fullName),
                          tooltip: 'Hapus Kader',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCadreDialog,
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
