import '../entities/larvae_report.dart';

abstract class ReportRepository {
  // Kontrak fungsi untuk mengirim laporan
  Future<void> submitReport(LarvaeReport report);
}
