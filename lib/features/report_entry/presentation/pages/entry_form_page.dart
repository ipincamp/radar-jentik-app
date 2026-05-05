import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/entities/larvae_report.dart';
import '../../../gis_map/data/models/risk_point_model.dart';

class EntryFormPage extends StatefulWidget {
  const EntryFormPage({super.key});

  @override
  State<EntryFormPage> createState() => _EntryFormPageState();
}

class _EntryFormPageState extends State<EntryFormPage> {
  final _headOfFamilyController = TextEditingController();
  final _addressController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;

  double? _latitude;
  double? _longitude;
  bool _isPositive = true; // Default "Ya"

  // Waktu pembuatan laporan dikunci saat form dibuka
  final DateTime _creationTime = DateTime.now();

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _latitude = position.latitude;
      _longitude = position.longitude;
    });
  }

  Future<void> _takePicture() async {
    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );
    if (photo != null) setState(() => _imageFile = photo);
  }

  void _saveLocalReport() {
    if (_headOfFamilyController.text.isEmpty || _latitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lengkapi Nama KK dan GPS!")),
      );
      return;
    }

    // Simpan ke Luring (Belum Sync)
    final report = LarvaeReport(
      headOfFamily: _headOfFamilyController.text,
      address: _addressController.text,
      latitude: _latitude!,
      longitude: _longitude!,
      isPositive: _isPositive,
      imagePath: _imageFile?.path,
      timestamp: _creationTime, // Waktu diambil dari saat form diinisiasi
      isSynced: false,
    );

    MockDatabase.localReports.add(report);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Laporan Disimpan Luring!")));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Laporan Jentik Baru",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF143B59),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Field Nama KK
            Container(
              color: const Color(0xFFD4EBD9),
              child: TextField(
                controller: _headOfFamilyController,
                decoration: const InputDecoration(
                  hintText: "Nama Kepala Keluarga",
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Field Alamat
            Container(
              color: const Color(0xFFD4EBD9),
              child: TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  hintText: "Alamat",
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Ambil GPS
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF143B59),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _getCurrentLocation,
                    child: Text(
                      _latitude == null ? "AMBIL GPS" : "GPS TEREKAM",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  color: const Color(0xFFD4EBD9),
                  child: const Icon(Icons.map, color: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Status Jentik
            const Text(
              "Status Jentik",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Ada Jentik?"),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text("Ya"),
                        selected: _isPositive,
                        selectedColor: const Color(0xFF43A047),
                        onSelected: (val) => setState(() => _isPositive = true),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text("Tidak"),
                        selected: !_isPositive,
                        selectedColor: Colors.grey[300],
                        onSelected: (val) =>
                            setState(() => _isPositive = false),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Unggah Foto Jentik
            const Text(
              "Unggah Foto Jentik",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _takePicture,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4EBD9),
                  border: Border.all(
                    color: Colors.teal,
                    width: 2,
                  ), // Simulasi Dotted dengan border tegas
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
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
                          Icon(
                            Icons.camera_alt,
                            color: Color(0xFF143B59),
                            size: 40,
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Ambil Foto",
                            style: TextStyle(
                              color: Color(0xFF143B59),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 32),

            // Tombol Simpan Laporan
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF143B59),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onPressed: _saveLocalReport,
                child: const Text(
                  "SIMPAN LAPORAN",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
