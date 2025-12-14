import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/workout_template.dart';
import 'package:zenith/services/dao/workout_template_dao.dart';

void main() {
  group('WorkoutTemplateDao', () {
    late WorkoutTemplateDao dao;

    setUp(() {
      dao = WorkoutTemplateDao();
    });

    test('should have correct table name', () {
      expect(dao.tableName, 'WorkoutTemplate');
    });

    test('should convert workout template to map', () {
      final now = DateTime.now();
      final template = WorkoutTemplate(
        id: 'template123',
        name: 'Push Day',
        description: 'Focus on push exercises',
        iconCodePoint: 0xe1a3,
        colorValue: 0xFF2196F3,
        folderId: 'folder123',
        notes: 'Warm up properly',
        lastUsed: now.toIso8601String(),
        orderIndex: 1,
      );

      final map = dao.toMap(template);

      expect(map['id'], 'template123');
      expect(map['name'], 'Push Day');
      expect(map['description'], 'Focus on push exercises');
      expect(map['iconCodePoint'], 0xe1a3);
      expect(map['colorValue'], 0xFF2196F3);
      expect(map['folderId'], 'folder123');
      expect(map['notes'], 'Warm up properly');
      expect(map['lastUsed'], now.toIso8601String());
      expect(map['orderIndex'], 1);
    });

    test('should convert map to workout template', () {
      final now = DateTime.now();
      final map = {
        'id': 'template456',
        'name': 'Pull Day',
        'description': 'Focus on pull exercises',
        'iconCodePoint': 0xe531,
        'colorValue': 0xFF4CAF50,
        'folderId': 'folder456',
        'notes': 'Focus on form',
        'lastUsed': now.toIso8601String(),
        'orderIndex': 2,
      };

      final template = dao.fromMap(map);

      expect(template.id, 'template456');
      expect(template.name, 'Pull Day');
      expect(template.description, 'Focus on pull exercises');
      expect(template.iconCodePoint, 0xe531);
      expect(template.colorValue, 0xFF4CAF50);
      expect(template.folderId, 'folder456');
      expect(template.notes, 'Focus on form');
      expect(template.lastUsed, now.toIso8601String());
      expect(template.orderIndex, 2);
    });

    test('should handle null values in map conversion', () {
      final map = {
        'id': 'template789',
        'name': 'Minimal Template',
        'description': null,
        'iconCodePoint': null,
        'colorValue': null,
        'folderId': null,
        'notes': null,
        'lastUsed': null,
        'orderIndex': null,
      };

      final template = dao.fromMap(map);

      expect(template.id, 'template789');
      expect(template.name, 'Minimal Template');
      expect(template.description, isNull);
      expect(template.iconCodePoint, isNull);
      expect(template.colorValue, isNull);
      expect(template.folderId, isNull);
      expect(template.notes, isNull);
      expect(template.lastUsed, isNull);
      expect(template.orderIndex, isNull);
    });

    test('should convert template with null values to map', () {
      final template = WorkoutTemplate(
        id: 'template999',
        name: 'Simple Template',
      );

      final map = dao.toMap(template);

      expect(map['id'], 'template999');
      expect(map['name'], 'Simple Template');
      expect(map['description'], isNull);
      expect(map['iconCodePoint'], isNull);
      expect(map['colorValue'], isNull);
      expect(map['folderId'], isNull);
      expect(map['notes'], isNull);
      expect(map['lastUsed'], isNull);
      expect(map['orderIndex'], isNull);
    });

    test('should handle template with all fields populated', () {
      final now = DateTime.now();
      final template = WorkoutTemplate(
        id: 'full-template',
        name: 'Complete Workout',
        description: 'Full body workout with all muscle groups',
        iconCodePoint: 0xe52f,
        colorValue: 0xFFF44336,
        folderId: 'strength-folder',
        notes: 'Progressive overload focus',
        lastUsed: now.toIso8601String(),
        orderIndex: 5,
      );

      final map = dao.toMap(template);
      final reconstructed = dao.fromMap(map);

      expect(reconstructed.id, template.id);
      expect(reconstructed.name, template.name);
      expect(reconstructed.description, template.description);
      expect(reconstructed.iconCodePoint, template.iconCodePoint);
      expect(reconstructed.colorValue, template.colorValue);
      expect(reconstructed.folderId, template.folderId);
      expect(reconstructed.notes, template.notes);
      expect(reconstructed.lastUsed, template.lastUsed);
      expect(reconstructed.orderIndex, template.orderIndex);
    });

    test('should handle empty string values', () {
      final template = WorkoutTemplate(
        id: 'empty-template',
        name: '',
        description: '',
        notes: '',
        folderId: '',
        lastUsed: '',
      );

      final map = dao.toMap(template);
      final reconstructed = dao.fromMap(map);

      expect(reconstructed.name, '');
      expect(reconstructed.description, '');
      expect(reconstructed.notes, '');
      expect(reconstructed.folderId, '');
      expect(reconstructed.lastUsed, '');
    });

    test('should handle special characters in string fields', () {
      final template = WorkoutTemplate(
        id: 'special-template',
        name: 'Übung für Körper 💪',
        description: 'Spécial entraînement avec caractères accentués',
        notes: 'Notes with symbols: @#\$%^&*()',
        folderId: 'folder-with-dashes_and_underscores',
      );

      final map = dao.toMap(template);
      final reconstructed = dao.fromMap(map);

      expect(reconstructed.name, template.name);
      expect(reconstructed.description, template.description);
      expect(reconstructed.notes, template.notes);
      expect(reconstructed.folderId, template.folderId);
    });

    test('should handle very long string values', () {
      const longName = 'This is a very long workout template name that exceeds normal length expectations and contains many words';
      const longDescription = 'This is an extremely long description that contains multiple sentences and provides extensive detail about the workout template, including information about exercises, sets, reps, rest periods, progression schemes, and other important training variables that users should be aware of when following this particular workout routine.';
      const longNotes = 'These are very detailed notes that include specific instructions, modifications, safety considerations, equipment requirements, and other important information that trainers and athletes need to know.';

      final template = WorkoutTemplate(
        id: 'long-template',
        name: longName,
        description: longDescription,
        notes: longNotes,
      );

      final map = dao.toMap(template);
      final reconstructed = dao.fromMap(map);

      expect(reconstructed.name, longName);
      expect(reconstructed.description, longDescription);
      expect(reconstructed.notes, longNotes);
    });

    test('should handle extreme numeric values', () {
      final template = WorkoutTemplate(
        id: 'extreme-template',
        name: 'Extreme Values',
        iconCodePoint: 0xFFFFFF, // Maximum value
        colorValue: 0xFFFFFFFF, // Maximum color value
        orderIndex: -999999, // Very negative order
      );

      final map = dao.toMap(template);
      final reconstructed = dao.fromMap(map);

      expect(reconstructed.iconCodePoint, 0xFFFFFF);
      expect(reconstructed.colorValue, 0xFFFFFFFF);
      expect(reconstructed.orderIndex, -999999);
    });

    test('should handle zero values for numeric fields', () {
      final template = WorkoutTemplate(
        id: 'zero-template',
        name: 'Zero Values',
        iconCodePoint: 0,
        colorValue: 0,
        orderIndex: 0,
      );

      final map = dao.toMap(template);
      final reconstructed = dao.fromMap(map);

      expect(reconstructed.iconCodePoint, 0);
      expect(reconstructed.colorValue, 0);
      expect(reconstructed.orderIndex, 0);
    });

    test('should handle ISO8601 timestamp formats', () {
      final timestamps = [
        DateTime.now().toIso8601String(),
        DateTime.utc(2023, 1, 1, 12, 0, 0).toIso8601String(),
        DateTime.utc(2023, 12, 31, 23, 59, 59, 999).toIso8601String(),
      ];

      for (final timestamp in timestamps) {
        final template = WorkoutTemplate(
          id: 'timestamp-template',
          name: 'Timestamp Test',
          lastUsed: timestamp,
        );

        final map = dao.toMap(template);
        final reconstructed = dao.fromMap(map);

        expect(reconstructed.lastUsed, timestamp);
        
        // Verify the timestamp can be parsed back to DateTime
        final parsedDate = DateTime.parse(reconstructed.lastUsed!);
        expect(parsedDate, isA<DateTime>());
      }
    });

    test('should preserve data integrity through multiple conversions', () {
      final now = DateTime.now();
      final originalTemplate = WorkoutTemplate(
        id: 'integrity-test',
        name: 'Data Integrity Test',
        description: 'Testing data preservation',
        iconCodePoint: 0xe1a3,
        colorValue: 0xFF2196F3,
        folderId: 'test-folder',
        notes: 'Important notes',
        lastUsed: now.toIso8601String(),
        orderIndex: 42,
      );

      // Convert to map and back multiple times
      var template = originalTemplate;
      for (int i = 0; i < 5; i++) {
        final map = dao.toMap(template);
        template = dao.fromMap(map);
      }

      // Verify all data is preserved
      expect(template.id, originalTemplate.id);
      expect(template.name, originalTemplate.name);
      expect(template.description, originalTemplate.description);
      expect(template.iconCodePoint, originalTemplate.iconCodePoint);
      expect(template.colorValue, originalTemplate.colorValue);
      expect(template.folderId, originalTemplate.folderId);
      expect(template.notes, originalTemplate.notes);
      expect(template.lastUsed, originalTemplate.lastUsed);
      expect(template.orderIndex, originalTemplate.orderIndex);
    });

    test('should handle mixed null and non-null values', () {
      final template = WorkoutTemplate(
        id: 'mixed-template',
        name: 'Mixed Values',
        description: null,
        iconCodePoint: 0xe1a3,
        colorValue: null,
        folderId: 'folder123',
        notes: null,
        lastUsed: DateTime.now().toIso8601String(),
        orderIndex: null,
      );

      final map = dao.toMap(template);
      final reconstructed = dao.fromMap(map);

      expect(reconstructed.id, 'mixed-template');
      expect(reconstructed.name, 'Mixed Values');
      expect(reconstructed.description, isNull);
      expect(reconstructed.iconCodePoint, 0xe1a3);
      expect(reconstructed.colorValue, isNull);
      expect(reconstructed.folderId, 'folder123');
      expect(reconstructed.notes, isNull);
      expect(reconstructed.lastUsed, isNotNull);
      expect(reconstructed.orderIndex, isNull);
    });

    test('should handle templates with different folder associations', () {
      final templates = [
        WorkoutTemplate(name: 'No Folder', folderId: null),
        WorkoutTemplate(name: 'Strength Folder', folderId: 'strength'),
        WorkoutTemplate(name: 'Cardio Folder', folderId: 'cardio'),
        WorkoutTemplate(name: 'Empty Folder', folderId: ''),
      ];

      for (final template in templates) {
        final map = dao.toMap(template);
        final reconstructed = dao.fromMap(map);
        expect(reconstructed.folderId, template.folderId);
      }
    });

    test('should handle templates with different order indices', () {
      final orderIndices = [null, -100, -1, 0, 1, 100, 999999];

      for (final orderIndex in orderIndices) {
        final template = WorkoutTemplate(
          name: 'Order Test',
          orderIndex: orderIndex,
        );

        final map = dao.toMap(template);
        final reconstructed = dao.fromMap(map);
        expect(reconstructed.orderIndex, orderIndex);
      }
    });

    test('should maintain type safety for all fields', () {
      final template = WorkoutTemplate(
        id: 'type-test',
        name: 'Type Safety Test',
        description: 'Testing types',
        iconCodePoint: 0xe1a3,
        colorValue: 0xFF2196F3,
        folderId: 'folder',
        notes: 'Notes',
        lastUsed: DateTime.now().toIso8601String(),
        orderIndex: 1,
      );

      final map = dao.toMap(template);

      expect(map['id'], isA<String>());
      expect(map['name'], isA<String>());
      expect(map['description'], isA<String>());
      expect(map['iconCodePoint'], isA<int>());
      expect(map['colorValue'], isA<int>());
      expect(map['folderId'], isA<String>());
      expect(map['notes'], isA<String>());
      expect(map['lastUsed'], isA<String>());
      expect(map['orderIndex'], isA<int>());
    });
  });
}
