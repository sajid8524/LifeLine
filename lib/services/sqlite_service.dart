import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/device_model.dart';
import '../models/emergency_message.dart';

class SqliteService {
  Database? _database;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) {
      return existing;
    }
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'lifesaver_dtn.db');
    _database = await openDatabase(path, version: 2, onCreate: _create, onUpgrade: _upgrade);
    return _database!;
  }

  Future<void> _create(Database db, int version) async {
    await db.execute('''
      CREATE TABLE emergency_messages (
        messageId TEXT PRIMARY KEY,
        senderDevice TEXT NOT NULL,
        type TEXT NOT NULL,
        victims INTEGER NOT NULL,
        description TEXT NOT NULL,
        medicalEmergency INTEGER NOT NULL,
        priority TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        timestamp TEXT NOT NULL,
        status TEXT NOT NULL,
        photoPath TEXT,
        ttl INTEGER NOT NULL DEFAULT 3,
        relayCount INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE connected_devices (
        endpointId TEXT PRIMARY KEY,
        deviceName TEXT NOT NULL,
        connectedAt TEXT NOT NULL,
        lastSeenAt TEXT NOT NULL,
        status TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        messageId TEXT,
        action TEXT NOT NULL,
        detail TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE forwarding_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        messageId TEXT NOT NULL,
        deviceId TEXT NOT NULL,
        action TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        UNIQUE(messageId, deviceId)
      )
    ''');
  }

  Future<void> _upgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _addColumnIfMissing(db, 'emergency_messages', 'ttl', 'INTEGER NOT NULL DEFAULT 3');
      await _addColumnIfMissing(db, 'emergency_messages', 'relayCount', 'INTEGER NOT NULL DEFAULT 0');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS forwarding_logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          messageId TEXT NOT NULL,
          deviceId TEXT NOT NULL,
          action TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          UNIQUE(messageId, deviceId)
        )
      ''');
    }
  }

  Future<void> _addColumnIfMissing(Database db, String table, String column, String definition) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    final exists = columns.any((row) => row['name'] == column);
    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
    }
  }

  Future<void> upsertEmergency(EmergencyMessage message) async {
    final db = await database;
    await db.insert(
      'emergency_messages',
      message.toDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<EmergencyMessage>> getEmergencies({String? status}) async {
    final db = await database;
    final rows = await db.query(
      'emergency_messages',
      where: status == null ? null : 'status = ?',
      whereArgs: status == null ? null : [status],
      orderBy: 'timestamp DESC',
    );
    return rows.map(EmergencyMessage.fromDb).toList();
  }

  Future<List<EmergencyMessage>> getUnsyncedEmergencies() async {
    final db = await database;
    final rows = await db.query(
      'emergency_messages',
      where: 'status != ?',
      whereArgs: ['SYNCED'],
      orderBy: 'timestamp ASC',
    );
    return rows.map(EmergencyMessage.fromDb).toList();
  }

  Future<List<EmergencyMessage>> getForwardableEmergencies() async {
    final db = await database;
    final rows = await db.query(
      'emergency_messages',
      where: 'ttl > 0 AND status != ?',
      whereArgs: ['SYNCED'],
      orderBy: 'timestamp ASC',
    );
    return rows.map(EmergencyMessage.fromDb).toList();
  }

  Future<bool> emergencyExists(String messageId) async {
    final db = await database;
    final rows = await db.query(
      'emergency_messages',
      columns: ['messageId'],
      where: 'messageId = ?',
      whereArgs: [messageId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<void> updateEmergencyStatus(String messageId, String status) async {
    final db = await database;
    await db.update(
      'emergency_messages',
      {'status': status},
      where: 'messageId = ?',
      whereArgs: [messageId],
    );
  }

  Future<void> deleteEmergency(String messageId) async {
    final db = await database;
    await db.delete('emergency_messages', where: 'messageId = ?', whereArgs: [messageId]);
  }

  Future<int> emergencyCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) AS count FROM emergency_messages');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> upsertDevice(DeviceModel device) async {
    final db = await database;
    await db.insert(
      'connected_devices',
      device.toDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> addSyncLog(String messageId, String action, String detail) async {
    final db = await database;
    await db.insert('sync_logs', {
      'messageId': messageId,
      'action': action,
      'detail': detail,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<bool> wasForwardedToDevice(String messageId, String deviceId) async {
    final db = await database;
    final rows = await db.query(
      'forwarding_logs',
      columns: ['id'],
      where: 'messageId = ? AND deviceId = ?',
      whereArgs: [messageId, deviceId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<void> addForwardingLog(String messageId, String deviceId, String action) async {
    final db = await database;
    await db.insert(
      'forwarding_logs',
      {
        'messageId': messageId,
        'deviceId': deviceId,
        'action': action,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }
}
