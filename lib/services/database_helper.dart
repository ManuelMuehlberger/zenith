import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p; // Alias to avoid conflict with path_provider's Directory
import 'package:toml/toml.dart';

import '../models/exercise.dart';
import '../models/muscle_group.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  static const String _dbName = 'workout_tracker.db';
  static const int _dbVersion = 3; // Updated version

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
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create MuscleGroup table
    await db.execute('''
      CREATE TABLE MuscleGroup (
        name TEXT PRIMARY KEY
      )
    ''');

    // Create Exercise table
    await db.execute('''
      CREATE TABLE Exercise (
        slug TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        primaryMuscleGroup TEXT NOT NULL,
        secondaryMuscleGroups TEXT, -- JSON encoded list
        instructions TEXT, -- JSON encoded list
        image TEXT,
        animation TEXT,
        isBodyWeightExercise INTEGER DEFAULT 0, -- 0 for false, 1 for true
        FOREIGN KEY (primaryMuscleGroup) REFERENCES MuscleGroup (name)
      )
    ''');

    // Create UserData table
    await db.execute('''
      CREATE TABLE UserData (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        birthdate TEXT NOT NULL, -- ISO8601 string
        units TEXT NOT NULL DEFAULT 'metric',
        createdAt TEXT NOT NULL, -- ISO8601 string
        theme TEXT NOT NULL DEFAULT 'dark'
      )
    ''');

    // Create WeightEntry table
    await db.execute('''
      CREATE TABLE WeightEntry (
        id TEXT PRIMARY KEY,
        userDataId TEXT NOT NULL,
        timestamp TEXT NOT NULL, -- ISO8601 string
        value REAL NOT NULL,
        FOREIGN KEY (userDataId) REFERENCES UserData (id) ON DELETE CASCADE
      )
    ''');

    // Create WorkoutFolder table
    await db.execute('''
      CREATE TABLE WorkoutFolder (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        orderIndex INTEGER
      )
    ''');

    // Create Workout table
    await db.execute('''
      CREATE TABLE Workout (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        iconCodePoint INTEGER,
        colorValue INTEGER,
        folderId TEXT,
        notes TEXT,
        lastUsed TEXT, -- ISO8601 string
        orderIndex INTEGER,
        status INTEGER NOT NULL DEFAULT 0, -- 0: template, 1: inProgress, 2: completed
        templateId TEXT, -- Links a session to its template
        startedAt TEXT, -- ISO8601 string
        completedAt TEXT, -- ISO8601 string
        FOREIGN KEY (folderId) REFERENCES WorkoutFolder (id) ON DELETE SET NULL,
        FOREIGN KEY (templateId) REFERENCES Workout (id) ON DELETE SET NULL
      )
    ''');

    // Create WorkoutExercise table
    await db.execute('''
      CREATE TABLE WorkoutExercise (
        id TEXT PRIMARY KEY,
        workoutId TEXT NOT NULL,
        exerciseSlug TEXT NOT NULL,
        notes TEXT,
        orderIndex INTEGER,
        FOREIGN KEY (workoutId) REFERENCES Workout (id) ON DELETE CASCADE,
        FOREIGN KEY (exerciseSlug) REFERENCES Exercise (slug) ON DELETE CASCADE
      )
    ''');

    // Create WorkoutSet table
    await db.execute('''
      CREATE TABLE WorkoutSet (
        id TEXT PRIMARY KEY,
        workoutExerciseId TEXT NOT NULL,
        setIndex INTEGER NOT NULL,
        targetReps INTEGER,
        targetWeight REAL,
        targetRestSeconds INTEGER,
        actualReps INTEGER,
        actualWeight REAL,
        isCompleted INTEGER DEFAULT 0, -- 0 for false, 1 for true
        FOREIGN KEY (workoutExerciseId) REFERENCES WorkoutExercise (id) ON DELETE CASCADE
      )
    ''');

    // Insert default muscle groups
    final muscleGroups = [
      'Chest', 'Triceps', 'Front Deltoid', 'Lateral Deltoid', 'Rear Deltoid',
      'Shoulders', 'Rotator Cuff (posterior)', 'Rotator Cuff (anterior)',
      'Biceps', 'Quads', 'Hamstrings', 'Glutes', 'Adductors', 'Lower Back',
      'Trapezius', 'Forearm Flexors', 'Calves', 'Abs', 'Obliques', 'Back', 'Legs', 'Cardio'
    ];
    
    for (final muscleGroup in muscleGroups) {
      await db.insert('MuscleGroup', {'name': muscleGroup});
    }
  }

  // Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new columns to Workouts table
      await db.execute('ALTER TABLE Workout ADD COLUMN status INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE Workout ADD COLUMN templateId TEXT');
      await db.execute('ALTER TABLE Workout ADD COLUMN startedAt TEXT');
      await db.execute('ALTER TABLE Workout ADD COLUMN completedAt TEXT');
      
      // Add new columns to WorkoutSets table
      await db.execute('ALTER TABLE WorkoutSet ADD COLUMN actualReps INTEGER');
      await db.execute('ALTER TABLE WorkoutSet ADD COLUMN actualWeight REAL');
      await db.execute('ALTER TABLE WorkoutSet ADD COLUMN isCompleted INTEGER DEFAULT 0');
      
      // Update existing WorkoutSets to set isCompleted to 0 (false) for all existing records
      await db.rawUpdate('UPDATE WorkoutSet SET isCompleted = 0 WHERE isCompleted IS NULL');
    }
    
    if (oldVersion < 3) {
      // Create new tables for full schema implementation
      // Create MuscleGroup table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS MuscleGroup (
          name TEXT PRIMARY KEY
        )
      ''');

      // Create Exercise table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS Exercise (
          slug TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          primaryMuscleGroup TEXT NOT NULL,
          secondaryMuscleGroups TEXT, -- JSON encoded list
          instructions TEXT, -- JSON encoded list
          image TEXT,
          animation TEXT,
          isBodyWeightExercise INTEGER DEFAULT 0, -- 0 for false, 1 for true
          FOREIGN KEY (primaryMuscleGroup) REFERENCES MuscleGroup (name)
        )
      ''');

      // Create UserData table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS UserData (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          birthdate TEXT NOT NULL, -- ISO8601 string
          units TEXT NOT NULL DEFAULT 'metric',
          createdAt TEXT NOT NULL, -- ISO8601 string
          theme TEXT NOT NULL DEFAULT 'dark'
        )
      ''');

      // Create WeightEntry table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS WeightEntry (
          id TEXT PRIMARY KEY,
          userDataId TEXT NOT NULL,
          timestamp TEXT NOT NULL, -- ISO8601 string
          value REAL NOT NULL,
          FOREIGN KEY (userDataId) REFERENCES UserData (id) ON DELETE CASCADE
        )
      ''');

      // Add missing columns to Workout table
      try {
        await db.execute('ALTER TABLE Workout ADD COLUMN description TEXT');
      } catch (e) {
        // Column might already exist
      }

      // Insert default muscle groups if they don't exist
      final muscleGroups = [
        'Chest', 'Triceps', 'Front Deltoid', 'Lateral Deltoid', 'Rear Deltoid',
        'Shoulders', 'Rotator Cuff (posterior)', 'Rotator Cuff (anterior)',
        'Biceps', 'Quads', 'Hamstrings', 'Glutes', 'Adductors', 'Lower Back',
        'Trapezius', 'Forearm Flexors', 'Calves', 'Abs', 'Obliques', 'Back', 'Legs', 'Cardio'
      ];
      
      for (final muscleGroup in muscleGroups) {
        await db.insert('MuscleGroup', {'name': muscleGroup}, 
            conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null; // Reset the static instance so it can be re-initialized if needed
  }
  
  // Helper method to seed exercises from TOML file
  Future<void> seedExercisesFromToml(String tomlContent) async {
    final db = await database;
    
    // Parse the TOML content using the toml package
    final tomlDocument = TomlDocument.parse(tomlContent);
    final tomlMap = tomlDocument.toMap();
    
    // Iterate through the parsed TOML data
    for (final entry in tomlMap.entries) {
      if (entry.key.startsWith('exercise_')) {
        final exerciseData = entry.value as Map<String, dynamic>;
        
        try {
          // Create a map for the exercise data
          final exerciseMap = <String, dynamic>{
            'slug': exerciseData['slug'] ?? '',
            'name': exerciseData['name'] ?? '',
            'primary_muscle_group': exerciseData['primary_muscle_group'] ?? '',
            'secondary_muscle_groups': jsonEncode(exerciseData['secondary_muscle_groups'] ?? []),
            'instructions': jsonEncode(exerciseData['instructions'] ?? []),
            'image': exerciseData['image'] ?? '',
            'animation': exerciseData['animation'] ?? '',
            'is_bodyweight_exercise': exerciseData['is_bodyweight_exercise'] ?? false,
          };
          
          // Insert the exercise into the database
          await db.insert('Exercise', exerciseMap,
              conflictAlgorithm: ConflictAlgorithm.ignore);
        } catch (e) {
          // Handle any errors during insertion
          print('Error inserting exercise ${exerciseData['slug']}: $e');
        }
      }
    }
  }
}
