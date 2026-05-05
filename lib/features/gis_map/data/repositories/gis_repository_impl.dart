import '../../domain/entities/risk_point.dart';
import '../../domain/repositories/gis_repository.dart';
import '../models/risk_point_model.dart';

class GisRepositoryImpl implements GisRepository {
  @override
  Future<List<RiskPoint>> getZonationData() async {
    // Simulasi loading pengambilan data (dipercepat jadi 0.5 detik)
    await Future.delayed(const Duration(milliseconds: 500));

    // Mengembalikan data dari simulasi JSON/Database
    return MockDatabase.mapData;
  }
}
