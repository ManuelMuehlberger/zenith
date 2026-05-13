import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:zenith/services/database_helper.dart';
import 'package:zenith/services/export_import_service.dart';

class MockDatabase extends Mock implements Database {}

class FakeDatabaseHelper implements DatabaseHelper {
  FakeDatabaseHelper({
    required this.databasePathValue,
    Database? databaseInstance,
  }) : _databaseInstance = databaseInstance ?? MockDatabase();

  final String databasePathValue;
  final Database _databaseInstance;

  int closeCallCount = 0;
  int databaseAccessCount = 0;
  bool throwOnDatabaseAccess = false;
  Object databaseAccessError = StateError('database open failed');

  @override
  Future<void> close() async {
    closeCallCount++;
  }

  @override
  Future<Database> get database async {
    databaseAccessCount++;
    if (throwOnDatabaseAccess) {
      throw databaseAccessError;
    }
    return _databaseInstance;
  }

  @override
  Future<String> get databasePath async => databasePathValue;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ExportImportService', () {
    late Directory sandboxDir;
    late Directory exportDir;

    setUp(() async {
      sandboxDir = Directory('test/services/export_import_service_test_data');
      if (await sandboxDir.exists()) {
        await sandboxDir.delete(recursive: true);
      }
      await sandboxDir.create(recursive: true);
      exportDir = Directory('${sandboxDir.path}/exports');
      await exportDir.create(recursive: true);
    });

    tearDown(() async {
      if (await sandboxDir.exists()) {
        await sandboxDir.delete(recursive: true);
      }
    });

    File writeFile(String relativePath, String contents) {
      final file = File('${sandboxDir.path}/$relativePath');
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(contents);
      return file;
    }

    ExportImportService buildService({
      required FakeDatabaseHelper databaseHelper,
      ShareFilesCallback? shareFiles,
      PickFilesCallback? pickFiles,
      DateTime Function()? nowProvider,
    }) {
      return ExportImportService.withDependencies(
        databaseHelper: databaseHelper,
        shareFiles: shareFiles,
        pickFiles: pickFiles,
        tempDirectoryProvider: () => exportDir,
        nowProvider: nowProvider,
      );
    }

    test(
      'exportData shares a timestamped backup copy and deletes it after sharing',
      () async {
        final dbFile = writeFile('workout_tracker.db', 'db-backup-data');
        final databaseHelper = FakeDatabaseHelper(
          databasePathValue: dbFile.path,
        );

        late List<XFile> sharedFiles;
        String? sharedSubject;

        final service = buildService(
          databaseHelper: databaseHelper,
          nowProvider: () => DateTime.fromMillisecondsSinceEpoch(1700000000000),
          shareFiles: (files, {subject}) async {
            sharedFiles = files;
            sharedSubject = subject;
            expect(
              await File(files.single.path).readAsString(),
              'db-backup-data',
            );
          },
        );

        await service.exportData();

        expect(sharedSubject, 'Zenith Workout Tracker Backup');
        expect(sharedFiles, hasLength(1));
        expect(
          sharedFiles.single.path.split(Platform.pathSeparator).last,
          'zenith_backup_1700000000000.db',
        );
        expect(File(sharedFiles.single.path).existsSync(), isFalse);
        expect(databaseHelper.closeCallCount, 1);
        expect(databaseHelper.databaseAccessCount, 1);
      },
    );

    test(
      'exportData throws when the database file is missing and reopens the database',
      () async {
        final missingPath = '${sandboxDir.path}/missing_database.db';
        final databaseHelper = FakeDatabaseHelper(
          databasePathValue: missingPath,
        );
        final service = buildService(databaseHelper: databaseHelper);

        await expectLater(
          service.exportData(),
          throwsA(
            isA<Exception>().having(
              (error) => error.toString(),
              'message',
              contains('Database file not found'),
            ),
          ),
        );

        expect(databaseHelper.closeCallCount, 0);
        expect(databaseHelper.databaseAccessCount, 1);
      },
    );

    test(
      'exportData rethrows sharing failures after reopening the database',
      () async {
        final dbFile = writeFile('workout_tracker.db', 'db-backup-data');
        final databaseHelper = FakeDatabaseHelper(
          databasePathValue: dbFile.path,
        );
        final shareError = StateError('share failed');

        final service = buildService(
          databaseHelper: databaseHelper,
          shareFiles: (files, {subject}) async {
            throw shareError;
          },
        );

        await expectLater(service.exportData(), throwsA(same(shareError)));

        expect(databaseHelper.closeCallCount, 1);
        expect(databaseHelper.databaseAccessCount, 2);
      },
    );

    test(
      'exportData surfaces the database reopen failure when cleanup also fails',
      () async {
        final dbFile = writeFile('workout_tracker.db', 'db-backup-data');
        final databaseHelper = FakeDatabaseHelper(
          databasePathValue: dbFile.path,
        );
        final shareError = StateError('share failed');

        final service = buildService(
          databaseHelper: databaseHelper,
          shareFiles: (files, {subject}) async {
            databaseHelper.throwOnDatabaseAccess = true;
            throw shareError;
          },
        );

        await expectLater(
          service.exportData(),
          throwsA(same(databaseHelper.databaseAccessError)),
        );

        expect(databaseHelper.closeCallCount, 1);
        expect(databaseHelper.databaseAccessCount, 2);
      },
    );

