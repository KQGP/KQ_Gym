import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'member.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'kq_gym.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE members (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            phone TEXT NOT NULL,
            startDate TEXT NOT NULL,
            endDate TEXT NOT NULL,
            isActive INTEGER NOT NULL,
            notes TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Add originalStartDate column and populate it with startDate values
          await db.execute('ALTER TABLE members ADD COLUMN originalStartDate TEXT');
          await db.execute('UPDATE members SET originalStartDate = startDate');
        }
        if (oldVersion < 3) {
          // Remove originalStartDate column as it's no longer needed
          await db.execute('CREATE TABLE members_new (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, phone TEXT NOT NULL, startDate TEXT NOT NULL, endDate TEXT NOT NULL, isActive INTEGER NOT NULL, notes TEXT)');
          await db.execute('INSERT INTO members_new SELECT id, name, phone, startDate, endDate, isActive, notes FROM members');
          await db.execute('DROP TABLE members');
          await db.execute('ALTER TABLE members_new RENAME TO members');
        }
      },
    );
  }

  Future<int> insertMember(Member member) async {
    final dbClient = await db;
    return await dbClient.insert('members', member.toMap());
  }

  Future<List<Member>> getMembers({bool activeOnly = true}) async {
    final dbClient = await db;
    final maps = await dbClient.query(
      'members',
      where: activeOnly ? 'isActive = ?' : null,
      whereArgs: activeOnly ? [1] : null,
      orderBy: 'endDate ASC',
    );
    return maps.map((e) => Member.fromMap(e)).toList();
  }

  Future<List<Member>> searchMembers(String query, {bool activeOnly = true}) async {
    final dbClient = await db;
    final maps = await dbClient.query(
      'members',
      where: '${activeOnly ? 'isActive = 1 AND ' : ''}(name LIKE ? OR phone LIKE ?)',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'endDate ASC',
    );
    return maps.map((e) => Member.fromMap(e)).toList();
  }

  Future<int> updateMember(Member member) async {
    final dbClient = await db;
    return await dbClient.update(
      'members',
      member.toMap(),
      where: 'id = ?',
      whereArgs: [member.id],
    );
  }

  Future<int> softDeleteMember(int id) async {
    final dbClient = await db;
    return await dbClient.update(
      'members',
      {'isActive': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteMember(int id) async {
    final dbClient = await db;
    return await dbClient.delete(
      'members',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
} 