class LarvaeReport {
  final String headOfFamily;
  final String address;
  final double latitude;
  final double longitude;
  final bool isPositive; // true = Ada Jentik, false = Bebas Jentik
  final String notes; // Catatan tambahan (opsional)
  final String? imagePath; // Path ke gambar (opsional)
  final DateTime timestamp; // Waktu laporan dibuat (bukan dikirim)
  bool isSynced; // Status apakah sudah dikirim ke server/peta

  LarvaeReport({
    required this.headOfFamily,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.isPositive,
    this.notes = '',
    this.imagePath,
    required this.timestamp,
    this.isSynced = false, // Default: Belum sinkron (Luring)
  });
}
