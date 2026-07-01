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

    return await openDatabase(
      path,
      version: 2, // VERSI 2: Penambahan tabel Master Data
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  // --- PEMBUATAN TABEL SAAT INSTALL BARU ---
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE pending_reports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        local_image_path TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE TABLE villages (id TEXT PRIMARY KEY, name TEXT NOT NULL)',
    );
    await db.execute(
      'CREATE TABLE container_types (id TEXT PRIMARY KEY, name TEXT NOT NULL)',
    );
  }

  // --- UPGRADE TABEL JIKA SUDAH INSTALL VERSI 1 ---
  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'CREATE TABLE villages (id TEXT PRIMARY KEY, name TEXT NOT NULL)',
      );
      await db.execute(
        'CREATE TABLE container_types (id TEXT PRIMARY KEY, name TEXT NOT NULL)',
      );
    }
  }

  // ========================================================
  // 1. MANAJEMEN ANTREAN LAPORAN OFFLINE
  // ========================================================
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

  Future<List<Map<String, dynamic>>> getPendingReports() async {
    final db = await instance.database;
    return await db.query('pending_reports', orderBy: 'created_at ASC');
  }

  Future<int> deletePendingReport(int id) async {
    final db = await instance.database;
    return await db.delete('pending_reports', where: 'id = ?', whereArgs: [id]);
  }

  // ========================================================
  // 2. MANAJEMEN MASTER DATA (CACHE OFFLINE DESA)
  // ========================================================
  Future<void> saveVillages(List<dynamic> villages) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.delete('villages'); // Hapus data lama
      for (var v in villages) {
        await txn.insert('villages', {
          'id': v['id'].toString(),
          'name': v['name'].toString(),
        });
      }
    });
  }

  Future<List<Map<String, dynamic>>> getVillages() async {
    final db = await instance.database;
    return await db.query('villages');
  }

  // ========================================================
  // 3. MANAJEMEN MASTER DATA (CACHE OFFLINE JENIS WADAH)
  // ========================================================
  Future<void> saveContainerTypes(List<dynamic> containers) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.delete('container_types'); // Hapus data lama
      for (var c in containers) {
        await txn.insert('container_types', {
          'id': c['id'].toString(),
          'name': c['name'].toString(),
        });
      }
    });
  }

  Future<List<Map<String, dynamic>>> getContainerTypes() async {
    final db = await instance.database;
    return await db.query('container_types');
  }
}
