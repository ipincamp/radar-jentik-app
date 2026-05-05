class LarvaeReport {
  final double latitude;
  final double longitude;
  final bool isPositive; // true = Ada Jentik, false = Bebas Jentik
  final String notes; // Catatan tambahan (opsional)
  final String? imagePath; // Path ke gambar (opsional)
  final DateTime timestamp;

  LarvaeReport({
    required this.latitude,
    required this.longitude,
    required this.isPositive,
    this.notes = '',
    this.imagePath,
    required this.timestamp,
  });
}
