import '../../domain/entities/risk_point.dart';
import '../../domain/repositories/gis_repository.dart';
import '../models/risk_point_model.dart';

class GisRepositoryImpl implements GisRepository {
  @override
  Future<List<RiskPoint>> getZonationData() async {
    // Simulasi delay jaringan (misal: 2 detik)
    await Future.delayed(const Duration(seconds: 2));

    // Mengembalikan data dummy statis
    return RiskPointModel.getDummyList();
  }
}
