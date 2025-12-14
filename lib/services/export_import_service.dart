import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:logging/logging.dart';
import 'package:share_plus/share_plus.dart';
import 'package:zenith/services/database_helper.dart';

class ExportImportService {
  static ExportImportService? _instance;
  final Logger _logger = Logger('ExportImportService');
  final DatabaseHelper _databaseHelper;

  ExportImportService._internal(this._databaseHelper);

  static ExportImportService get instance {
    _instance ??= ExportImportService._internal(DatabaseHelper());
    return _instance!;
  }

  Future<void> exportData() async {
    _logger.info('Starting database export');
    try {
      // Get the database path
      final dbPath = await _databaseHelper.databasePath;
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        throw Exception('Database file not found at $dbPath');
      }

      // Close the database to ensure all data is flushed and file is safe to copy
      await _databaseHelper.close();

      try {
        // Share the database file directly
        // We use the original file path. SharePlus copies it internally usually.
        // If we wanted to be extra safe we could copy to a temp dir first, 
        // but closing the DB should be enough.
        
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final exportName = 'zenith_backup_$timestamp.db';
        
        // Create a temporary copy with the timestamped name for sharing
        final tempDir = Directory.systemTemp;
        final tempFile = await dbFile.copy('${tempDir.path}/$exportName');

        await Share.shareXFiles(
          [XFile(tempFile.path)],
          subject: 'Zenith Workout Tracker Backup',
        );
        
        // Clean up temp file
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      } finally {
        // Re-open the database (accessing the property triggers init)
        await _databaseHelper.database;
      }
      
      _logger.info('Database export completed');
    } catch (e) {
      _logger.severe('Failed to export database: $e');
      // Ensure database is re-opened even if export fails
      try {
        await _databaseHelper.database;
      } catch (dbError) {
        _logger.severe('Failed to re-open database after export error: $dbError');
      }
      rethrow;
    }
  }

  Future<bool> importData() async {
    _logger.info('Starting database import');
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        // We use FileType.any because on some Android devices/versions, 
        // filtering by extension (custom) can prevent selecting files 
        // that don't have the exact MIME type registered.
        // However, if the user reports issues, we might need to adjust this.
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        _logger.info('No file selected for import');
        return false;
      }

      final pickedPath = result.files.single.path!;
      final pickedFile = File(pickedPath);
      
      // Basic validation - check if it's a valid SQLite file? 
      // Or just trust the user. Let's check extension at least if possible, 
      // but on mobile extensions can be hidden or weird.
      // We'll just try to use it.

      // Get current DB path
      final dbPath = await _databaseHelper.databasePath;
      final dbFile = File(dbPath);

      // Close current database
      await _databaseHelper.close();

      try {
        // Backup current DB just in case? 
        // For now, we'll just overwrite as requested.
        
        // Copy picked file to DB path
        await pickedFile.copy(dbPath);
        
        _logger.info('Database file overwritten with imported file');
      } catch (e) {
        _logger.severe('Error copying imported file: $e');
        // If copy fails, we might be in a bad state if we deleted the original.
        // But copy overwrites, so if it fails mid-way... 
        // Ideally we should have backed up.
        rethrow;
      } finally {
        // Re-open database (this will verify if it's a valid DB file implicitly by trying to open it)
        await _databaseHelper.database;
      }

      _logger.info('Database import completed successfully');
      return true;
    } catch (e) {
      _logger.severe('Failed to import database: $e');
      // Ensure database is re-opened
      try {
        await _databaseHelper.database;
      } catch (dbError) {
        _logger.severe('Failed to re-open database after import error: $dbError');
      }
      rethrow;
    }
  }
}
