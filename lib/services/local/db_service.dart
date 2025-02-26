import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../config/constants.dart';
import '../../models/message.dart';
import '../../utils/logger.dart';

class DBService {
  static final DBService _instance = DBService._internal();
  factory DBService() => _instance;
  DBService._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // 创建消息表
        await db.execute('''
          CREATE TABLE ${AppConstants.messageTable} (
            id TEXT PRIMARY KEY,
            timestamp INTEGER NOT NULL,
            type TEXT NOT NULL,
            content TEXT,
            isDeleted INTEGER DEFAULT 0,
            isEdited INTEGER DEFAULT 0,
            fileName TEXT,
            filePath TEXT,
            fileSize INTEGER,
            fileType TEXT,
            isDownloaded INTEGER DEFAULT 0
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
        AppConstants.messageTable,
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
        AppConstants.messageTable,
        where: 'isDeleted = 0',
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
        AppConstants.messageTable,
        where: 'isDeleted = 0',
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
        AppConstants.messageTable,
        where: 'content LIKE ? OR fileName LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
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

      final result = await db.update(
        AppConstants.messageTable,
        {'isDeleted': 1},
        where: 'id = ?',
        whereArgs: [id],
      );

      if (result > 0) {
        AppLogger.debug('DBService - 消息记录删除成功，影响行数: $result');
      } else {
        AppLogger.warning('DBService - 未找到要删除的消息记录: $id');
      }
    } catch (e, stackTrace) {
      AppLogger.error('DBService - 删除消息记录失败', e, stackTrace);
      rethrow;
    }
  }

  // 更新消息
  Future<void> updateMessage(Message message) async {
    try {
      final db = await database;
      await db.update(
        AppConstants.messageTable,
        message.toMap(),
        where: 'id = ?',
        whereArgs: [message.id],
      );
    } catch (e, stackTrace) {
      AppLogger.error('更新消息失败', e, stackTrace);
      rethrow;
    }
  }
}
