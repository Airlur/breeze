import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../models/message.dart';
import '../../models/file.dart';
import '../../models/device.dart';
import '../../utils/logger.dart';

class DBService {
  static final DBService _instance = DBService._internal();
  factory DBService() => _instance;
  DBService._internal();

  static Database? _db;
  static const String dbName = 'chat.db';

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, dbName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // 创建消息表
        await db.execute('''
          CREATE TABLE messages (
            id TEXT PRIMARY KEY,
            content TEXT NOT NULL,
            type TEXT NOT NULL,
            sender_device_id TEXT NOT NULL,
            timestamp INTEGER NOT NULL,
            is_encrypted INTEGER NOT NULL DEFAULT 0,
            is_edited INTEGER NOT NULL DEFAULT 0,
            is_deleted INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        // 创建文件表
        await db.execute('''
          CREATE TABLE files (
            id TEXT PRIMARY KEY,
            url TEXT NOT NULL,
            filename TEXT NOT NULL,
            size INTEGER NOT NULL,
            mime_type TEXT NOT NULL,
            uploaded_by TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');

        // 创建设备表
        await db.execute('''
          CREATE TABLE devices (
            id TEXT PRIMARY KEY,
            device_id TEXT NOT NULL,
            device_name TEXT NOT NULL,
            device_type TEXT NOT NULL,
            is_master INTEGER NOT NULL DEFAULT 0,
            last_active TEXT,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  // 插入消息
  Future<void> insertMessage(Message message) async {
    try {
      final db = await database;
      await db.insert(
        'messages',
        message.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e, stackTrace) {
      AppLogger.error('插入消息失败', e, stackTrace);
      rethrow;
    }
  }

  // 获取所有消息
  Future<List<Message>> getAllMessages() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'messages',
        orderBy: 'timestamp DESC',
      );

      return List.generate(maps.length, (i) => Message.fromMap(maps[i]));
    } catch (e, stackTrace) {
      AppLogger.error('获取消息失败', e, stackTrace);
      rethrow;
    }
  }

  // 获取分页消息
  Future<List<Message>> getPagedMessages(int limit, int offset) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'messages',
        orderBy: 'timestamp DESC',
        limit: limit,
        offset: offset,
      );

      return List.generate(maps.length, (i) => Message.fromMap(maps[i]));
    } catch (e, stackTrace) {
      AppLogger.error('获取分页消息失败', e, stackTrace);
      rethrow;
    }
  }

  // 搜索消息
  Future<List<Message>> searchMessages(String query) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'messages',
        where: 'content LIKE ?',
        whereArgs: ['%$query%'],
        orderBy: 'timestamp DESC',
      );

      return List.generate(maps.length, (i) => Message.fromMap(maps[i]));
    } catch (e, stackTrace) {
      AppLogger.error('搜索消息失败', e, stackTrace);
      rethrow;
    }
  }

  // 删除消息
  Future<void> deleteMessage(String id) async {
    try {
      final db = await database;
      await db.delete(
        'messages',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e, stackTrace) {
      AppLogger.error('删除消息失败', e, stackTrace);
      rethrow;
    }
  }

  // 更新消息
  Future<void> updateMessage(Message message) async {
    try {
      final db = await database;
      await db.update(
        'messages',
        message.toMap(),
        where: 'id = ?',
        whereArgs: [message.id],
      );
    } catch (e, stackTrace) {
      AppLogger.error('更新消息失败', e, stackTrace);
      rethrow;
    }
  }

  // 文件相关操作
  Future<void> insertFile(FileModel file) async {
    final db = await database;
    await db.insert(
      'files',
      file.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<FileModel?> getFile(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'files',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return FileModel.fromMap(maps.first);
  }

  Future<void> deleteFile(String id) async {
    final db = await database;
    await db.delete(
      'files',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 设备相关操作
  Future<void> insertDevice(Device device) async {
    final db = await database;
    await db.insert(
      'devices',
      device.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Device?> getDevice(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'devices',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Device.fromMap(maps.first);
  }

  Future<List<Device>> getAllDevices() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('devices');
    return List.generate(maps.length, (i) => Device.fromMap(maps[i]));
  }

  Future<void> deleteDevice(String id) async {
    final db = await database;
    await db.delete(
      'devices',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
