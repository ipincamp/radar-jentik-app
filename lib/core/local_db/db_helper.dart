import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('radar_jentik.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // Membuat tabel untuk menyimpan antrean laporan yang belum terkirim
    await db.execute('''
      CREATE TABLE pending_reports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        local_image_path TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  // 1. Simpan laporan ke antrean lokal (Store)
  Future<int> insertPendingReport({
    required String localImagePath,
    required String payloadJson,
  }) async {
    final db = await instance.database;
    return await db.insert('pending_reports', {
      'local_image_path': localImagePath,
      'payload_json': payloadJson,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // 2. Ambil semua laporan yang belum terkirim
  Future<List<Map<String, dynamic>>> getPendingReports() async {
    final db = await instance.database;
    return await db.query('pending_reports', orderBy: 'created_at ASC');
  }

  // 3. Hapus laporan jika sudah sukses terkirim ke server (Forward)
  Future<int> deletePendingReport(int id) async {
    final db = await instance.database;
    return await db.delete('pending_reports', where: 'id = ?', whereArgs: [id]);
  }
}
