import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/network/api_client.dart';

class ContainerInput {
  String type = 'Bak Mandi';
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
  bool _isFetchingLocation = false; // Status loading khusus untuk GPS

  final _rtController = TextEditingController();
  final _rwController = TextEditingController();
  final _headNameController = TextEditingController();

  // Kosongkan nilai awal agar user harus memencet tombol deteksi
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  bool _isLarvaePositive = false;

  List<dynamic> _villages = [];
  String? _selectedVillageId;
  bool _isLoadingVillages = true;

  final List<ContainerInput> _containers = [ContainerInput()];

  @override
  void initState() {
    super.initState();
    _fetchVillages();
  }

  @override
  void dispose() {
    _rtController.dispose();
    _rwController.dispose();
    _headNameController.dispose();
    _latController.dispose();
    _lngController.dispose();
    for (var c in _containers) {
      c.inspectedCtrl.dispose();
      c.positiveCtrl.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchVillages() async {
    try {
      final response = await _apiClient.dio.get('/villages');
      if (response.statusCode == 200) {
        setState(() {
          _villages = response.data['data'];
          _isLoadingVillages = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingVillages = false);
    }
  }

  // Mengambil Lokasi GPS Akurat
  Future<void> _getCurrentLocation() async {
    setState(() => _isFetchingLocation = true);

    try {
      bool serviceEnabled;
      LocationPermission permission;

      // 1. Cek apakah layanan lokasi (GPS) aktif di HP
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception(
          'Layanan GPS/Lokasi tidak aktif. Harap nyalakan GPS Anda.',
        );
      }

      // 2. Cek status izin aplikasi
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // Minta izin ke user
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

      // 3. Tarik kordinat saat ini dengan akurasi tinggi
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 4. Masukkan ke dalam Controller (Form Teks)
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
      if (mounted) {
        setState(() => _isFetchingLocation = false);
      }
    }
  }

  void _addContainer() => setState(() => _containers.add(ContainerInput()));
  void _removeContainer(int index) =>
      setState(() => _containers.removeAt(index));

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedVillageId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap pilih desa lokasi survei')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      List<Map<String, dynamic>> containerList = _containers.map((c) {
        return {
          "container_type": c.type,
          "inspected_count": int.tryParse(c.inspectedCtrl.text) ?? 0,
          "positive_count": int.tryParse(c.positiveCtrl.text) ?? 0,
        };
      }).toList();

      final payload = {
        "village_id": _selectedVillageId,
        "rt": _rtController.text.trim(),
        "rw": _rwController.text.trim(),
        "family_head_name": _headNameController.text.trim(),
        "latitude": double.tryParse(_latController.text) ?? 0.0,
        "longitude": double.tryParse(_lngController.text) ?? 0.0,
        "larvae_status": _isLarvaePositive,
        "containers": containerList,
      };

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
    } on DioException catch (e) {
      String errMsg = e.response?.data['error'] ?? 'Gagal mengirim laporan';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errMsg), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Form Laporan Baru')),
      body: _isLoadingVillages
          ? const Center(child: CircularProgressIndicator())
          : Form(
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
                    onChanged: (val) =>
                        setState(() => _selectedVillageId = val),
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

                  // TOMBOL DETEKSI LOKASI
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[100],
                        foregroundColor: Colors.blue[900],
                      ),
                      onPressed: _isFetchingLocation
                          ? null
                          : _getCurrentLocation,
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

                  // INPUT LATITUDE LONGITUDE (KINI READ-ONLY)
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _latController,
                          readOnly:
                              true, // Mencegah user mengetik manual yang rawan typo
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
                          readOnly:
                              true, // Mencegah user mengetik manual yang rawan typo
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
                    'Status Jentik Keseluruhan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SwitchListTile(
                    title: Text(
                      _isLarvaePositive
                          ? 'Positif (Ditemukan Jentik)'
                          : 'Negatif (Bebas Jentik)',
                    ),
                    subtitle: const Text(
                      'Geser jika ditemukan jentik di rumah ini',
                    ),
                    activeColor: Colors.red,
                    value: _isLarvaePositive,
                    onChanged: (bool value) =>
                        setState(() => _isLarvaePositive = value),
                  ),

                  const Divider(height: 40, thickness: 2),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Rincian Wadah',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _addContainer,
                        icon: const Icon(Icons.add),
                        label: const Text('Tambah Wadah'),
                      ),
                    ],
                  ),

                  ...List.generate(_containers.length, (index) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _containers[index].type,
                                    decoration: const InputDecoration(
                                      labelText: 'Jenis Wadah',
                                    ),
                                    items:
                                        [
                                              'Bak Mandi',
                                              'Tempayan',
                                              'Ember',
                                              'Pot Bunga',
                                              'Lainnya',
                                            ]
                                            .map(
                                              (e) => DropdownMenuItem(
                                                value: e,
                                                child: Text(e),
                                              ),
                                            )
                                            .toList(),
                                    onChanged: (val) => setState(
                                      () => _containers[index].type = val!,
                                    ),
                                  ),
                                ),
                                if (_containers.length > 1)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _removeContainer(index),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller:
                                        _containers[index].inspectedCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Jml Diperiksa',
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextFormField(
                                    controller: _containers[index].positiveCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Jml Positif',
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
                  }),

                  const SizedBox(height: 30),

                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                      onPressed: _isLoading ? null : _submitReport,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Kirim Laporan',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
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
