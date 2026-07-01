import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/local_db/db_helper.dart';

// --- KELAS BANTUAN UNTUK WADAH STANDAR ---
class ContainerInput {
  final String id;
  final String name;
  final TextEditingController inspectedCtrl = TextEditingController(text: '0');
  final TextEditingController positiveCtrl = TextEditingController(text: '0');

  ContainerInput({required this.id, required this.name});
}

// --- KELAS BANTUAN UNTUK WADAH LAIN-LAIN (DINAMIS) ---
class OtherContainerInput {
  final TextEditingController customNameCtrl = TextEditingController();
  final TextEditingController inspectedCtrl = TextEditingController(text: '0');
  final TextEditingController positiveCtrl = TextEditingController(text: '0');
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
  List<ContainerInput> _standardContainers = [];
  String? _otherContainerId; // Menyimpan ID khusus untuk wadah "Lain-lain"
  List<OtherContainerInput> _otherContainers =
      []; // List dinamis untuk input user
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
    for (var c in _standardContainers) {
      c.inspectedCtrl.dispose();
      c.positiveCtrl.dispose();
    }
    for (var oc in _otherContainers) {
      oc.customNameCtrl.dispose();
      oc.inspectedCtrl.dispose();
      oc.positiveCtrl.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchVillages() async {
    try {
      final response = await _apiClient.dio.get('/villages');
      if (response.statusCode == 200) {
        setState(() {
          _villages = response.data['data'] ?? [];
          _isLoadingVillages = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingVillages = false);
    }
  }

  Future<void> _fetchContainerTypes() async {
    try {
      final response = await _apiClient.dio.get('/container-types');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];

        List<ContainerInput> standard = [];
        String? otherId;

        // PISAHKAN Wadah Standar dengan "Lain-lain"
        for (var item in data) {
          final id = item['id'].toString();
          final name = item['name'].toString();

          // Deteksi apakah ini "Lain-lain" berdasarkan namanya
          if (name.toLowerCase().contains('lain')) {
            otherId = id;
          } else {
            standard.add(ContainerInput(id: id, name: name));
          }
        }

        setState(() {
          _standardContainers = standard;
          _otherContainerId = otherId;
          _isLoadingContainers = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingContainers = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat daftar wadah jentik')),
        );
      }
    }
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
      if (!serviceEnabled)
        throw Exception(
          'Layanan GPS/Lokasi tidak aktif. Harap nyalakan GPS Anda.',
        );

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
      for (var c in _standardContainers) {
        containerList.add({
          "container_type_id": c.id,
          "inspected_count": int.tryParse(c.inspectedCtrl.text) ?? 0,
          "positive_count": int.tryParse(c.positiveCtrl.text) ?? 0,
        });
      }
      if (_otherContainerId != null) {
        for (var oc in _otherContainers) {
          String customName = oc.customNameCtrl.text.trim();
          if (customName.isNotEmpty) {
            containerList.add({
              "container_type_id": _otherContainerId,
              "custom_name": customName,
              "inspected_count": int.tryParse(oc.inspectedCtrl.text) ?? 0,
              "positive_count": int.tryParse(oc.positiveCtrl.text) ?? 0,
            });
          }
        }
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

      // 3. CEK KONEKSI INTERNET
      var connectivityResult = await (Connectivity().checkConnectivity());
      bool hasInternet = connectivityResult != ConnectivityResult.none;

      if (hasInternet) {
        // --- JIKA ONLINE: LANGSUNG UPLOAD & KIRIM KE BACKEND ---
        String? uploadedPhotoUrl = await _uploadPhoto();
        if (uploadedPhotoUrl == null)
          throw Exception("Gagal mendapatkan link foto dari server.");

        payload["photo_url"] = uploadedPhotoUrl; // Masukkan URL foto

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
        // --- JIKA OFFLINE: SIMPAN KE SQFLITE LOKAL (STORE) ---
        String payloadJson = jsonEncode(payload); // Ubah Map ke String JSON

        await DatabaseHelper.instance.insertPendingReport(
          localImagePath: _imageFile!.path, // Simpan lokasi fisik foto di HP
          payloadJson: payloadJson, // Simpan data teks JSON
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
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errMsg), backgroundColor: Colors.red),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
          padding: const EdgeInsets.all(16.0),
          children: [
            const Text(
              'Data Lokasi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Desa',
                border: OutlineInputBorder(),
              ),
              value: _selectedVillageId,
              items: _villages.map<DropdownMenuItem<String>>((v) {
                return DropdownMenuItem<String>(
                  value: v['id'].toString(),
                  child: Text(v['name'].toString()),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedVillageId = val),
              validator: (val) => val == null ? 'Pilih desa' : null,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _rtController,
                    decoration: const InputDecoration(
                      labelText: 'RT',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Wajib' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _rwController,
                    decoration: const InputDecoration(
                      labelText: 'RW',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Wajib' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _headNameController,
              decoration: const InputDecoration(
                labelText: 'Nama Kepala Keluarga',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.isEmpty ? 'Wajib' : null,
            ),
            const SizedBox(height: 20),
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
            const SizedBox(height: 10),
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
                    ),
                    validator: (v) =>
                        v!.isEmpty ? 'Gunakan tombol deteksi' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _lngController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Longitude',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Color(0xFFF3F4F6),
                    ),
                    validator: (v) =>
                        v!.isEmpty ? 'Gunakan tombol deteksi' : null,
                  ),
                ),
              ],
            ),
            const Divider(height: 40, thickness: 2),
            const Text(
              "Foto Bukti Inspeksi",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 10),
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
                            ? Image.network(_imageFile!.path, fit: BoxFit.cover)
                            : Image.file(
                                File(_imageFile!.path),
                                fit: BoxFit.cover,
                              ),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, color: Colors.blue, size: 50),
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
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
              ),
            ),

            const Divider(height: 40, thickness: 2),
            const Padding(
              padding: EdgeInsets.only(bottom: 12.0),
              child: Text(
                'Rincian Wadah',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            // --- LIST WADAH STANDAR ---
            ..._standardContainers.map((container) {
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        container.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: container.inspectedCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Jml Diperiksa',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: container.positiveCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Jml Positif',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),

            // --- LIST WADAH LAIN-LAIN (DINAMIS) ---
            if (_otherContainerId != null) ...[
              const SizedBox(height: 20),
              const Text(
                'Wadah Lain-lain (Opsional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),

              ..._otherContainers.asMap().entries.map((entry) {
                int index = entry.key;
                OtherContainerInput oc = entry.value;

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  color: Colors.orange[50],
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: oc.customNameCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Nama Wadah (Misal: Galon Bekas)',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _otherContainers.removeAt(index);
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: oc.inspectedCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Jml Diperiksa',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: oc.positiveCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Jml Positif',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),

              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _otherContainers.add(OtherContainerInput());
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text("Tambah Wadah Lainnya"),
              ),
            ],

            const SizedBox(height: 30),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                onPressed: _isLoading ? null : _submitReport,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Kirim Laporan',
                        style: TextStyle(fontSize: 16, color: Colors.white),
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
