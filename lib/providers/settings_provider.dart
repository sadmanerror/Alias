import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:alias/services/drive_backup_service.dart';
import 'package:alias/services/local_db_service.dart';

final localDbServiceProvider = Provider<LocalDbService>((ref) {
  return LocalDbService();
});

final driveBackupServiceProvider = Provider<DriveBackupService>((ref) {
  return DriveBackupService(GoogleSignIn(scopes: ['email', 'https://www.googleapis.com/auth/drive.appdata']));
});

class SettingsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  bool _isDarkMode = false;

  SettingsNotifier(this.ref) : super(const AsyncValue.data(null));

  SettingsNotifier get notifier => this;

  bool get isDarkMode => _isDarkMode;

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

final settingsNotifierProvider = StateNotifierProvider<SettingsNotifier, AsyncValue<void>>((ref) {
  return SettingsNotifier(ref);
});
