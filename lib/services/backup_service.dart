import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class BackupService {
  static Future<File?> exportDatabase() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/backup/export'),
        headers: ApiService.authHeaders,
      );

      if (response.statusCode == 200) {
        String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Database Backup',
          fileName:
              'zitemart_backup_${DateTime.now().millisecondsSinceEpoch}.sql',
          allowedExtensions: ['sql'],
        );

        if (outputFile != null) {
          final file = File(outputFile);
          await file.writeAsBytes(response.bodyBytes);
          return file;
        }
      }
      return null;
    } catch (e) {
      print('Error exporting database: $e');
      return null;
    }
  }

  static Future<File?> importDatabase() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select Database Backup File',
        allowedExtensions: ['sql'],
        type: FileType.custom,
      );

      if (result == null) return null;

      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/backup/import'),
      );
      request.headers.addAll(ApiService.authHeaders);
      request.files.add(
        http.MultipartFile.fromBytes(
          'backup',
          bytes,
          filename: result.files.single.name,
        ),
      );

      final response = await request.send();
      if (response.statusCode == 200) {
        return file;
      }
      return null;
    } catch (e) {
      print('Error importing database: $e');
      return null;
    }
  }

  static Future<Directory> getBackupDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${directory.path}/backups');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir;
  }

  // ADD THIS METHOD:
  static Future<void> openBackupFolder(String path) async {
    if (Platform.isWindows) {
      await Process.run('explorer', [path]);
    } else if (Platform.isMacOS) {
      await Process.run('open', [path]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [path]);
    }
  }

  static Future<List<FileSystemEntity>> getBackupFiles() async {
    try {
      final directory = await getBackupDirectory();
      final files = await directory.list().toList();
      final sqlFiles = files
          .where(
            (file) =>
                file.path.endsWith('.sql') && File(file.path).existsSync(),
          )
          .toList();
      sqlFiles.sort((a, b) {
        return File(
          b.path,
        ).lastModifiedSync().compareTo(File(a.path).lastModifiedSync());
      });
      return sqlFiles;
    } catch (e) {
      print('Error getting backup files: $e');
      return [];
    }
  }

  static Future<bool> restoreFromFile(String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/backup/restore'),
      );
      request.headers.addAll(ApiService.authHeaders);
      request.files.add(
        http.MultipartFile.fromBytes(
          'backup',
          bytes,
          filename: filePath.split('\\').last,
        ),
      );
      final response = await request.send();
      return response.statusCode == 200;
    } catch (e) {
      print('Error restoring from file: $e');
      return false;
    }
  }

  static Future<void> deleteBackupFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
