import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../services/export_import_service.dart';

class SettingsDataSection extends StatelessWidget {
  const SettingsDataSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[900],
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 16.0, top: 8.0, bottom: 4.0),
              child: Text(
                'Data Management',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            _buildDataItem(
              context,
              icon: CupertinoIcons.square_arrow_up,
              title: 'Export Data',
              subtitle: 'Backup your workouts and progress',
              onTap: () => _exportData(context),
            ),
            _buildDivider(),
            _buildDataItem(
              context,
              icon: CupertinoIcons.square_arrow_down,
              title: 'Import Data',
              subtitle: 'Restore from backup file',
              onTap: () => _importData(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: ListTile(
          leading: Icon(icon, color: Colors.grey[400], size: 22),
          title: Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
          trailing: Icon(
            CupertinoIcons.chevron_right,
            color: Colors.grey[400],
            size: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 0.5,
      thickness: 0.5,
      color: Colors.grey[700],
      indent: 58,
    );
  }

  Future<void> _exportData(BuildContext context) async {
    try {
      final exportService = ExportImportService();
      await exportService.exportData();
      
      if (context.mounted) {
        _showSuccessDialog(
          context,
          'Export Successful',
          'Your data has been exported successfully.',
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorDialog(
          context,
          'Export Failed',
          'Failed to export data: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _importData(BuildContext context) async {
    try {
      final exportService = ExportImportService();
      await exportService.importData();
      
      if (context.mounted) {
        _showSuccessDialog(
          context,
          'Import Successful',
          'Your data has been imported successfully.',
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorDialog(
          context,
          'Import Failed',
          'Failed to import data: ${e.toString()}',
        );
      }
    }
  }

  void _showSuccessDialog(BuildContext context, String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
