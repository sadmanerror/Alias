import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:alias/services/agora_service.dart';
import 'package:alias/models/call_model.dart';
import 'package:alias/core/config/app_config.dart';
import 'package:alias/providers/auth_provider.dart';
import 'package:alias/providers/chat_provider.dart';

final agoraServiceProvider = Provider<AgoraService>((ref) {
  return AgoraService(AppConfig.agoraAppId);
});

class CallNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  CallModel? _activeCall;
  bool _isMuted = false;
  bool _isCameraOn = true;

  CallNotifier(this.ref) : super(const AsyncValue.data(null));

  CallNotifier get notifier => this;

  bool get isMuted => _isMuted;
  bool get isCameraOn => _isCameraOn;
  CallModel? get activeCall => _activeCall;

  Future<String?> initiateCall({
    required String calleeId,
    required String channelName,
    required CallType callType,
  }) async {
    final caller = ref.read(authStateProvider).value;
    if (caller == null) return null;

    final currentUser = ref.read(currentUserModelProvider).value;
    final callerName = currentUser?.username ?? caller.displayName ?? '';

    state = const AsyncValue.loading();
    String? createdCallId;
    state = await AsyncValue.guard(() async {
      final docRef = FirebaseFirestore.instance.collection('calls').doc();
      final callId = docRef.id;
      createdCallId = callId;

      final call = CallModel(
        callId: callId,
        callerId: caller.uid,
        calleeId: calleeId,
        channelName: channelName,
        type: callType,
        status: CallStatus.ringing,
        startedAt: DateTime.now(),
        callerName: callerName,
      );
      _activeCall = call;
      await ref.read(firestoreServiceProvider).initiateCall(call);

      try {
        await ref.read(agoraServiceProvider).joinChannel(
          channelName: channelName,
          token: call.agoraToken ?? '',
          uid: 0,
          withVideo: callType == CallType.video,
        );
      } catch (e) {
        debugPrint('Agora joinChannel non-fatal error: $e');
      }
    });

    return createdCallId;
  }

  Future<void> acceptCall(CallModel call) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      _activeCall = call;
      await ref.read(firestoreServiceProvider).updateCallStatus(call.callId, 'active');
      try {
        await ref.read(agoraServiceProvider).joinChannel(
          channelName: call.channelName,
          token: call.agoraToken ?? '',
          uid: 0,
          withVideo: call.type == CallType.video,
        );
      } catch (e) {
        debugPrint('Agora joinChannel non-fatal error: $e');
      }
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
      try {
        await ref.read(agoraServiceProvider).leaveChannel();
      } catch (e) {
        debugPrint('Agora leaveChannel non-fatal error: $e');
      }
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

final callNotifierProvider = StateNotifierProvider<CallNotifier, AsyncValue<void>>((ref) {
  return CallNotifier(ref);
});

final incomingCallProvider = StreamProvider<CallModel?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return const Stream.empty();
  return ref.watch(firestoreServiceProvider).streamIncomingCalls(user.uid);
});

final groupCallProvider = StreamProvider.family<Map<String, dynamic>?, String>(
  (ref, chatId) {
    return FirebaseFirestore.instance
        .collection('calls')
        .doc('${chatId}_group')
        .snapshots()
        .map((snap) => snap.exists ? snap.data() : null);
  },
);
