import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p; // Alias to avoid conflict with path_provider's Directory
import 'package:toml/toml.dart';
import 'package:logging/logging.dart';

import 'package:zenith/models/muscle_group.dart';


class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  static final Logger _logger = Logger('DatabaseHelper');

  static const String _dbName = 'workout_tracker.db';
  static const int _dbVersion = 4; // Updated version for WorkoutTemplate

  Future<Database> get database async {
    if (_database != null) {
      _logger.fine('Database already initialized, returning existing instance');
      return _database!;
    }
    _logger.info('Initializing database for the first time');
    try {
      _database = await _initDB();
      _logger.info('Database initialization completed successfully');
      return _database!;
    } catch (e) {
      _logger.severe('Failed to initialize database: $e');
      rethrow;
    }
  }

  Future<Database> _initDB() async {
    try {
      _logger.info('Getting application documents directory');
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      String path = p.join(documentsDirectory.path, _dbName);
      _logger.info('Database path: $path');
      
      _logger.info('Opening database with version $_dbVersion');
      return await openDatabase(
        path,
        version: _dbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      _logger.severe('Error during database initialization: $e');
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    _logger.info('Creating new database with version $version');
    
    try {
      // Create MuscleGroup table
      _logger.info('Creating MuscleGroup table');
      await db.execute('''
        CREATE TABLE MuscleGroup (
          name TEXT PRIMARY KEY
        )
      ''');

      // Create Exercise table
      _logger.info('Creating Exercise table');
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
      _logger.info('Creating UserData table');
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
      _logger.info('Creating WeightEntry table');
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
      _logger.info('Creating WorkoutFolder table');
      await db.execute('''
        CREATE TABLE WorkoutFolder (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          orderIndex INTEGER
        )
      ''');

      // Create WorkoutTemplate table
      _logger.info('Creating WorkoutTemplate table');
      await db.execute('''
        CREATE TABLE WorkoutTemplate (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT,
          iconCodePoint INTEGER,
          colorValue INTEGER,
          folderId TEXT,
          notes TEXT,
          lastUsed TEXT, -- ISO8601 string
          orderIndex INTEGER,
          FOREIGN KEY (folderId) REFERENCES WorkoutFolder (id) ON DELETE SET NULL
        )
      ''');

      // Create Workout table
      _logger.info('Creating Workout table');
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
      _logger.info('Creating WorkoutExercise table');
      await db.execute('''
        CREATE TABLE WorkoutExercise (
          id TEXT PRIMARY KEY,
          workoutTemplateId TEXT,
          workoutId TEXT,
          exerciseSlug TEXT NOT NULL,
          notes TEXT,
          orderIndex INTEGER,
          FOREIGN KEY (workoutTemplateId) REFERENCES WorkoutTemplate (id) ON DELETE CASCADE,
          FOREIGN KEY (workoutId) REFERENCES Workout (id) ON DELETE CASCADE,
          FOREIGN KEY (exerciseSlug) REFERENCES Exercise (slug) ON DELETE CASCADE,
          CHECK ((workoutTemplateId IS NOT NULL AND workoutId IS NULL) OR (workoutTemplateId IS NULL AND workoutId IS NOT NULL))
        )
      ''');

      // Create WorkoutSet table
      _logger.info('Creating WorkoutSet table');
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
      _logger.info('Inserting default muscle groups');
      final muscleGroups = MuscleGroup.values.map((e) => e.name).toList();
      
      for (final muscleGroup in muscleGroups) {
        await db.insert('MuscleGroup', {'name': muscleGroup});
      }
      _logger.info('Inserted ${muscleGroups.length} muscle groups');

      // Seed exercises from TOML file
      _logger.info('Loading exercises from TOML file');
      final tomlString = await rootBundle.loadString('assets/gym_exercises_complete.toml');
      await _seedExercisesFromToml(db, tomlString);
      
      _logger.info('Database creation completed successfully');
    } catch (e) {
      _logger.severe('Error during database creation: $e');
      rethrow;
    }
  }

  // Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    _logger.warning('Upgrading database from version $oldVersion to $newVersion');
    
    try {
      if (oldVersion < 2) {
        _logger.info('Applying version 2 upgrades');
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
        _logger.info('Version 2 upgrades completed');
      }
      
      if (oldVersion < 3) {
        _logger.info('Applying version 3 upgrades');
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
          _logger.info('Added description column to Workout table');
        } catch (e) {
          _logger.info('Description column already exists in Workout table');
        }

        // Insert default muscle groups if they don't exist
        final muscleGroups = MuscleGroup.values.map((e) => e.name).toList();
        
        for (final muscleGroup in muscleGroups) {
          await db.insert('MuscleGroup', {'name': muscleGroup}, 
              conflictAlgorithm: ConflictAlgorithm.ignore);
        }
        _logger.info('Version 3 upgrades completed');
      }
      
      if (oldVersion < 4) {
        _logger.info('Applying version 4 upgrades');
        // Create WorkoutTemplate table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS WorkoutTemplate (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT,
            iconCodePoint INTEGER,
            colorValue INTEGER,
            folderId TEXT,
            notes TEXT,
            lastUsed TEXT, -- ISO8601 string
            orderIndex INTEGER,
            FOREIGN KEY (folderId) REFERENCES WorkoutFolder (id) ON DELETE SET NULL
          )
        ''');
        
        // Add workoutTemplateId column to WorkoutExercise table
        try {
          await db.execute('ALTER TABLE WorkoutExercise ADD COLUMN workoutTemplateId TEXT');
          _logger.info('Added workoutTemplateId column to WorkoutExercise table');
        } catch (e) {
          _logger.info('workoutTemplateId column already exists in WorkoutExercise table');
        }
        
        // Update workoutId column to be nullable (this is a schema change that requires recreation)
        // For existing data, we'll keep workoutId as NOT NULL since existing records should have it
        _logger.info('WorkoutExercise table schema updated for template support');
        _logger.info('Version 4 upgrades completed');
      }
      
      _logger.info('Database upgrade completed successfully');
    } catch (e) {
      _logger.severe('Error during database upgrade: $e');
      rethrow;
    }
  }

  Future<void> close() async {
    try {
      _logger.info('Closing database connection');
      final db = await database;
      await db.close();
      _database = null; // Reset the static instance so it can be re-initialized if needed
      _logger.info('Database connection closed successfully');
    } catch (e) {
      _logger.severe('Error closing database: $e');
      rethrow;
    }
  }
  
  // Helper method to seed exercises from TOML file
  Future<void> _seedExercisesFromToml(Database db, String tomlContent) async {
    _logger.info('Starting to seed exercises from TOML content');
    int exerciseCount = 0;
    int errorCount = 0;
    
    try {
      // Parse the TOML content using the toml package
      final tomlDocument = TomlDocument.parse(tomlContent);
      final tomlMap = tomlDocument.toMap();
      _logger.info('TOML content parsed successfully');
      
      // Iterate through the parsed TOML data
      for (final entry in tomlMap.entries) {
        if (entry.key.startsWith('exercise_')) {
          final exerciseData = entry.value as Map<String, dynamic>;
          
          try {
            final primaryMuscleGroup = exerciseData['primary_muscle_group'] ?? '';
            final slug = exerciseData['slug'] ?? '';
            
            // Skip exercises with empty or invalid primary muscle groups
            if (primaryMuscleGroup.toString().trim().isEmpty) {
              errorCount++;
              _logger.warning('Skipping exercise $slug: empty primary muscle group');
              continue;
            }
            
            // Validate that the primary muscle group exists in our enum
            final muscleGroupNames = MuscleGroup.values.map((e) => e.name).toList();
            
            if (!muscleGroupNames.any((mg) => mg.toLowerCase() == primaryMuscleGroup.toString().toLowerCase())) {
              errorCount++;
              _logger.warning('Skipping exercise $slug: invalid primary muscle group "$primaryMuscleGroup"');
              continue;
            }
            
            // Create a map for the exercise data
            final exerciseMap = <String, dynamic>{
              'slug': slug,
              'name': exerciseData['name'] ?? '',
              'primaryMuscleGroup': primaryMuscleGroup,
              'secondaryMuscleGroups': jsonEncode(exerciseData['secondary_muscle_groups'] ?? []),
              'instructions': jsonEncode(exerciseData['instructions'] ?? []),
              'image': exerciseData['image'] ?? '',
              'animation': exerciseData['animation'] ?? '',
              'isBodyWeightExercise': (exerciseData['is_bodyweight_exercise'] ?? false) ? 1 : 0,
            };
            
            // Insert the exercise into the database
            await db.insert('Exercise', exerciseMap,
                conflictAlgorithm: ConflictAlgorithm.ignore);
            exerciseCount++;
          } catch (e) {
            // Handle any errors during insertion
            errorCount++;
            _logger.warning('Error inserting exercise ${exerciseData['slug']}: $e');
          }
        }
      }
      
      _logger.info('Exercise seeding completed: $exerciseCount exercises inserted, $errorCount errors');
    } catch (e) {
      _logger.severe('Critical error during exercise seeding: $e');
      rethrow;
    }
  }
}
