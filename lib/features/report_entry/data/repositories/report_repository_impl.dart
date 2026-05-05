import 'dart:developer';
import '../../domain/entities/larvae_report.dart';
import '../../domain/repositories/report_repository.dart';

class ReportRepositoryImpl implements ReportRepository {
  @override
  Future<void> submitReport(LarvaeReport report) async {
    // 1. Simulasi delay jaringan (misal: kirim ke server butuh 1.5 detik)
    await Future.delayed(const Duration(milliseconds: 1500));

    // 2. Simulasi "Kirim Data" (Cetak ke Console sebagai bukti)
    // TODO Di aplikasi asli, panggil GraphQL Mutation
    log('--- MENGIRIM LAPORAN KE SERVER ---');
    log('Koordinat: ${report.latitude}, ${report.longitude}');
    log('Status: ${report.isPositive ? "POSITIF (Bahaya)" : "NEGATIF (Aman)"}');
    log('Catatan: ${report.notes}');
    log('Foto: ${report.imagePath ?? "Tidak ada foto dilampirkan"}');
    log('Waktu: ${report.timestamp}');
    log('----------------------------------');

    // Anggap selalu sukses untuk MVP ini
    return;
  }
}
