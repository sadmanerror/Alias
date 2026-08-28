import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:alias/models/message_model.dart';

class LocalDbService {
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'alias_messages.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        chatId TEXT,
        senderId TEXT,
        receiverId TEXT,
        type TEXT,
        content TEXT,
        mediaUrl TEXT,
        thumbnailUrl TEXT,
        fileName TEXT,
        fileSize INTEGER,
        duration INTEGER,
        timestamp INTEGER,
        isRead INTEGER,
        isDelivered INTEGER,
        gifUrl TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE chats (
        chatId TEXT PRIMARY KEY,
        participants TEXT,
        lastMessage TEXT,
        lastMessageTime INTEGER,
        lastMessageType TEXT
      )
    ''');
  }

  Future<void> insertMessage(MessageModel message, String chatId) async {
    final db = await database;
    await db.insert(
      'messages',
      {
        'id': message.messageId,
        'chatId': chatId,
        'senderId': message.senderId,
        'receiverId': message.receiverId,
        'type': message.type.toString(),
        'content': message.content,
        'mediaUrl': message.mediaUrl,
        'thumbnailUrl': message.thumbnailUrl,
        'fileName': message.fileName,
        'fileSize': message.fileSize,
        'duration': message.duration,
        'timestamp': message.timestamp.millisecondsSinceEpoch,
        'isRead': message.isRead ? 1 : 0,
        'isDelivered': message.isDelivered ? 1 : 0,
        'gifUrl': message.gifUrl,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<MessageModel>> getMessages(String chatId, {int limit = 50, int offset = 0}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'chatId = ?',
      whereArgs: [chatId],
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );

    return List.generate(maps.length, (i) {
      // Need proper type parsing in the actual app depending on enum structure
      // For this scaffold, parsing maps back to MessageModel
      return MessageModel(
        messageId: maps[i]['id'],
        senderId: maps[i]['senderId'],
        receiverId: maps[i]['receiverId'],
        type: maps[i]['type'], // Need to map back from string
        content: maps[i]['content'],
        mediaUrl: maps[i]['mediaUrl'],
        thumbnailUrl: maps[i]['thumbnailUrl'],
        fileName: maps[i]['fileName'],
        fileSize: maps[i]['fileSize'],
        duration: maps[i]['duration'],
        timestamp: DateTime.fromMillisecondsSinceEpoch(maps[i]['timestamp']),
        isRead: maps[i]['isRead'] == 1,
        isDelivered: maps[i]['isDelivered'] == 1,
        gifUrl: maps[i]['gifUrl'],
      );
    });
  }

  Future<void> deleteMessage(String messageId) async {
    final db = await database;
    await db.delete(
      'messages',
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  Future<void> clearChat(String chatId) async {
    final db = await database;
    await db.delete(
      'messages',
      where: 'chatId = ?',
      whereArgs: [chatId],
    );
  }

  Future<String> getDatabasePath() async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, 'alias_messages.db');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  Future<void> syncFromList(String chatId, List<MessageModel> messages) async {
    final db = await database;
    final batch = db.batch();
    for (var message in messages) {
      batch.insert(
        'messages',
        {
          'id': message.messageId,
          'chatId': chatId,
          'senderId': message.senderId,
          'receiverId': message.receiverId,
          'type': message.type.toString(),
          'content': message.content,
          'mediaUrl': message.mediaUrl,
          'thumbnailUrl': message.thumbnailUrl,
          'fileName': message.fileName,
          'fileSize': message.fileSize,
          'duration': message.duration,
          'timestamp': message.timestamp.millisecondsSinceEpoch,
          'isRead': message.isRead ? 1 : 0,
          'isDelivered': message.isDelivered ? 1 : 0,
          'gifUrl': message.gifUrl,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }
}
