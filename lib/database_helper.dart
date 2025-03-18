import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // private constructor
  DatabaseHelper._init();

  // Singleton-Pattern
  // this creates the only instance of the database that can get used globally in the whole code
  // you  can use this in code with DatabaseHelper.instance
  static final DatabaseHelper instance = DatabaseHelper._init();
  
  // static means the variable belongs to the class itself, not to an instance of the class
  // this way the database stays in the storage and doesnt get opened every single time, a method is called
  // "?" means _database is either Database or null because we initialize it only later
  static Database? _database;

  // Future means it returns a database but later because opening it takes some time
  Future<Database> get database async { // async allows use of await
    // database already exists, return it
    if (_database != null) {
      return _database!;
    }
    // database doesnt exist yet, call _initDB to create
    else {
      _database = await _initDB('clubs.db'); // await causes that the app doesnt freeze while loading the db
    return _database!;
    }
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // creates the clubs table with variables id and name
    await db.execute('''
      CREATE TABLE clubs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        city TEXT NOT NULL,
        year TEXT NOT NULL,
        color TEXT NOT NULL,
        secondcolor TEXT NOT NULL,
        description TEXT NOT NULL
      )
    ''');

    // creates the members table
    // and it makes sure to delete all members of a club if that club gets deleted
    await db.execute('''
      CREATE TABLE members (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        birthdate INTEGER,
        clubId INTEGER,
        FOREIGN KEY (clubId) REFERENCES clubs (id) ON DELETE CASCADE 
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    /*
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE clubs ADD COLUMN description TEXT");
    }
    */
  }

  // get all existing clubs from db
  Future<List<Map<String, dynamic>>> getClubs() async {
    final db = await database;
    return await db.query('clubs');
  }

  // add a new club to db
  Future<int> addClub(String name, String city, String year, String color, String secondColor,String description) async {
    final db = await database;
    return await db.insert(
      'clubs',
      {'name': name,
       'city': city,
       'year': year,
       'color': color,
       'secondcolor': secondColor,
       'description': description
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // delete a club from db
  Future<int> deleteClub(int id) async {
    final db = await database;
    return await db.delete(
      'clubs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // get all members of a specific club
  Future<List<Map<String, dynamic>>> getMembers(int clubId) async {
    final db = await database;
    return await db.query(
      'members',
      where: 'clubId = ?',
      whereArgs: [clubId],
    );
  }

  // add a new member to db
  Future<int> addMember(String name, String birthdate, int clubId) async {
    final db = await database;
    return await db.insert(
      'members',
      {'name': name, 
      'birthdate': birthdate,
      'clubId': clubId},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // delete a member from db
  Future<int> deleteMember(int id) async {
    final db = await database;
    return await db.delete(
      'members',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
