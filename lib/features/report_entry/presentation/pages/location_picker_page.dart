import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class LocationPickerPage extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const LocationPickerPage({super.key, this.initialLat, this.initialLng});

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  late LatLng _selectedLocation;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    // Jika koordinat sebelumnya sudah ada, gunakan itu.
    // Jika tidak, set default ke area Puskesmas Cilongok II.
    _selectedLocation = LatLng(
      widget.initialLat ?? -7.4025,
      widget.initialLng ?? 109.1670,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pilih Titik Manual',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF143B59),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _selectedLocation,
          initialZoom: 16.0, // Zoom lebih dekat agar lebih presisi
          // Fitur onTap untuk memindahkan marker saat peta disentuh
          onTap: (tapPosition, point) {
            setState(() {
              _selectedLocation = point;
            });
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.radarjentik.app',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: _selectedLocation,
                width: 50,
                height: 50,
                alignment:
                    Alignment.topCenter, // Agar ujung bawah pin pas di titik
                child: const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 50,
                ),
              ),
            ],
          ),
        ],
      ),
      // Tombol untuk mengonfirmasi lokasi pilihan
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Mengembalikan titik koordinat (LatLng) ke halaman sebelumnya
          Navigator.pop(context, _selectedLocation);
        },
        label: const Text("Gunakan Lokasi Ini"),
        icon: const Icon(Icons.check),
        backgroundColor: const Color(0xFFFF6D00), // Warna orange agar menonjol
        foregroundColor: Colors.white,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
