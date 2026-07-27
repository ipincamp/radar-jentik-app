import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../../../../core/network/api_client.dart';

// Class penampung wadah dibuat private (pakai underscore)
// agar tidak bentrok dengan class di entry_form_page.dart
class _AddedContainer {
  final String id;
  final String baseName;
  final bool isCustom;
  final TextEditingController customNameCtrl;
  int inspectedCount;
  int positiveCount;

  _AddedContainer({
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

class EditFormPage extends StatefulWidget {
  final Map<String, dynamic>
  reportData; // Menerima data laporan yang akan diedit

  const EditFormPage({super.key, required this.reportData});

  @override
  State<EditFormPage> createState() => _EditFormPageState();
}

class _EditFormPageState extends State<EditFormPage> {
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isFetchingLocation = false;

  // Controllers
  final _rtController = TextEditingController();
  final _rwController = TextEditingController();
  final _headNameController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _dateTimeController = TextEditingController();
  DateTime _selectedDateTime = DateTime.now();

  // Variabel Data Master
  List<dynamic> _villages = [];
  String? _selectedVillageId;
  bool _isLoadingVillages = true;

  List<dynamic> _containerTypes = [];
  String? _selectedContainerTypeId;
  final List<_AddedContainer> _addedContainers = [];
  bool _isLoadingContainers = true;

  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;

  // Tambahkan variabel ini di bawah deklarasi variabel lainnya
  final _apiClient = ApiClient();

  @override
  void initState() {
    super.initState();
    // 1. Isi form dengan data laporan bawaan (termasuk UUID desa)
    _populateInitialData();
    // 2. Fetch API Desa yang asli & validasi UUID-nya
    _fetchMasterData();
  }

  @override
  void dispose() {
    _rtController.dispose();
    _rwController.dispose();
    _headNameController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _dateTimeController.dispose();
    for (var c in _addedContainers) {
      c.dispose();
    }
    super.dispose();
  }

  // Mengisi kolom dengan data bawaan (reportData)
  void _populateInitialData() {
    _headNameController.text = widget.reportData['family_head_name'] ?? '';
    _rtController.text = widget.reportData['rt']?.toString() ?? '';
    _rwController.text = widget.reportData['rw']?.toString() ?? '';
    _latController.text = widget.reportData['latitude']?.toString() ?? '';
    _lngController.text = widget.reportData['longitude']?.toString() ?? '';

    _selectedVillageId = widget.reportData['village_id']?.toString();

    if (widget.reportData['inspected_at'] != null) {
      try {
        _selectedDateTime = DateTime.parse(
          widget.reportData['inspected_at'],
        ).toLocal();
      } catch (_) {}
    }
    _dateTimeController.text = _formatDateTime(_selectedDateTime);

    // ==============================================================
    // Memuat daftar wadah yang sudah ada sebelumnya
    // ==============================================================
    final details =
        widget.reportData['container_details'] as List<dynamic>? ?? [];

    for (var detail in details) {
      final containerTypeId = detail['container_type_id']?.toString() ?? '';

      // Ambil nama wadah bawaan dari relasi container_type (Preload database)
      String baseName = 'Wadah Standar';
      if (detail['container_type'] != null) {
        baseName = detail['container_type']['name']?.toString() ?? baseName;
      }

      // Cek apakah ini "Wadah Lainnya" yang butuh input teks manual
      final isCustom = baseName.toLowerCase().contains('lain');
      final customName = detail['custom_name']?.toString() ?? '';

      // Inisiasi objek wadah untuk ditampilkan di UI
      final existingContainer = _AddedContainer(
        id: containerTypeId,
        baseName: baseName,
        isCustom: isCustom,
      );

      // Jika custom, isi controller teksnya
      if (isCustom) {
        existingContainer.customNameCtrl.text = customName;
      }

      // Isi angka jumlah diperiksa dan positif
      existingContainer.inspectedCount =
          int.tryParse(detail['inspected_count']?.toString() ?? '0') ?? 0;
      existingContainer.positiveCount =
          int.tryParse(detail['positive_count']?.toString() ?? '0') ?? 0;

      // Masukkan ke dalam list state form
      _addedContainers.add(existingContainer);
    }
  }

  String _formatDateTime(DateTime dt) {
    return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  Future<void> _pickDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          _dateTimeController.text = _formatDateTime(_selectedDateTime);
        });
      }
    }
  }

  Future<void> _fetchMasterData() async {
    try {
      // Ambil Data Desa Asli dari API
      final responseVillages = await _apiClient.dio.get('/villages');
      if (responseVillages.statusCode == 200) {
        _villages = responseVillages.data['data'] ?? [];
      }

      // Ambil Data Wadah Asli dari API
      final responseContainers = await _apiClient.dio.get('/container-types');
      if (responseContainers.statusCode == 200) {
        _containerTypes = responseContainers.data['data'] ?? [];
      }

      if (mounted) {
        setState(() {
          // VALIDASI AMAN: Pastikan _selectedVillageId (UUID laporan) ada di daftar _villages asli
          if (_selectedVillageId != null) {
            bool exists = _villages.any(
              (v) => v['id'].toString() == _selectedVillageId,
            );
            if (!exists) {
              _selectedVillageId =
                  null; // Reset jika tidak ketemu agar Dropdown tidak crash
            }
          }

          _isLoadingVillages = false;
          _isLoadingContainers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingVillages = false;
          _isLoadingContainers = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memuat data master desa atau wadah'),
          ),
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fungsi deteksi lokasi (Menyusul)')),
    );
  }

  Future<void> _submitEditReport() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedVillageId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap pilih desa lokasi survei')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // TODO: URUSAN BACKEND NANTI
    await Future.delayed(const Duration(seconds: 1)); // Simulasi loading API

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perubahan Laporan Berhasil Disimpan!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(
        context,
        true,
      ); // Kembali ke halaman sebelumnya dan bawa status true (refresh)
    }
  }

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
              child: Icon(Icons.remove_circle_outline, color: color, size: 36),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 32,
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            InkWell(
              onTap: onIncrement,
              child: Icon(Icons.add_circle_outline, color: color, size: 36),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.black87),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingVillages || _isLoadingContainers) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Edit Laporan',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF143B59),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Laporan',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF143B59),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(12.0),
          children: [
            ExpansionTile(
              initiallyExpanded: true,
              title: const Text(
                'Data Lokasi',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              leading: const Icon(Icons.location_on, color: Colors.blue),
              childrenPadding: const EdgeInsets.all(12),
              children: [
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
                const SizedBox(height: 12),
                TextFormField(
                  controller: _dateTimeController,
                  readOnly: true,
                  onTap: _pickDateTime,
                  decoration: const InputDecoration(
                    labelText: 'Waktu Survei / Inspeksi',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(
                      Icons.calendar_month_rounded,
                      color: Colors.blue,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 45,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[100],
                            foregroundColor: Colors.blue[900],
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          onPressed: _isFetchingLocation
                              ? null
                              : _getCurrentLocation,
                          icon: const Icon(Icons.my_location),
                          label: const Text(
                            'Otomatis',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 45,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[100],
                            foregroundColor: Colors.orange[900],
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Buka Peta (Menyusul)'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.map),
                          label: const Text(
                            'Pilih di Peta',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
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
                        validator: (v) => v!.isEmpty ? 'Wajib' : null,
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
                        validator: (v) => v!.isEmpty ? 'Wajib' : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 20, thickness: 1),

            ExpansionTile(
              initiallyExpanded: true,
              title: const Text(
                'Foto Bukti Inspeksi (Opsional)',
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
                                "Ketuk untuk mengambil foto baru",
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20, thickness: 1),

            ExpansionTile(
              initiallyExpanded: true,
              title: const Text(
                'Rincian Wadah',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              leading: const Icon(Icons.water_drop, color: Colors.blue),
              childrenPadding: const EdgeInsets.all(12),
              children: [
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
                            _AddedContainer(
                              id: selected['id'].toString(),
                              baseName: selected['name'].toString(),
                              isCustom: isOther,
                            ),
                          );
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
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: container.isCustom
                                    ? TextFormField(
                                        controller: container.customNameCtrl,
                                        decoration: const InputDecoration(
                                          hintText:
                                              'Nama wadah (mis. Ember Bekas)',
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                        ),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : Text(
                                        container.baseName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _addedContainers.remove(container);
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildCounter(
                                value: container.inspectedCount,
                                label: 'jumlah',
                                color: Colors.black,
                                onDecrement: () {
                                  if (container.inspectedCount > 0) {
                                    setState(() {
                                      container.inspectedCount--;
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
                              _buildCounter(
                                value: container.positiveCount,
                                label: 'positif',
                                color: const Color(0xFFA11D20),
                                onDecrement: () {
                                  if (container.positiveCount > 0) {
                                    setState(() => container.positiveCount--);
                                  }
                                },
                                onIncrement: () {
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
                            ],
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
                  backgroundColor: const Color(0xFF143B59),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isLoading ? null : _submitEditReport,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Simpan Perubahan',
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
