import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/local_db/db_helper.dart';

class AddedContainer {
  final String id;
  final String baseName;
  final bool isCustom;
  final TextEditingController customNameCtrl;
  int inspectedCount;
  int positiveCount;

  AddedContainer({
    required this.id,
    required this.baseName,
    this.isCustom = false,
  }) : customNameCtrl = TextEditingController(),
       inspectedCount = 0,
       positiveCount = 0;

  void dispose() {
    customNameCtrl.dispose();
  }
}

class EntryFormPage extends StatefulWidget {
  const EntryFormPage({super.key});

  @override
  State<EntryFormPage> createState() => _EntryFormPageState();
}

class _EntryFormPageState extends State<EntryFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _apiClient = ApiClient();

  bool _isLoading = false;
  bool _isFetchingLocation = false;

  final _rtController = TextEditingController();
  final _rwController = TextEditingController();
  final _headNameController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  List<dynamic> _villages = [];
  String? _selectedVillageId;
  bool _isLoadingVillages = true;

  // Variabel penampung Wadah
  List<dynamic> _containerTypes = [];
  String? _selectedContainerTypeId;
  final List<AddedContainer> _addedContainers = [];
  bool _isLoadingContainers = true;

  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;

  @override
  void initState() {
    super.initState();
    _fetchVillages();
    _fetchContainerTypes();
  }

  @override
  void dispose() {
    _rtController.dispose();
    _rwController.dispose();
    _headNameController.dispose();
    _latController.dispose();
    _lngController.dispose();
    for (var c in _addedContainers) {
      c.dispose();
    }
    super.dispose();
  }

  // ==========================================
  // FETCH DATA DESA (SMART CACHE)
  // ==========================================
  Future<void> _fetchVillages() async {
    try {
      final response = await _apiClient.dio.get('/villages');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        await DatabaseHelper.instance.saveVillages(data);
        setState(() {
          _villages = data;
          _isLoadingVillages = false;
        });
        return;
      }
    } catch (e) {
      debugPrint('Offline mode: Memuat Desa dari SQLite...');
    }

    final localData = await DatabaseHelper.instance.getVillages();
    setState(() {
      _villages = localData;
      _isLoadingVillages = false;
    });
  }

  // ==========================================
  // FETCH JENIS WADAH (SMART CACHE)
  // ==========================================
  Future<void> _fetchContainerTypes() async {
    List<dynamic> data = [];
    try {
      final response = await _apiClient.dio.get('/container-types');
      if (response.statusCode == 200) {
        data = response.data['data'] ?? [];
        await DatabaseHelper.instance.saveContainerTypes(data);
      }
    } catch (e) {
      debugPrint('Offline mode: Memuat Wadah dari SQLite...');
      data = await DatabaseHelper.instance.getContainerTypes();
    }

    setState(() {
      _containerTypes = data;
      _isLoadingContainers = false;
    });
  }

  Future<void> _takePicture() async {
    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );
    if (photo != null) setState(() => _imageFile = photo);
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception(
          'Layanan GPS/Lokasi tidak aktif. Harap nyalakan GPS Anda.',
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Izin akses lokasi ditolak oleh pengguna.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Izin lokasi ditolak permanen. Ubah di Pengaturan HP Anda.',
        );
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latController.text = position.latitude.toString();
        _lngController.text = position.longitude.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lokasi berhasil ditemukan!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  Future<String?> _uploadPhoto() async {
    if (_imageFile == null) return null;
    try {
      String fileName = _imageFile!.path.split('/').last;
      FormData formData = FormData.fromMap({
        "photo": await MultipartFile.fromFile(
          _imageFile!.path,
          filename: fileName,
        ),
      });

      final response = await _apiClient.dio.post('/uploads', data: formData);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['data']['photo_url'];
      }
      return null;
    } catch (e) {
      throw Exception("Gagal mengunggah foto bukti.");
    }
  }

  // --- FUNGSI UTAMA PENGIRIMAN DATA ---
  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedVillageId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap pilih desa lokasi survei')),
      );
      return;
    }

    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wajib mengunggah foto bukti')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Kumpulkan Data Wadah
      List<Map<String, dynamic>> containerList = [];
      for (var c in _addedContainers) {
        // Lewati jika tidak ada nilai sama sekali
        if (c.inspectedCount == 0 && c.positiveCount == 0) continue;

        final itemData = {
          "container_type_id": c.id,
          "inspected_count": c.inspectedCount,
          "positive_count": c.positiveCount,
        };

        if (c.isCustom) {
          itemData["custom_name"] = c.customNameCtrl.text.trim();
        }
        containerList.add(itemData);
      }

      // 2. Susun Payload (Tanpa photo_url dulu)
      final payload = {
        "village_id": _selectedVillageId,
        "rt": _rtController.text.trim(),
        "rw": _rwController.text.trim(),
        "family_head_name": _headNameController.text.trim(),
        "latitude": double.tryParse(_latController.text) ?? 0.0,
        "longitude": double.tryParse(_lngController.text) ?? 0.0,
        "inspected_at": DateTime.now().toIso8601String(),
        "containers": containerList,
      };

      // 3. Cek Koneksi Internet
      final List<ConnectivityResult> connectivityResult = await (Connectivity()
          .checkConnectivity());
      bool isOffline = connectivityResult.contains(ConnectivityResult.none);
      bool hasInternet = !isOffline;

      if (hasInternet) {
        String? uploadedPhotoUrl = await _uploadPhoto();
        if (uploadedPhotoUrl == null) {
          throw Exception("Gagal mendapatkan link foto dari server.");
        }

        payload["photo_url"] = uploadedPhotoUrl;
        final response = await _apiClient.dio.post('/reports', data: payload);

        if (response.statusCode == 201) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Laporan berhasil dikirim!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          }
        }
      } else {
        String payloadJson = jsonEncode(payload);
        await DatabaseHelper.instance.insertPendingReport(
          localImagePath: _imageFile!.path,
          payloadJson: payloadJson,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Anda Sedang Offline! Laporan disimpan di Antrean Sinkronisasi.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
          Navigator.pop(context);
        }
      }
    } on DioException catch (e) {
      String errMsg = e.message ?? 'Gagal mengirim laporan';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errMsg), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- WIDGET HELPER UNTUK COUNTER WADAH ---
  Widget _buildCounter({
    required int value,
    required String label,
    required Color color,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: onDecrement,
              child: Icon(Icons.remove_circle_outline, color: color, size: 28),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 24,
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: onIncrement,
              child: Icon(Icons.add_circle_outline, color: color, size: 28),
            ),
          ],
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.black87),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingVillages || _isLoadingContainers) {
      return Scaffold(
        appBar: AppBar(title: const Text('Form Laporan Baru')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Memuat data formulir..."),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Form Laporan Baru')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(12.0),
          children: [
            // =====================================
            // SECTION 1: DATA LOKASI
            // =====================================
            ExpansionTile(
              initiallyExpanded: true,
              title: const Text(
                'Data Lokasi',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              leading: const Icon(Icons.location_on, color: Colors.blue),
              childrenPadding: const EdgeInsets.all(12),
              children: [
                // Baris 1: Desa, RT, RW digabung
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Desa',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        value: _selectedVillageId,
                        items: _villages.map<DropdownMenuItem<String>>((v) {
                          return DropdownMenuItem<String>(
                            value: v['id'].toString(),
                            child: Text(v['name'].toString()),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setState(() => _selectedVillageId = val),
                        validator: (val) => val == null ? 'Wajib' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _rtController,
                        decoration: const InputDecoration(
                          labelText: 'RT',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'X' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _rwController,
                        decoration: const InputDecoration(
                          labelText: 'RW',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'X' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _headNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Kepala Keluarga',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  validator: (v) => v!.isEmpty ? 'Wajib' : null,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[100],
                      foregroundColor: Colors.blue[900],
                    ),
                    onPressed: _isFetchingLocation ? null : _getCurrentLocation,
                    icon: _isFetchingLocation
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location),
                    label: const Text(
                      'Deteksi Koordinat Saat Ini',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Latitude',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Color(0xFFF3F4F6),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        validator: (v) =>
                            v!.isEmpty ? 'Gunakan tombol deteksi' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _lngController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Longitude',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Color(0xFFF3F4F6),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        validator: (v) =>
                            v!.isEmpty ? 'Gunakan tombol deteksi' : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 20, thickness: 1),

            // =====================================
            // SECTION 2: FOTO BUKTI
            // =====================================
            ExpansionTile(
              initiallyExpanded: true,
              title: const Text(
                'Foto Bukti Inspeksi',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              childrenPadding: const EdgeInsets.all(12),
              children: [
                InkWell(
                  onTap: _takePicture,
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      border: Border.all(color: Colors.blue, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _imageFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: kIsWeb
                                ? Image.network(
                                    _imageFile!.path,
                                    fit: BoxFit.cover,
                                  )
                                : Image.file(
                                    File(_imageFile!.path),
                                    fit: BoxFit.cover,
                                  ),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo,
                                color: Colors.blue,
                                size: 50,
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Ketuk untuk mengambil foto",
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Wajib melampirkan 1 foto",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20, thickness: 1),

            // =====================================
            // SECTION 3: RINCIAN WADAH
            // =====================================
            ExpansionTile(
              initiallyExpanded: true,
              title: const Text(
                'Rincian Wadah',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              leading: const Icon(Icons.water_drop, color: Colors.blue),
              childrenPadding: const EdgeInsets.all(12),
              children: [
                // Dropdown untuk menambah wadah
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Pilih Wadah',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        value: _selectedContainerTypeId,
                        items: _containerTypes.map<DropdownMenuItem<String>>((
                          c,
                        ) {
                          return DropdownMenuItem<String>(
                            value: c['id'].toString(),
                            child: Text(c['name'].toString()),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setState(() => _selectedContainerTypeId = val),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 16,
                        ),
                      ),
                      onPressed: () {
                        if (_selectedContainerTypeId == null) return;
                        final selected = _containerTypes.firstWhere(
                          (c) => c['id'].toString() == _selectedContainerTypeId,
                        );

                        final isOther = selected['name']
                            .toString()
                            .toLowerCase()
                            .contains('lain');

                        setState(() {
                          _addedContainers.add(
                            AddedContainer(
                              id: selected['id'].toString(),
                              baseName: selected['name'].toString(),
                              isCustom: isOther,
                            ),
                          );
                          // Reset dropdown setelah tambah
                          _selectedContainerTypeId = null;
                        });
                      },
                      child: const Text(
                        'Tambah',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Daftar Wadah yang Ditambahkan (1 Baris per Wadah)
                if (_addedContainers.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'Belum ada wadah ditambahkan. Pilih dari daftar di atas lalu tekan Tambah.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                ..._addedContainers.map((container) {
                  return Card(
                    elevation: 1,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.blue.shade100),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          // Kolom Nama Wadah
                          Expanded(
                            flex: 3,
                            child: container.isCustom
                                ? TextFormField(
                                    controller: container.customNameCtrl,
                                    decoration: const InputDecoration(
                                      hintText: 'Nama wadah...',
                                      isDense: true,
                                      border: UnderlineInputBorder(),
                                    ),
                                    style: const TextStyle(fontSize: 14),
                                  )
                                : Text(
                                    container.baseName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 8),
                          // Counter Jumlah Diperiksa (Hitam)
                          _buildCounter(
                            value: container.inspectedCount,
                            label: 'jumlah',
                            color: Colors.black,
                            onDecrement: () {
                              if (container.inspectedCount > 0) {
                                setState(() {
                                  container.inspectedCount--;
                                  // Pastikan positif tidak melebihi yang diperiksa
                                  if (container.positiveCount >
                                      container.inspectedCount) {
                                    container.positiveCount =
                                        container.inspectedCount;
                                  }
                                });
                              }
                            },
                            onIncrement: () {
                              setState(() => container.inspectedCount++);
                            },
                          ),
                          const SizedBox(width: 12),
                          // Counter Positif Jentik (Merah)
                          _buildCounter(
                            value: container.positiveCount,
                            label: 'positif',
                            color: const Color(0xFFA11D20), // Merah gelap
                            onDecrement: () {
                              if (container.positiveCount > 0) {
                                setState(() => container.positiveCount--);
                              }
                            },
                            onIncrement: () {
                              // Cegah positif melebihi total yang diperiksa
                              if (container.positiveCount <
                                  container.inspectedCount) {
                                setState(() => container.positiveCount++);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Jumlah positif tidak boleh melebihi jumlah diperiksa!',
                                    ),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              }
                            },
                          ),
                          // Tombol Hapus
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(
                              Icons.close,
                              color: Colors.grey,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _addedContainers.remove(container);
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),

            const SizedBox(height: 30),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isLoading ? null : _submitReport,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Kirim Laporan',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