    test('importData returns false when the picker is cancelled', () async {
      final databaseHelper = FakeDatabaseHelper(
        databasePathValue: '${sandboxDir.path}/workout_tracker.db',
      );

      final service = buildService(
        databaseHelper: databaseHelper,
        pickFiles: ({required type, required allowMultiple}) async {
          expect(type, FileType.any);
          expect(allowMultiple, isFalse);
          return null;
        },
      );

      final imported = await service.importData();

      expect(imported, isFalse);
      expect(databaseHelper.closeCallCount, 0);
      expect(databaseHelper.databaseAccessCount, 0);
    });

    test('importData returns false when the picker returns no files', () async {
      final databaseHelper = FakeDatabaseHelper(
        databasePathValue: '${sandboxDir.path}/workout_tracker.db',
      );

      final service = buildService(
        databaseHelper: databaseHelper,
        pickFiles: ({required type, required allowMultiple}) async {
          return const FilePickerResult([]);
        },
      );

      final imported = await service.importData();

      expect(imported, isFalse);
      expect(databaseHelper.closeCallCount, 0);
      expect(databaseHelper.databaseAccessCount, 0);
    });

    test(
      'importData overwrites the database with the selected backup file',
      () async {
        final dbFile = writeFile('workout_tracker.db', 'old-db-data');
        final importFile = writeFile('backup.db', 'new-db-data');
        final databaseHelper = FakeDatabaseHelper(
          databasePathValue: dbFile.path,
        );

        final service = buildService(
          databaseHelper: databaseHelper,
          pickFiles: ({required type, required allowMultiple}) async {
            return FilePickerResult([
              PlatformFile(
                path: importFile.path,
                name: 'backup.db',
                size: importFile.lengthSync(),
              ),
            ]);
          },
        );

        final imported = await service.importData();

        expect(imported, isTrue);
        expect(await dbFile.readAsString(), 'new-db-data');
        expect(databaseHelper.closeCallCount, 1);
        expect(databaseHelper.databaseAccessCount, 1);
      },
    );

    test(
      'importData rethrows malformed picker results with a null path',
      () async {
        final databaseHelper = FakeDatabaseHelper(
          databasePathValue: '${sandboxDir.path}/workout_tracker.db',
        );

        final service = buildService(
          databaseHelper: databaseHelper,
          pickFiles: ({required type, required allowMultiple}) async {
            return FilePickerResult([
              PlatformFile(path: null, name: 'broken.db', size: 0),
            ]);
          },
        );

        await expectLater(
          service.importData(),
          throwsA(
            predicate<Object>(
              (error) => error.toString().contains(
                'Null check operator used on a null value',
              ),
            ),
          ),
        );

        expect(databaseHelper.closeCallCount, 0);
        expect(databaseHelper.databaseAccessCount, 1);
      },
    );

    test(
      'importData rethrows copy failures after reopening the database',
      () async {
        final dbFile = writeFile('workout_tracker.db', 'old-db-data');
        final missingImportPath = '${sandboxDir.path}/missing_backup.db';
        final databaseHelper = FakeDatabaseHelper(
          databasePathValue: dbFile.path,
        );

        final service = buildService(
          databaseHelper: databaseHelper,
          pickFiles: ({required type, required allowMultiple}) async {
            return FilePickerResult([
              PlatformFile(
                path: missingImportPath,
                name: 'missing_backup.db',
                size: 0,
              ),
            ]);
          },
        );

        await expectLater(
          service.importData(),
          throwsA(isA<FileSystemException>()),
        );

        expect(await dbFile.readAsString(), 'old-db-data');
        expect(databaseHelper.closeCallCount, 1);
        expect(databaseHelper.databaseAccessCount, 2);
      },
    );

    test(
      'importData surfaces the database reopen failure when cleanup also fails',
      () async {
        final dbFile = writeFile('workout_tracker.db', 'old-db-data');
        final missingImportPath = '${sandboxDir.path}/missing_backup.db';
        final databaseHelper = FakeDatabaseHelper(
          databasePathValue: dbFile.path,
        );

        final service = buildService(
          databaseHelper: databaseHelper,
          pickFiles: ({required type, required allowMultiple}) async {
            databaseHelper.throwOnDatabaseAccess = true;
            return FilePickerResult([
              PlatformFile(
                path: missingImportPath,
                name: 'missing_backup.db',
                size: 0,
              ),
            ]);
          },
        );

        await expectLater(
          service.importData(),
          throwsA(same(databaseHelper.databaseAccessError)),
        );

        expect(await dbFile.readAsString(), 'old-db-data');
        expect(databaseHelper.closeCallCount, 1);
        expect(databaseHelper.databaseAccessCount, 2);
      },
    );

    test(
      'importData rethrows picker failures without touching the database',
      () async {
        final databaseHelper = FakeDatabaseHelper(
          databasePathValue: '${sandboxDir.path}/workout_tracker.db',
        );
        final pickerError = StateError('picker failed');

        final service = buildService(
          databaseHelper: databaseHelper,
          pickFiles: ({required type, required allowMultiple}) async {
            throw pickerError;
          },
        );

        await expectLater(service.importData(), throwsA(same(pickerError)));

        expect(databaseHelper.closeCallCount, 0);
        expect(databaseHelper.databaseAccessCount, 1);
      },
    );
  });
}
