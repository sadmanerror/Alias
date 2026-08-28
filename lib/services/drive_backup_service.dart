import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class BackupResult {
  final bool success;
  final String? error;
  final DateTime? timestamp;

  BackupResult({required this.success, this.error, this.timestamp});
}

class RestoreResult {
  final bool success;
  final String? error;

  RestoreResult({required this.success, this.error});
}

class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}

class DriveBackupService {
  final GoogleSignIn _googleSignIn;

  DriveBackupService(this._googleSignIn);

  Future<drive.DriveApi?> _getDriveApi() async {
    try {
      final account = _googleSignIn.currentUser ?? await _googleSignIn.signIn();
      if (account == null) return null;

      final authHeaders = await account.authHeaders;
      final authenticateClient = _GoogleAuthClient(authHeaders);
      return drive.DriveApi(authenticateClient);
    } catch (e) {
      return null;
    }
  }

  Future<BackupResult> backup(String dbFilePath) async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) {
        return BackupResult(success: false, error: 'Authentication failed');
      }

      final tempDir = await getTemporaryDirectory();
      final zipPath = '${tempDir.path}/alias_backup.zip';
      
      final encoder = ZipFileEncoder();
      encoder.create(zipPath);
      encoder.addFile(File(dbFilePath));
      encoder.close();

      final fileList = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name='alias_backup.zip'",
      );

      final existingFile = fileList.files?.isNotEmpty == true ? fileList.files!.first : null;
      
      final driveFile = drive.File()..name = 'alias_backup.zip';
      final fileMedia = drive.Media(File(zipPath).openRead(), File(zipPath).lengthSync());

      if (existingFile != null && existingFile.id != null) {
        await driveApi.files.update(
          driveFile,
          existingFile.id!,
          uploadMedia: fileMedia,
        );
      } else {
        driveFile.parents = ['appDataFolder'];
        await driveApi.files.create(
          driveFile,
          uploadMedia: fileMedia,
        );
      }

      File(zipPath).deleteSync();
      return BackupResult(success: true, timestamp: DateTime.now());
    } catch (e) {
      return BackupResult(success: false, error: e.toString());
    }
  }

  Future<RestoreResult> restore(String targetDbPath) async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) {
        return RestoreResult(success: false, error: 'Authentication failed');
      }

      final fileList = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name='alias_backup.zip'",
      );

      if (fileList.files == null || fileList.files!.isEmpty) {
        return RestoreResult(success: false, error: 'No backup found');
      }

      final backupFileId = fileList.files!.first.id!;
      final drive.Media media = await driveApi.files.get(
        backupFileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final tempDir = await getTemporaryDirectory();
      final zipPath = '${tempDir.path}/alias_backup.zip';
      final fileStream = File(zipPath).openWrite();
      await media.stream.pipe(fileStream);

      final bytes = File(zipPath).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive) {
        if (file.isFile) {
          final data = file.content as List<int>;
          File(targetDbPath)
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
        }
      }

      File(zipPath).deleteSync();
      return RestoreResult(success: true);
    } catch (e) {
      return RestoreResult(success: false, error: e.toString());
    }
  }

  Future<DateTime?> getLastBackupTime() async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return null;

      final fileList = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name='alias_backup.zip'",
        $fields: "files(modifiedTime)",
      );

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        return fileList.files!.first.modifiedTime;
      }
    } catch (e) {
      return null;
    }
    return null;
  }
}
