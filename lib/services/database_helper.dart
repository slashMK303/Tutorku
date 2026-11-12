import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tutorku/models/service_model.dart';
import 'package:tutorku/models/order_model.dart';
import 'package:tutorku/models/revision_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tutorku.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // Initialize FFI for SQLite on Windows
    if (!kIsWeb && Platform.isWindows) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await _getDatabaseDirectoryPath();
    final directory = Directory(dbPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE orders ADD COLUMN cash_received REAL;');
      } catch (e) {
        // Ignore if column already exists
      }
    }
  }

  Future<String> _getDatabaseDirectoryPath() async {
    if (!kIsWeb && Platform.isWindows) {
      // In Windows, AppData/Roaming is the standard
      final directory = await getApplicationSupportDirectory();
      return directory.path;
    } else {
      // On mobile
      return await getDatabasesPath();
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE services (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        default_price REAL NOT NULL,
        description TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_name TEXT NOT NULL,
        student_class TEXT NOT NULL,
        service_id INTEGER NOT NULL,
        target_year INTEGER NOT NULL,
        target_month TEXT NOT NULL,
        target_day INTEGER NOT NULL,
        nominal REAL NOT NULL,
        cash_received REAL,
        payment_method TEXT NOT NULL,
        transfer_channel TEXT NOT NULL,
        order_date TEXT NOT NULL,
        status TEXT NOT NULL,
        notes TEXT NOT NULL,
        is_revised INTEGER NOT NULL DEFAULT 0,
        parent_order_id INTEGER,
        FOREIGN KEY (service_id) REFERENCES services (id) ON DELETE RESTRICT
      )
    ''');

    await db.execute('''
      CREATE TABLE revisions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        revision_reason TEXT NOT NULL,
        revision_date TEXT NOT NULL,
        old_details TEXT NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE
      )
    ''');

    // Seed some initial services
    final now = DateTime.now().toIso8601String();
    await db.rawInsert('''
      INSERT INTO services (name, category, default_price, description, created_at)
      VALUES 
      ('Les Matematika SMP', 'SMP', 150000.0, 'Bimbingan belajar matematika untuk siswa SMP', '$now'),
      ('Les IPA Terpadu SMP', 'SMP', 160000.0, 'Bimbingan belajar Fisika & Biologi untuk siswa SMP', '$now'),
      ('Les Matematika SMA', 'SMA/SMK', 200000.0, 'Bimbingan belajar matematika tingkat SMA/SMK', '$now'),
      ('Les Fisika SMA', 'SMA/SMK', 220000.0, 'Bimbingan belajar fisika lanjutan tingkat SMA/SMK', '$now'),
      ('Les Bahasa Inggris SMA', 'SMA/SMK', 180000.0, 'Bimbingan bahasa Inggris percakapan & tata bahasa SMA/SMK', '$now')
    ''');
  }

  // --- SERVICE CRUD ---

  Future<int> insertService(ServiceModel service) async {
    final db = await instance.database;
    return await db.insert('services', service.toMap());
  }

  Future<List<ServiceModel>> getServices() async {
    final db = await instance.database;
    final result = await db.query('services', orderBy: 'category ASC, name ASC');
    return result.map((json) => ServiceModel.fromMap(json)).toList();
  }

  Future<int> updateService(ServiceModel service) async {
    final db = await instance.database;
    return await db.update(
      'services',
      service.toMap(),
      where: 'id = ?',
      whereArgs: [service.id],
    );
  }

  Future<int> deleteService(int id) async {
    final db = await instance.database;
    // Check if service is referenced by any orders
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM orders WHERE service_id = ?',
      [id],
    );
    final count = Sqflite.firstIntValue(countResult) ?? 0;
    if (count > 0) {
      throw Exception('Jasa ini tidak bisa dihapus karena telah digunakan dalam transaksi order.');
    }
    return await db.delete(
      'services',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- ORDER CRUD ---

  Future<void> fixLegacyOrderDates() async {
    try {
      final db = await database;
      final ordersRaw = await db.query('orders');
      const monthsMap = {
        'Januari': 1, 'Februari': 2, 'Maret': 3, 'April': 4,
        'Mei': 5, 'Juni': 6, 'Juli': 7, 'Agustus': 8,
        'September': 9, 'Oktober': 10, 'November': 11, 'Desember': 12,
      };

      for (final map in ordersRaw) {
        final id = map['id'] as int?;
        final targetYear = map['target_year'] as int?;
        final targetMonthStr = map['target_month'] as String?;
        final targetDay = map['target_day'] as int?;
        final orderDateStr = map['order_date'] as String?;

        if (id != null && targetYear != null && targetMonthStr != null && targetDay != null && orderDateStr != null) {
          final monthNum = monthsMap[targetMonthStr];
          if (monthNum != null) {
            final currentDate = DateTime.tryParse(orderDateStr);
            if (currentDate != null) {
              if (currentDate.year != targetYear || currentDate.month != monthNum || currentDate.day != targetDay) {
                final newDate = DateTime(
                  targetYear,
                  monthNum,
                  targetDay,
                  currentDate.hour,
                  currentDate.minute,
                  currentDate.second,
                );
                await db.update(
                  'orders',
                  {'order_date': newDate.toIso8601String()},
                  where: 'id = ?',
                  whereArgs: [id],
                );
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error fixing legacy order dates: $e');
    }
  }

  Future<int> insertOrder(OrderModel order) async {
    final db = await instance.database;
    return await db.insert('orders', order.toMap());
  }

  Future<List<OrderModel>> getOrders() async {
    await fixLegacyOrderDates();
    final db = await instance.database;
    // Join with services to get service name and category
    final result = await db.rawQuery('''
      SELECT o.*, s.name as service_name, s.category as service_category
      FROM orders o
      JOIN services s ON o.service_id = s.id
      ORDER BY o.order_date DESC
    ''');
    return result.map((json) => OrderModel.fromMap(json)).toList();
  }

  Future<OrderModel?> getOrderById(int id) async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT o.*, s.name as service_name, s.category as service_category
      FROM orders o
      JOIN services s ON o.service_id = s.id
      WHERE o.id = ?
    ''', [id]);
    if (result.isNotEmpty) {
      return OrderModel.fromMap(result.first);
    }
    return null;
  }

  Future<int> updateOrder(OrderModel order) async {
    final db = await instance.database;
    return await db.update(
      'orders',
      order.toMap(),
      where: 'id = ?',
      whereArgs: [order.id],
    );
  }

  Future<int> deleteOrder(int id) async {
    final db = await instance.database;
    return await db.delete(
      'orders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- REVISION CRUD ---

  Future<int> insertRevision(RevisionModel revision) async {
    final db = await instance.database;
    return await db.insert('revisions', revision.toMap());
  }

  Future<List<RevisionModel>> getRevisionsForOrder(int orderId) async {
    final db = await instance.database;
    final result = await db.query(
      'revisions',
      where: 'order_id = ?',
      whereArgs: [orderId],
      orderBy: 'revision_date DESC',
    );
    return result.map((json) => RevisionModel.fromMap(json)).toList();
  }

  // --- BACKUP & RESTORE ---

  Future<String> getDatabaseFileAbsolutePath() async {
    final dbPath = await _getDatabaseDirectoryPath();
    return join(dbPath, 'tutorku.db');
  }

  Future<void> exportBackup(String targetFilePath) async {
    // Flush sqlite cache to disk
    final db = await database;
    await db.rawQuery('PRAGMA wal_checkpoint(FULL)');
    
    final dbFile = File(await getDatabaseFileAbsolutePath());
    if (await dbFile.exists()) {
      await dbFile.copy(targetFilePath);
    } else {
      throw Exception('Database file tidak ditemukan.');
    }
  }

  Future<void> importBackup(String sourceFilePath) async {
    // 1. Close current connection
    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    // 2. Overwrite file
    final sourceFile = File(sourceFilePath);
    if (await sourceFile.exists()) {
      final dbFilePath = await getDatabaseFileAbsolutePath();
      
      // Ensure target directory exists
      final targetFile = File(dbFilePath);
      if (!await targetFile.parent.exists()) {
        await targetFile.parent.create(recursive: true);
      }
      
      await sourceFile.copy(dbFilePath);
    } else {
      throw Exception('File backup sumber tidak ditemukan.');
    }

    // 3. Re-initialize database
    _database = await _initDB('tutorku.db');
  }
}
