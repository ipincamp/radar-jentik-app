import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/entities/larvae_report.dart';
import '../../data/repositories/report_repository_impl.dart';

class EntryFormPage extends StatefulWidget {
  const EntryFormPage({super.key});

  @override
  State<EntryFormPage> createState() => _EntryFormPageState();
}

class _EntryFormPageState extends State<EntryFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _repository = ReportRepositoryImpl();

  // Instance ImagePicker
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;

  // State Form
  bool _isLoadingLocation = true;
  bool _isSubmitting = false;
  String? _locationMessage;
  double? _latitude;
  double? _longitude;

  // Default status: Negatif (Bebas Jentik)
  bool _isPositive = false;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); // Ambil GPS otomatis saat buka halaman
  }

  // Fungsi mengambil GPS
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      // 1. Cek apakah Layanan Lokasi di Sistem Operasi aktif
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationMessage =
              "Layanan Lokasi OS mati (Cek setting Windows/Mac).";
          _isLoadingLocation = false;
        });
        return;
      }

      // 2. Cek Izin Browser
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationMessage = "Izin lokasi ditolak oleh browser.";
            _isLoadingLocation = false;
          });
          return;
        }
      }

      // 3. Cek jika izin ditolak secara permanen
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationMessage = "Izin lokasi ditolak permanen oleh OS/Browser.";
          _isLoadingLocation = false;
        });
        return;
      }

      // 4. Jika izin lolos, ambil koordinat
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationMessage = "${position.latitude}, ${position.longitude}";
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() {
        // Ini akan menangkap error jika browser gagal menentukan lokasi
        _locationMessage = "Gagal mengambil GPS: $e";
        _isLoadingLocation = false;
      });
    }
  }

  // Fungsi mengambil gambar (opsional, untuk MVP bisa diabaikan dulu)
  Future<void> _takePicture() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70, // Kompresi gambar agar pengiriman lebih cepat
      );
      if (photo != null) {
        setState(() {
          _imageFile = photo;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal membuka kamera: $e")));
    }
  }

  // Fungsi Submit
  Future<void> _submitForm() async {
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tunggu lokasi GPS terdeteksi!")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final report = LarvaeReport(
      latitude: _latitude!,
      longitude: _longitude!,
      isPositive: _isPositive,
      notes: _notesController.text,
      imagePath: _imageFile?.path,
      timestamp: DateTime.now(),
    );

    await _repository.submitReport(report);

    if (mounted) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Laporan Berhasil Dikirim!")),
      );
      Navigator.pop(context); // Kembali ke Peta setelah sukses
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Lapor Jentik")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // 1. Bagian Lokasi (Otomatis)
              Card(
                color: Colors.grey[100],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.teal,
                        size: 40,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Lokasi Temuan",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _isLoadingLocation
                          ? const CircularProgressIndicator()
                          : Text(
                              _locationMessage ?? "Lokasi belum didapat",
                              style: const TextStyle(fontSize: 16),
                            ),
                      if (!_isLoadingLocation && _latitude == null)
                        TextButton(
                          onPressed: _getCurrentLocation,
                          child: const Text("Coba Ambil Lokasi Lagi"),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 2. Status Jentik (Switch/Radio)
              const Text(
                "Status Keberadaan Jentik:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SwitchListTile(
                title: Text(
                  _isPositive
                      ? "POSITIF (Ada Jentik)"
                      : "NEGATIF (Bebas Jentik)",
                  style: TextStyle(
                    color: _isPositive ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text("Geser jika ditemukan jentik"),
                value: _isPositive,
                activeColor: Colors.red,
                onChanged: (val) {
                  setState(() => _isPositive = val);
                },
              ),
              const Divider(),

              // 3. Catatan Tambahan
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: "Catatan Tambahan (Opsional)",
                  border: OutlineInputBorder(),
                  hintText: "Contoh: Di bak mandi luar rumah",
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // 4. BUKTI FOTO (Opsional)
              const Text(
                "Bukti Foto Observasi:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _takePicture,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    border: Border.all(
                      color: Colors.grey.shade400,
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: kIsWeb
                              // Jika berjalan di Web, gunakan Image.network
                              ? Image.network(
                                  _imageFile!.path,
                                  fit: BoxFit.cover,
                                )
                              // Jika berjalan di Android/iOS, gunakan Image.file
                              : Image.file(
                                  File(_imageFile!.path),
                                  fit: BoxFit.cover,
                                ),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt,
                              size: 48,
                              color: Colors.teal,
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Buka Kamera",
                              style: TextStyle(
                                color: Colors.teal,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              // Tombol hapus foto jika foto sudah diambil
              if (_imageFile != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _imageFile = null),
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text(
                      "Hapus Foto",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              const SizedBox(height: 32),

              // 5. Tombol Simpan
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _isSubmitting ? null : _submitForm,
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("KIRIM LAPORAN"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
