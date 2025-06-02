# Workout Tracker Export/Import Data Specification

## Version: alpha0.1.0
## Date: 2025-05-28

## Overview

This document defines the specification for exporting and importing user data in the Workout Tracker application.

## Data Format

### Primary Format: JSON
- **File Extension**: `.json`
- **MIME Type**: `application/json`
- **Encoding**: UTF-8

## File Structure

```json
{
  "metadata": {
    "version": "1.0.0",
    "format": "json",
    "exportDate": "2025-05-28T22:37:00.000Z",
    "appVersion": "1.0.0",
    "deviceInfo": {
      "platform": "android|ios",
      "osVersion": "string",
      "appBuild": "string"
    },
    "dataIntegrity": {
      "checksum": "sha256_hash",
      "recordCount": {
        "userProfile": 1,
        "workoutFolders": 0,
        "workouts": 0,
        "exercises": 0,
        "workoutSessions": 0
      }
    },
    "exportOptions": {
      "includePersonalData": true,
      "includeWorkoutHistory": true,
      "includeCustomExercises": true,
      "dateRange": {
        "from": "2025-01-01T00:00:00.000Z",
        "to": "2025-05-28T23:59:59.999Z"
      }
    }
  },
  "data": {
    "userProfile": {...},
    "workoutFolders": [...],
    "workouts": [...],
    "exercises": [...],
    "workoutSessions": [...],
    "customExercises": [...],
    "preferences": {...}
  }
}
```

## Data Schemas

### 1. User Profile Schema

```json
{
  "userProfile": {
    "name": "string",
    "age": "integer",
    "units": "metric|imperial",
    "weight": "number",
    "createdAt": "ISO8601_datetime"
  }
}
```

### 2. Workout Folders Schema

```json
{
  "workoutFolders": [
    {
      "id": "string",
      "name": "string",
      "createdAt": "ISO8601_datetime",
      "updatedAt": "ISO8601_datetime"
    }
  ]
}
```

### 3. Workouts Schema

```json
{
  "workouts": [
    {
      "id": "string",
      "name": "string",
      "folderId": "string|null",
      "createdAt": "ISO8601_datetime",
      "updatedAt": "ISO8601_datetime",
      "iconCodePoint": "integer",
      "colorValue": "integer",
      "exercises": [
        {
          "id": "string",
          "exercise": {
            "slug": "string",
            "name": "string",
            "primaryMuscleGroup": "string",
            "secondaryMuscleGroups": ["string"],
            "instructions": ["string"],
            "image": "string",
            "animation": "string"
          },
          "sets": [
            {
              "id": "string",
              "reps": "integer",
              "weight": "number",
              "isCompleted": "boolean",
              "restTime": "integer|null",
              "notes": "string|null"
            }
          ],
          "notes": "string"
        }
      ]
    }
  ]
}
```

### 4. Workout Sessions Schema

```json
{
  "workoutSessions": [
    {
      "id": "string",
      "workoutId": "string",
      "workoutSnapshot": {...}, // Full workout data at time of session
      "startTime": "ISO8601_datetime",
      "endTime": "ISO8601_datetime|null",
      "isCompleted": "boolean",
      "notes": "string|null",
      "mood": "integer|null", // 0-4 representing WorkoutMood enum
      "exercises": [
        {
          "id": "string",
          "workoutExerciseId": "string",
          "sets": [
            {
              "id": "string",
              "reps": "integer",
              "weight": "number",
              "isCompleted": "boolean",
              "completedAt": "ISO8601_datetime|null"
            }
          ]
        }
      ]
    }
  ]
}
```

### 5. Custom Exercises Schema

```json
{
  "customExercises": [
    {
      "slug": "string",
      "name": "string",
      "primaryMuscleGroup": "string",
      "secondaryMuscleGroups": ["string"],
      "instructions": ["string"],
      "image": "string|null",
      "animation": "string|null",
      "isCustom": true,
      "createdAt": "ISO8601_datetime",
      "createdBy": "user"
    }
  ]
}
```

### 6. App Preferences Schema

```json
{
  "preferences": {
    "theme": "light|dark|system",
    "defaultRestTime": "integer",
    "autoStartTimer": "boolean",
    "soundEnabled": "boolean",
    "vibrationEnabled": "boolean",
    "reminderSettings": {
      "enabled": "boolean",
      "days": ["monday", "tuesday", ...],
      "time": "HH:mm"
    }
  }
}
```
