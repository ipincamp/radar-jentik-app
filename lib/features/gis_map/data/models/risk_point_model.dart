import '../../domain/entities/risk_point.dart';

// Kelas ini mensimulasikan penyimpanan JSON / Database Server
class MockDatabase {
  static List<RiskPoint> data = [
    // Data dummy awal agar peta tidak kosong
    const RiskPoint(latitude: -7.4025, longitude: 109.1670, value: 0.9, level: RiskLevel.danger),
    const RiskPoint(latitude: -7.4040, longitude: 109.1685, value: 0.6, level: RiskLevel.warning),
    const RiskPoint(latitude: -7.4010, longitude: 109.1650, value: 0.2, level: RiskLevel.safe),
  ];
}

/*
class RiskPointModel extends RiskPoint {
  const RiskPointModel({
    required double latitude,
    required double longitude,
    required double value,
    required RiskLevel level,
  }) : super(
         latitude: latitude,
         longitude: longitude,
         value: value,
         level: level,
       );

  // Fungsi untuk generate data dummy di area Cilongok (Lat: -7.4xxx, Long: 109.1xxx)
  static List<RiskPointModel> getDummyList() {
    return [
      // Titik 1: Zona Bahaya (Merah) - Area Pasar Cilongok (misal)
      const RiskPointModel(
        latitude: -7.4025,
        longitude: 109.1670,
        value: 0.9,
        level: RiskLevel.danger,
      ),
      // Titik 2: Zona Waspada (Kuning) - Area Pemukiman A
      const RiskPointModel(
        latitude: -7.4040,
        longitude: 109.1685,
        value: 0.6,
        level: RiskLevel.warning,
      ),
      // Titik 3: Zona Aman (Hijau) - Area Persawahan
      const RiskPointModel(
        latitude: -7.4010,
        longitude: 109.1650,
        value: 0.2,
        level: RiskLevel.safe,
      ),
      // Titik lain
      const RiskPointModel(
        latitude: -7.4055,
        longitude: 109.1660,
        value: 0.85,
        level: RiskLevel.danger,
      ),
    ];
  }
}
*/
