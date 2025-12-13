import '../entities/risk_point.dart';
import '../repositories/gis_repository.dart';

class GetZonationMap {
  final GisRepository repository;

  GetZonationMap(this.repository);

  // Fungsi eksekusi utama
  Future<List<RiskPoint>> execute() async {
    // TODO Tambahkan logic validasi atau filter data
    return await repository.getZonationData();
  }
}
