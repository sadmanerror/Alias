import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:alias/services/drive_backup_service.dart';
import 'package:alias/services/local_db_service.dart';

part 'settings_provider.g.dart';

@riverpod
LocalDbService localDbService(Ref ref) {
  return LocalDbService();
}

@riverpod
DriveBackupService driveBackupService(Ref ref) {
  return DriveBackupService(GoogleSignIn(scopes: ['email', 'https://www.googleapis.com/auth/drive.appdata']));
}

@riverpod
class SettingsNotifier extends _$SettingsNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  @override
  FutureOr<void> build() async {}

  Future<BackupResult> backupToGoogle() async {
    final dbPath = await ref.read(localDbServiceProvider).getDatabasePath();
    return ref.read(driveBackupServiceProvider).backup(dbPath);
  }

  Future<RestoreResult> restoreFromGoogle() async {
    final dbPath = await ref.read(localDbServiceProvider).getDatabasePath();
    return ref.read(driveBackupServiceProvider).restore(dbPath);
  }

  Future<DateTime?> getLastBackupTime() async {
    return ref.read(driveBackupServiceProvider).getLastBackupTime();
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
  }
}

final settingsNotifierProvider = settingsProvider;
