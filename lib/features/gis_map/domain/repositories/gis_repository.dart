import '../entities/risk_point.dart';

abstract class GisRepository {
  // Mengembalikan list titik grid untuk di-render jadi heatmap/marker
  Future<List<RiskPoint>> getZonationData();
}
