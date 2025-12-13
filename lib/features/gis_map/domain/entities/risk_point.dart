// Enum untuk klasifikasi Zonasi
enum RiskLevel { safe, warning, danger }

class RiskPoint {
  final double latitude; // Koordinat x
  final double longitude; // Koordinat y
  final double value; // Nilai Estimasi z'
  final RiskLevel level; // Hasil klasifikasi warna

  const RiskPoint({
    required this.latitude,
    required this.longitude,
    required this.value,
    required this.level,
  });

  // Logic bisnis ringan

  // Getter untuk konversi RiskLevel ke Hex Color string
  String get colorHex {
    switch (level) {
      case RiskLevel.danger:
        return "#FF0000"; // Merah
      case RiskLevel.warning:
        return "#FFFF00"; // Kuning
      case RiskLevel.safe:
        return "#00FF00"; // Hijau
    }
  }
}
