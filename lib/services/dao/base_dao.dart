import 'package:logging/logging.dart';
import 'package:sqflite/sqflite.dart';
import '../../services/database_helper.dart';

/// Abstract base class for all Data Access Objects (DAOs)
/// Provides common CRUD operations to reduce boilerplate code
abstract class BaseDao<T> {
  /// The database helper instance
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final Logger logger;

  BaseDao(String loggerName) : logger = Logger(loggerName);

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
    logger.fine('Inserting a new record into $tableName');
    try {
      final id = await db.insert(
        tableName,
        toMap(model),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      logger.fine('Record inserted with id: $id');
      return id;
    } catch (e) {
      logger.severe('Failed to insert record into $tableName: $e');
      rethrow;
    }
  }

  /// Inserts multiple records into the database
  Future<List<int>> insertAll(List<T> models) async {
    final db = await database;
    final List<int> ids = [];
    logger.fine('Inserting ${models.length} records into $tableName');
    try {
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
      logger.fine('Successfully inserted ${ids.length} records.');
      return ids;
    } catch (e) {
      logger.severe('Failed to insert multiple records into $tableName: $e');
      rethrow;
    }
  }

  /// Retrieves all records from the database
  Future<List<T>> getAll() async {
    final db = await database;
    logger.fine('Retrieving all records from $tableName');
    try {
      final List<Map<String, dynamic>> maps = await db.query(tableName);
      final results = maps.map((map) => fromMap(map)).toList();
      logger.fine('Retrieved ${results.length} records from $tableName');
      return results;
    } catch (e) {
      logger.severe('Failed to get all records from $tableName: $e');
      rethrow;
    }
  }

  /// Retrieves a record by its ID
  Future<T?> getById(String id) async {
    final db = await database;
    logger.fine('Retrieving record with id $id from $tableName');
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isNotEmpty) {
        logger.fine('Record with id $id found in $tableName');
        return fromMap(maps.first);
      }
      logger.fine('Record with id $id not found in $tableName');
      return null;
    } catch (e) {
      logger.severe('Failed to get record with id $id from $tableName: $e');
      rethrow;
    }
  }

  /// Updates a record in the database
  Future<int> update(T model, {String idColumn = 'id'}) async {
    final db = await database;
    final map = toMap(model);

    final id = map[idColumn];
    logger.fine('Updating record with $idColumn $id in $tableName');
    map.remove(idColumn);

    try {
      final count = await db.update(
        tableName,
        map,
        where: '$idColumn = ?',
        whereArgs: [id],
      );
      logger.fine('Updated $count record(s) in $tableName');
      return count;
    } catch (e) {
      logger.severe('Failed to update record with $idColumn $id in $tableName: $e');
      rethrow;
    }
  }

  /// Deletes a record from the database
  Future<int> delete(String id, {String idColumn = 'id'}) async {
    final db = await database;
    logger.fine('Deleting record with $idColumn $id from $tableName');
    try {
      final count = await db.delete(
        tableName,
        where: '$idColumn = ?',
        whereArgs: [id],
      );
      logger.fine('Deleted $count record(s) from $tableName');
      return count;
    } catch (e) {
      logger.severe('Failed to delete record with $idColumn $id from $tableName: $e');
      rethrow;
    }
  }

  /// Deletes all records from the table
  Future<int> deleteAll() async {
    final db = await database;
    logger.warning('Deleting all records from $tableName');
    try {
      final count = await db.delete(tableName);
      logger.fine('Deleted all $count records from $tableName');
      return count;
    } catch (e) {
      logger.severe('Failed to delete all records from $tableName: $e');
      rethrow;
    }
  }

  /// Executes a raw SQL query and returns the results as model objects
  Future<List<T>> rawQuery(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    logger.fine('Executing raw query on $tableName: $sql with arguments: $arguments');
    try {
      final List<Map<String, dynamic>> maps = await db.rawQuery(sql, arguments);
      final results = maps.map((map) => fromMap(map)).toList();
      logger.fine('Raw query returned ${results.length} results');
      return results;
    } catch (e) {
      logger.severe('Failed to execute raw query on $tableName: $e');
      rethrow;
    }
  }

  /// Executes a raw SQL update statement
  Future<int> rawUpdate(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    logger.fine('Executing raw update on $tableName: $sql with arguments: $arguments');
    try {
      final count = await db.rawUpdate(sql, arguments);
      logger.fine('Raw update affected $count rows');
      return count;
    } catch (e) {
      logger.severe('Failed to execute raw update on $tableName: $e');
      rethrow;
    }
  }

  /// Executes a raw SQL delete statement
  Future<int> rawDelete(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    logger.fine('Executing raw delete on $tableName: $sql with arguments: $arguments');
    try {
      final count = await db.rawDelete(sql, arguments);
      logger.fine('Raw delete affected $count rows');
      return count;
    } catch (e) {
      logger.severe('Failed to execute raw delete on $tableName: $e');
      rethrow;
    }
  }
}
