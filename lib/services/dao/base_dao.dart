import 'package:sqflite/sqflite.dart';
import '../../services/database_helper.dart';

/// Abstract base class for all Data Access Objects (DAOs)
/// Provides common CRUD operations to reduce boilerplate code
abstract class BaseDao<T> {
  /// The database helper instance
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// The name of the database table this DAO operates on
  String get tableName;

  /// Converts a database row (Map) to the model object
  T fromMap(Map<String, dynamic> map);

  /// Converts a model object to a database row (Map)
  Map<String, dynamic> toMap(T model);

  /// Gets the database instance
  Future<Database> get database async => await _dbHelper.database;

  /// Inserts a new record into the database
  Future<int> insert(T model) async {
    final db = await database;
    return await db.insert(
      tableName,
      toMap(model),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  /// Inserts multiple records into the database
  Future<List<int>> insertAll(List<T> models) async {
    final db = await database;
    final List<int> ids = [];
    
    await db.transaction((txn) async {
      for (final model in models) {
        final id = await txn.insert(
          tableName,
          toMap(model),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
        ids.add(id);
      }
    });
    
    return ids;
  }

  /// Retrieves all records from the database
  Future<List<T>> getAll() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(tableName);
    return maps.map((map) => fromMap(map)).toList();
  }

  /// Retrieves a record by its ID
  Future<T?> getById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return fromMap(maps.first);
    }
    return null;
  }

  /// Updates a record in the database
  Future<int> update(T model, {String idColumn = 'id'}) async {
    final db = await database;
    final map = toMap(model);
    
    // Remove the ID from the map to avoid updating it
    final id = map[idColumn];
    map.remove(idColumn);
    
    return await db.update(
      tableName,
      map,
      where: '$idColumn = ?',
      whereArgs: [id],
    );
  }

  /// Deletes a record from the database
  Future<int> delete(String id, {String idColumn = 'id'}) async {
    final db = await database;
    return await db.delete(
      tableName,
      where: '$idColumn = ?',
      whereArgs: [id],
    );
  }

  /// Deletes all records from the table
  Future<int> deleteAll() async {
    final db = await database;
    return await db.delete(tableName);
  }

  /// Executes a raw SQL query and returns the results as model objects
  Future<List<T>> rawQuery(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(sql, arguments);
    return maps.map((map) => fromMap(map)).toList();
  }

  /// Executes a raw SQL update statement
  Future<int> rawUpdate(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawUpdate(sql, arguments);
  }

  /// Executes a raw SQL delete statement
  Future<int> rawDelete(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawDelete(sql, arguments);
  }
}
