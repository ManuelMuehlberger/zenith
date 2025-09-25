import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/workout_template.dart';

void main() {
  group('WorkoutTemplate', () {
    late WorkoutTemplate workoutTemplate;

    setUp(() {
      workoutTemplate = WorkoutTemplate(
        name: 'Test Template',
        description: 'A test workout template',
        iconCodePoint: 0xe1a3,
        colorValue: 0xFF2196F3,
        notes: 'Test notes',
      );
    });

    test('should create a workout template with default values', () {
      expect(workoutTemplate.id, isNotNull);
      expect(workoutTemplate.name, 'Test Template');
      expect(workoutTemplate.description, 'A test workout template');
      expect(workoutTemplate.iconCodePoint, 0xe1a3);
      expect(workoutTemplate.colorValue, 0xFF2196F3);
      expect(workoutTemplate.folderId, isNull);
      expect(workoutTemplate.notes, 'Test notes');
      expect(workoutTemplate.lastUsed, isNull);
      expect(workoutTemplate.orderIndex, isNull);
    });

    test('should create a workout template with all parameters', () {
      final now = DateTime.now();
      final template = WorkoutTemplate(
        id: 'template-123',
        name: 'Full Template',
        description: 'Complete template',
        iconCodePoint: 0xe531,
        colorValue: 0xFF4CAF50,
        folderId: 'folder-456',
        notes: 'Complete notes',
        lastUsed: now.toIso8601String(),
        orderIndex: 5,
      );

      expect(template.id, 'template-123');
      expect(template.name, 'Full Template');
      expect(template.description, 'Complete template');
      expect(template.iconCodePoint, 0xe531);
      expect(template.colorValue, 0xFF4CAF50);
      expect(template.folderId, 'folder-456');
      expect(template.notes, 'Complete notes');
      expect(template.lastUsed, now.toIso8601String());
      expect(template.orderIndex, 5);
    });

    test('should create a workout template from map', () {
      final now = DateTime.now();
      final map = {
        'id': 'template-id',
        'name': 'Test Template',
        'description': 'A test workout template',
        'iconCodePoint': 0xe1a3,
        'colorValue': 0xFF2196F3,
        'folderId': 'folder-id',
        'notes': 'Test notes',
        'lastUsed': now.toIso8601String(),
        'orderIndex': 1,
      };

      final templateFromMap = WorkoutTemplate.fromMap(map);

      expect(templateFromMap.id, 'template-id');
      expect(templateFromMap.name, 'Test Template');
      expect(templateFromMap.description, 'A test workout template');
      expect(templateFromMap.iconCodePoint, 0xe1a3);
      expect(templateFromMap.colorValue, 0xFF2196F3);
      expect(templateFromMap.folderId, 'folder-id');
      expect(templateFromMap.notes, 'Test notes');
      expect(templateFromMap.lastUsed, now.toIso8601String());
      expect(templateFromMap.orderIndex, 1);
    });

    test('should create a workout template from map with null values', () {
      final map = {
        'id': 'template-id',
        'name': 'Minimal Template',
        'description': null,
        'iconCodePoint': null,
        'colorValue': null,
        'folderId': null,
        'notes': null,
        'lastUsed': null,
        'orderIndex': null,
      };

      final templateFromMap = WorkoutTemplate.fromMap(map);

      expect(templateFromMap.id, 'template-id');
      expect(templateFromMap.name, 'Minimal Template');
      expect(templateFromMap.description, isNull);
      expect(templateFromMap.iconCodePoint, isNull);
      expect(templateFromMap.colorValue, isNull);
      expect(templateFromMap.folderId, isNull);
      expect(templateFromMap.notes, isNull);
      expect(templateFromMap.lastUsed, isNull);
      expect(templateFromMap.orderIndex, isNull);
    });

    test('should convert workout template to map', () {
      final now = DateTime.now();
      final template = workoutTemplate.copyWith(
        folderId: 'folder-id',
        lastUsed: now.toIso8601String(),
        orderIndex: 2,
      );

      final map = template.toMap();

      expect(map['id'], template.id);
      expect(map['name'], 'Test Template');
      expect(map['description'], 'A test workout template');
      expect(map['iconCodePoint'], 0xe1a3);
      expect(map['colorValue'], 0xFF2196F3);
      expect(map['folderId'], 'folder-id');
      expect(map['notes'], 'Test notes');
      expect(map['lastUsed'], now.toIso8601String());
      expect(map['orderIndex'], 2);
    });

    test('should convert workout template to map with null values', () {
      final template = WorkoutTemplate(name: 'Minimal Template');
      final map = template.toMap();

      expect(map['id'], template.id);
      expect(map['name'], 'Minimal Template');
      expect(map['description'], isNull);
      expect(map['iconCodePoint'], isNull);
      expect(map['colorValue'], isNull);
      expect(map['folderId'], isNull);
      expect(map['notes'], isNull);
      expect(map['lastUsed'], isNull);
      expect(map['orderIndex'], isNull);
    });

    test('should copy with new values', () {
      final now = DateTime.now();
      final copiedTemplate = workoutTemplate.copyWith(
        name: 'Copied Template',
        description: 'Updated description',
        folderId: 'new-folder',
        lastUsed: now.toIso8601String(),
        orderIndex: 10,
      );

      expect(copiedTemplate.name, 'Copied Template');
      expect(copiedTemplate.description, 'Updated description');
      expect(copiedTemplate.folderId, 'new-folder');
      expect(copiedTemplate.lastUsed, now.toIso8601String());
      expect(copiedTemplate.orderIndex, 10);
      // Other values should remain the same
      expect(copiedTemplate.id, workoutTemplate.id);
      expect(copiedTemplate.iconCodePoint, workoutTemplate.iconCodePoint);
      expect(copiedTemplate.colorValue, workoutTemplate.colorValue);
      expect(copiedTemplate.notes, workoutTemplate.notes);
    });

    test('should copy with null values using undefined sentinel', () {
      final template = workoutTemplate.copyWith(
        description: 'Initial description',
        folderId: 'initial-folder',
        notes: 'Initial notes',
      );

      // Now copy with null values
      final copiedTemplate = template.copyWith(
        description: null,
        folderId: null,
        notes: null,
        lastUsed: null,
        orderIndex: null,
      );

      expect(copiedTemplate.description, isNull);
      expect(copiedTemplate.folderId, isNull);
      expect(copiedTemplate.notes, isNull);
      expect(copiedTemplate.lastUsed, isNull);
      expect(copiedTemplate.orderIndex, isNull);
      // Other values should remain the same
      expect(copiedTemplate.name, template.name);
      expect(copiedTemplate.iconCodePoint, template.iconCodePoint);
      expect(copiedTemplate.colorValue, template.colorValue);
    });

    test('should preserve values when copying without changes', () {
      final copiedTemplate = workoutTemplate.copyWith();

      expect(copiedTemplate.id, workoutTemplate.id);
      expect(copiedTemplate.name, workoutTemplate.name);
      expect(copiedTemplate.description, workoutTemplate.description);
      expect(copiedTemplate.iconCodePoint, workoutTemplate.iconCodePoint);
      expect(copiedTemplate.colorValue, workoutTemplate.colorValue);
      expect(copiedTemplate.folderId, workoutTemplate.folderId);
      expect(copiedTemplate.notes, workoutTemplate.notes);
      expect(copiedTemplate.lastUsed, workoutTemplate.lastUsed);
      expect(copiedTemplate.orderIndex, workoutTemplate.orderIndex);
    });

    test('should generate unique IDs for different templates', () {
      final template1 = WorkoutTemplate(name: 'Template 1');
      final template2 = WorkoutTemplate(name: 'Template 2');

      expect(template1.id, isNot(equals(template2.id)));
      expect(template1.id, isNotEmpty);
      expect(template2.id, isNotEmpty);
    });

    test('should accept custom ID in constructor', () {
      const customId = 'custom-template-id';
      final template = WorkoutTemplate(
        id: customId,
        name: 'Custom ID Template',
      );

      expect(template.id, customId);
    });

    test('should handle different icon code points', () {
      final templates = [
        WorkoutTemplate(name: 'Fitness', iconCodePoint: 0xe1a3),
        WorkoutTemplate(name: 'Running', iconCodePoint: 0xe02f),
        WorkoutTemplate(name: 'Swimming', iconCodePoint: 0xe047),
        WorkoutTemplate(name: 'Sports', iconCodePoint: 0xe52f),
        WorkoutTemplate(name: 'Gymnastics', iconCodePoint: 0xe531),
      ];

      expect(templates[0].iconCodePoint, 0xe1a3);
      expect(templates[1].iconCodePoint, 0xe02f);
      expect(templates[2].iconCodePoint, 0xe047);
      expect(templates[3].iconCodePoint, 0xe52f);
      expect(templates[4].iconCodePoint, 0xe531);
    });

    test('should handle different color values', () {
      final templates = [
        WorkoutTemplate(name: 'Blue', colorValue: 0xFF2196F3),
        WorkoutTemplate(name: 'Green', colorValue: 0xFF4CAF50),
        WorkoutTemplate(name: 'Red', colorValue: 0xFFF44336),
        WorkoutTemplate(name: 'Purple', colorValue: 0xFF9C27B0),
        WorkoutTemplate(name: 'Orange', colorValue: 0xFFFF9800),
      ];

      expect(templates[0].colorValue, 0xFF2196F3);
      expect(templates[1].colorValue, 0xFF4CAF50);
      expect(templates[2].colorValue, 0xFFF44336);
      expect(templates[3].colorValue, 0xFF9C27B0);
      expect(templates[4].colorValue, 0xFFFF9800);
    });

    test('should handle long names and descriptions', () {
      const longName = 'This is a very long workout template name that exceeds normal length';
      const longDescription = 'This is a very long description for a workout template that contains '
          'multiple sentences and provides detailed information about the workout routine, '
          'including exercises, sets, reps, and other important details that users should know.';

      final template = WorkoutTemplate(
        name: longName,
        description: longDescription,
      );

      expect(template.name, longName);
      expect(template.description, longDescription);
    });

    test('should handle special characters in name and description', () {
      const specialName = 'Übung für Körper & Geist 💪';
      const specialDescription = 'Spécial entraînement avec caractères accentués: àáâãäåæçèéêë';

      final template = WorkoutTemplate(
        name: specialName,
        description: specialDescription,
      );

      expect(template.name, specialName);
      expect(template.description, specialDescription);
    });

    test('should handle empty strings', () {
      final template = WorkoutTemplate(
        name: '',
        description: '',
        notes: '',
      );

      expect(template.name, '');
      expect(template.description, '');
      expect(template.notes, '');
    });

    test('should handle ISO8601 timestamp format for lastUsed', () {
      final now = DateTime.now();
      final isoString = now.toIso8601String();
      
      final template = WorkoutTemplate(
        name: 'Timestamp Test',
        lastUsed: isoString,
      );

      expect(template.lastUsed, isoString);
      
      // Verify it can be parsed back to DateTime
      final parsedDate = DateTime.parse(template.lastUsed!);
      expect(parsedDate.year, now.year);
      expect(parsedDate.month, now.month);
      expect(parsedDate.day, now.day);
    });

    test('should handle negative and zero order indices', () {
      final templates = [
        WorkoutTemplate(name: 'Negative', orderIndex: -1),
        WorkoutTemplate(name: 'Zero', orderIndex: 0),
        WorkoutTemplate(name: 'Positive', orderIndex: 1),
      ];

      expect(templates[0].orderIndex, -1);
      expect(templates[1].orderIndex, 0);
      expect(templates[2].orderIndex, 1);
    });

    test('should maintain immutability of id field', () {
      final originalId = workoutTemplate.id;
      final copiedTemplate = workoutTemplate.copyWith(name: 'New Name');

      expect(workoutTemplate.id, originalId);
      expect(copiedTemplate.id, originalId);
    });

    test('should allow changing id through copyWith', () {
      const newId = 'new-template-id';
      final copiedTemplate = workoutTemplate.copyWith(id: newId);

      expect(copiedTemplate.id, newId);
      expect(workoutTemplate.id, isNot(newId));
    });
  });
}
