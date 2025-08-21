import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p; // Alias to avoid conflict with path_provider's Directory

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  static const String _dbName = 'workout_tracker.db';
  static const int _dbVersion = 2; // Updated version

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = p.join(documentsDirectory.path, _dbName);
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, // Added onUpgrade handler
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE UserSettings (
        id TEXT PRIMARY KEY,
        units TEXT,
        theme TEXT,
        other_settings_json TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE WorkoutFolders (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        orderIndex INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE Workouts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        folderId TEXT,
        iconCodePoint INTEGER,
        colorValue INTEGER,
        notes TEXT,
        lastUsed TEXT, -- ISO8601 string
        orderIndex INTEGER,
        status INTEGER DEFAULT 0, -- 0: template, 1: inProgress, 2: completed
        templateId TEXT, -- Links a session to its template
        startedAt TEXT, -- ISO8601 string
        completedAt TEXT, -- ISO8601 string
        FOREIGN KEY (folderId) REFERENCES WorkoutFolders (id) ON DELETE SET NULL,
        FOREIGN KEY (templateId) REFERENCES Workouts (id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE WorkoutExercises (
        id TEXT PRIMARY KEY,
        workoutId TEXT NOT NULL,
        exerciseSlug TEXT NOT NULL,
        notes TEXT,
        orderIndex INTEGER,
        FOREIGN KEY (workoutId) REFERENCES Workouts (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE WorkoutSets (
        id TEXT PRIMARY KEY,
        workoutExerciseId TEXT NOT NULL,
        setIndex INTEGER NOT NULL,
        targetReps INTEGER,
        targetWeight REAL,
        targetRestSeconds INTEGER,
        actualReps INTEGER,
        actualWeight REAL,
        isCompleted INTEGER DEFAULT 0, -- 0 for false, 1 for true
        orderIndex INTEGER,
        FOREIGN KEY (workoutExerciseId) REFERENCES WorkoutExercises (id) ON DELETE CASCADE
      )
    ''');

    // Optionally, insert default settings
    await db.insert('UserSettings', {
      'id': 'default_settings',
      'units': 'metric',
      'theme': 'dark',
      'other_settings_json': '{}'
    });
  }

  // Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new columns to Workouts table
      await db.execute('ALTER TABLE Workouts ADD COLUMN status INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE Workouts ADD COLUMN templateId TEXT');
      await db.execute('ALTER TABLE Workouts ADD COLUMN startedAt TEXT');
      await db.execute('ALTER TABLE Workouts ADD COLUMN completedAt TEXT');
      
      // Add new columns to WorkoutSets table
      await db.execute('ALTER TABLE WorkoutSets ADD COLUMN actualReps INTEGER');
      await db.execute('ALTER TABLE WorkoutSets ADD COLUMN actualWeight REAL');
      await db.execute('ALTER TABLE WorkoutSets ADD COLUMN isCompleted INTEGER DEFAULT 0');
      
      // Update existing WorkoutSets to set isCompleted to 0 (false) for all existing records
      await db.rawUpdate('UPDATE WorkoutSets SET isCompleted = 0 WHERE isCompleted IS NULL');
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null; // Reset the static instance so it can be re-initialized if needed
  }
}
