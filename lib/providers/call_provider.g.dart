// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'call_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(agoraService)
final agoraServiceProvider = AgoraServiceProvider._();

final class AgoraServiceProvider
    extends $FunctionalProvider<AgoraService, AgoraService, AgoraService>
    with $Provider<AgoraService> {
  AgoraServiceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'agoraServiceProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$agoraServiceHash();

  @$internal
  @override
  $ProviderElement<AgoraService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AgoraService create(Ref ref) {
    return agoraService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AgoraService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AgoraService>(value),
    );
  }
}

String _$agoraServiceHash() => r'd0a85141bf117dbd802900fe2ad330d73ca27794';

@ProviderFor(CallNotifier)
final callProvider = CallNotifierProvider._();

final class CallNotifierProvider
    extends $AsyncNotifierProvider<CallNotifier, void> {
  CallNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'callProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$callNotifierHash();

  @$internal
  @override
  CallNotifier create() => CallNotifier();
}

String _$callNotifierHash() => r'b568a504c81bae233ea4b1c602180f165b0226f1';

abstract class _$CallNotifier extends $AsyncNotifier<void> {
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

@ProviderFor(incomingCall)
final incomingCallProvider = IncomingCallProvider._();

final class IncomingCallProvider extends $FunctionalProvider<
        AsyncValue<CallModel?>, CallModel?, Stream<CallModel?>>
    with $FutureModifier<CallModel?>, $StreamProvider<CallModel?> {
  IncomingCallProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'incomingCallProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$incomingCallHash();

  @$internal
  @override
  $StreamProviderElement<CallModel?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<CallModel?> create(Ref ref) {
    return incomingCall(ref);
  }
}

String _$incomingCallHash() => r'a0df4e18b1e3e706309e7d89883ea6e1a127cffe';
