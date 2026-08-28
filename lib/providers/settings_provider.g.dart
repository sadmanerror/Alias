// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(localDbService)
final localDbServiceProvider = LocalDbServiceProvider._();

final class LocalDbServiceProvider
    extends $FunctionalProvider<LocalDbService, LocalDbService, LocalDbService>
    with $Provider<LocalDbService> {
  LocalDbServiceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'localDbServiceProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$localDbServiceHash();

  @$internal
  @override
  $ProviderElement<LocalDbService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LocalDbService create(Ref ref) {
    return localDbService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocalDbService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocalDbService>(value),
    );
  }
}

String _$localDbServiceHash() => r'999d40788d43bf1ad29907044bfa0c157cc2ebc8';

@ProviderFor(driveBackupService)
final driveBackupServiceProvider = DriveBackupServiceProvider._();

final class DriveBackupServiceProvider extends $FunctionalProvider<
    DriveBackupService,
    DriveBackupService,
    DriveBackupService> with $Provider<DriveBackupService> {
  DriveBackupServiceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'driveBackupServiceProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$driveBackupServiceHash();

  @$internal
  @override
  $ProviderElement<DriveBackupService> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DriveBackupService create(Ref ref) {
    return driveBackupService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DriveBackupService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DriveBackupService>(value),
    );
  }
}

String _$driveBackupServiceHash() =>
    r'63270244dea06bcf6d945a857ff4c7005955a8e2';

@ProviderFor(SettingsNotifier)
final settingsProvider = SettingsNotifierProvider._();

final class SettingsNotifierProvider
    extends $AsyncNotifierProvider<SettingsNotifier, void> {
  SettingsNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'settingsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$settingsNotifierHash();

  @$internal
  @override
  SettingsNotifier create() => SettingsNotifier();
}

String _$settingsNotifierHash() => r'fb1bb33a3ca0204f674c1ed1fe77140bae3779e4';

abstract class _$SettingsNotifier extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<void>, void>,
        AsyncValue<void>,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}
