// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(giphyService)
final giphyServiceProvider = GiphyServiceProvider._();

final class GiphyServiceProvider
    extends $FunctionalProvider<GiphyService, GiphyService, GiphyService>
    with $Provider<GiphyService> {
  GiphyServiceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'giphyServiceProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$giphyServiceHash();

  @$internal
  @override
  $ProviderElement<GiphyService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GiphyService create(Ref ref) {
    return giphyService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GiphyService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GiphyService>(value),
    );
  }
}

String _$giphyServiceHash() => r'0782895ba140df034058152031089c9302cba8c7';

@ProviderFor(firestoreService)
final firestoreServiceProvider = FirestoreServiceProvider._();

final class FirestoreServiceProvider extends $FunctionalProvider<
    FirestoreService,
    FirestoreService,
    FirestoreService> with $Provider<FirestoreService> {
  FirestoreServiceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'firestoreServiceProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$firestoreServiceHash();

  @$internal
  @override
  $ProviderElement<FirestoreService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FirestoreService create(Ref ref) {
    return firestoreService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirestoreService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirestoreService>(value),
    );
  }
}

String _$firestoreServiceHash() => r'60ff847ea870b353b433504c7f164ea13f87009a';

@ProviderFor(storageService)
final storageServiceProvider = StorageServiceProvider._();

final class StorageServiceProvider
    extends $FunctionalProvider<StorageService, StorageService, StorageService>
    with $Provider<StorageService> {
  StorageServiceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'storageServiceProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$storageServiceHash();

  @$internal
  @override
  $ProviderElement<StorageService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  StorageService create(Ref ref) {
    return storageService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StorageService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StorageService>(value),
    );
  }
}

String _$storageServiceHash() => r'd00ff3a8d40ab09927629e8489be8696bd8d1760';

@ProviderFor(userChats)
final userChatsProvider = UserChatsProvider._();

final class UserChatsProvider extends $FunctionalProvider<
        AsyncValue<List<ChatModel>>, List<ChatModel>, Stream<List<ChatModel>>>
    with $FutureModifier<List<ChatModel>>, $StreamProvider<List<ChatModel>> {
  UserChatsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'userChatsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$userChatsHash();

  @$internal
  @override
  $StreamProviderElement<List<ChatModel>> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<ChatModel>> create(Ref ref) {
    return userChats(ref);
  }
}

String _$userChatsHash() => r'f695de26f58469425a4f7f01cd044b5cd3bc8bfd';

@ProviderFor(chatMessages)
final chatMessagesProvider = ChatMessagesFamily._();

final class ChatMessagesProvider extends $FunctionalProvider<
        AsyncValue<List<MessageModel>>,
        List<MessageModel>,
        Stream<List<MessageModel>>>
    with
        $FutureModifier<List<MessageModel>>,
        $StreamProvider<List<MessageModel>> {
  ChatMessagesProvider._(
      {required ChatMessagesFamily super.from, required String super.argument})
      : super(
          retry: null,
          name: r'chatMessagesProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$chatMessagesHash();

  @override
  String toString() {
    return r'chatMessagesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<MessageModel>> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<MessageModel>> create(Ref ref) {
    final argument = this.argument as String;
    return chatMessages(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ChatMessagesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$chatMessagesHash() => r'7512a11cb672f00629ba5dbb9b618b14d8026c2e';

final class ChatMessagesFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<MessageModel>>, String> {
  ChatMessagesFamily._()
      : super(
          retry: null,
          name: r'chatMessagesProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  ChatMessagesProvider call(
    String chatId,
  ) =>
      ChatMessagesProvider._(argument: chatId, from: this);

  @override
  String toString() => r'chatMessagesProvider';
}

@ProviderFor(MessageNotifier)
final messageProvider = MessageNotifierFamily._();

final class MessageNotifierProvider
    extends $AsyncNotifierProvider<MessageNotifier, void> {
  MessageNotifierProvider._(
      {required MessageNotifierFamily super.from,
      required String super.argument})
      : super(
          retry: null,
          name: r'messageProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$messageNotifierHash();

  @override
  String toString() {
    return r'messageProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  MessageNotifier create() => MessageNotifier();

  @override
  bool operator ==(Object other) {
    return other is MessageNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$messageNotifierHash() => r'825411478114f56ab818e0641ca75729933e19f0';

final class MessageNotifierFamily extends $Family
    with
        $ClassFamilyOverride<MessageNotifier, AsyncValue<void>, void,
            FutureOr<void>, String> {
  MessageNotifierFamily._()
      : super(
          retry: null,
          name: r'messageProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  MessageNotifierProvider call(
    String chatId,
  ) =>
      MessageNotifierProvider._(argument: chatId, from: this);

  @override
  String toString() => r'messageProvider';
}

abstract class _$MessageNotifier extends $AsyncNotifier<void> {
  late final _$args = ref.$arg as String;
  String get chatId => _$args;

  FutureOr<void> build(
    String chatId,
  );
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<void>, void>,
        AsyncValue<void>,
        Object?,
        Object?>;
    return element.handleCreate(
        ref,
        () => build(
              _$args,
            ));
  }
}

@ProviderFor(userProfile)
final userProfileProvider = UserProfileFamily._();

final class UserProfileProvider extends $FunctionalProvider<
        AsyncValue<UserModel?>, UserModel?, Stream<UserModel?>>
    with $FutureModifier<UserModel?>, $StreamProvider<UserModel?> {
  UserProfileProvider._(
      {required UserProfileFamily super.from, required String super.argument})
      : super(
          retry: null,
          name: r'userProfileProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$userProfileHash();

  @override
  String toString() {
    return r'userProfileProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<UserModel?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<UserModel?> create(Ref ref) {
    final argument = this.argument as String;
    return userProfile(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is UserProfileProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$userProfileHash() => r'19f591fb69b5c0185ff009bf4976921270792816';

final class UserProfileFamily extends $Family
    with $FunctionalFamilyOverride<Stream<UserModel?>, String> {
  UserProfileFamily._()
      : super(
          retry: null,
          name: r'userProfileProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  UserProfileProvider call(
    String uid,
  ) =>
      UserProfileProvider._(argument: uid, from: this);

  @override
  String toString() => r'userProfileProvider';
}

@ProviderFor(chatPartner)
final chatPartnerProvider = ChatPartnerFamily._();

final class ChatPartnerProvider extends $FunctionalProvider<
        AsyncValue<UserModel?>, UserModel?, FutureOr<UserModel?>>
    with $FutureModifier<UserModel?>, $FutureProvider<UserModel?> {
  ChatPartnerProvider._(
      {required ChatPartnerFamily super.from, required String super.argument})
      : super(
          retry: null,
          name: r'chatPartnerProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$chatPartnerHash();

  @override
  String toString() {
    return r'chatPartnerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<UserModel?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<UserModel?> create(Ref ref) {
    final argument = this.argument as String;
    return chatPartner(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ChatPartnerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$chatPartnerHash() => r'76fbd1dc41ba012fbe1dff790aa7d43454f5c0fe';

final class ChatPartnerFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<UserModel?>, String> {
  ChatPartnerFamily._()
      : super(
          retry: null,
          name: r'chatPartnerProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  ChatPartnerProvider call(
    String chatId,
  ) =>
      ChatPartnerProvider._(argument: chatId, from: this);

  @override
  String toString() => r'chatPartnerProvider';
}
