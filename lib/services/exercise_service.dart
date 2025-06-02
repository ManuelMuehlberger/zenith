import 'package:flutter/services.dart';
import 'package:toml/toml.dart';
import '../models/exercise.dart';

class ExerciseService {
  static final ExerciseService _instance = ExerciseService._internal();
  factory ExerciseService() => _instance;
  ExerciseService._internal();
  
  static ExerciseService get instance => _instance;

  List<Exercise> _exercises = [];
  List<Exercise> get exercises => _exercises;

  Future<void> loadExercises() async {
    try {
      final String tomlString = await rootBundle.loadString('assets/gym_exercises_complete.toml');
      final Map<String, dynamic> tomlData = TomlDocument.parse(tomlString).toMap();
      
      _exercises = [];
      
      // Parse exercises from TOML - each exercise is a separate section
      for (final entry in tomlData.entries) {
        if (entry.value is Map<String, dynamic>) {
          final exerciseData = entry.value as Map<String, dynamic>;
          
          final exerciseMap = {
            'slug': exerciseData['slug'] ?? entry.key,
            'name': exerciseData['name'] ?? '',
            'primary_muscle_group': exerciseData['primary_muscle_group'] ?? '',
            'secondary_muscle_groups': exerciseData['secondary_muscle_groups'] ?? [],
            'instructions': exerciseData['instructions'] ?? [],
            'image': exerciseData['image'] ?? '',
            'animation': exerciseData['animation'] ?? '',
          };
          
          _exercises.add(Exercise.fromMap(exerciseMap));
        }
      }
      
    } catch (e) {
      _exercises = [];
    }
  }

  List<Exercise> searchExercises(String query) {
    if (query.isEmpty) return _exercises;
    
    return _exercises.where((exercise) {
      return exercise.name.toLowerCase().contains(query.toLowerCase()) ||
             exercise.primaryMuscleGroup.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  List<Exercise> filterByMuscleGroup(String muscleGroup) {
    if (muscleGroup.isEmpty) return _exercises;
    
    return _exercises.where((exercise) {
      return exercise.primaryMuscleGroup.toLowerCase() == muscleGroup.toLowerCase();
    }).toList();
  }

  List<String> get allMuscleGroups {
    final Set<String> muscleGroups = {};
    for (final exercise in _exercises) {
      muscleGroups.add(exercise.primaryMuscleGroup);
    }
    return muscleGroups.toList()..sort();
  }
}
