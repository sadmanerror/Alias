import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:alias/services/agora_service.dart';
import 'package:alias/models/call_model.dart';
import 'package:alias/core/config/app_config.dart';
import 'package:alias/providers/auth_provider.dart';
import 'package:alias/providers/chat_provider.dart';

part 'call_provider.g.dart';

@riverpod
AgoraService agoraService(Ref ref) {
  return AgoraService(AppConfig.agoraAppId);
}

final callNotifierProvider = callProvider;

@riverpod
class CallNotifier extends _$CallNotifier {
  CallModel? _activeCall;
  bool _isMuted = false;
  bool _isCameraOn = true;

  bool get isMuted => _isMuted;
  bool get isCameraOn => _isCameraOn;
  CallModel? get activeCall => _activeCall;

  @override
  FutureOr<void> build() async {}

  Future<void> initiateCall({required String calleeId, required String channelName, required CallType callType}) async {
    final caller = ref.read(authStateProvider).value;
    if (caller == null) return;
    
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final call = CallModel(
        callId: channelName,
        callerId: caller.uid,
        calleeId: calleeId,
        channelName: channelName,
        type: callType,
        status: CallStatus.ringing,
        startedAt: DateTime.now(),
      );
      _activeCall = call;
      await ref.read(firestoreServiceProvider).initiateCall(call);
    });
  }

  Future<void> acceptCall(CallModel call) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      _activeCall = call;
      await ref.read(firestoreServiceProvider).updateCallStatus(call.callId, 'active');
      await ref.read(agoraServiceProvider).joinChannel(
        channelName: call.channelName,
        token: call.agoraToken ?? '',
        uid: 0,
        withVideo: call.type == CallType.video,
      );
    });
  }

  Future<void> declineCall(CallModel call) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(firestoreServiceProvider).updateCallStatus(call.callId, 'declined');
      _activeCall = null;
    });
  }

  Future<void> endCall() async {
    if (_activeCall == null) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(firestoreServiceProvider).updateCallStatus(_activeCall!.callId, 'ended');
      await ref.read(agoraServiceProvider).leaveChannel();
      _activeCall = null;
    });
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    ref.read(agoraServiceProvider).toggleMute(_isMuted);
  }

  void toggleCamera() {
    _isCameraOn = !_isCameraOn;
    ref.read(agoraServiceProvider).toggleVideo(_isCameraOn);
  }

  void switchCamera() {
    ref.read(agoraServiceProvider).switchCamera();
  }
}

@riverpod
Stream<CallModel?> incomingCall(Ref ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return const Stream.empty();
  return ref.watch(firestoreServiceProvider).streamIncomingCalls(user.uid);
}
