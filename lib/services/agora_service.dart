import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/widgets.dart';
import 'package:alias/core/config/app_config.dart';

class AgoraService {
  final String appId;
  RtcEngine? _engine;
  
  Function(int)? onUserJoined;
  Function(int)? onUserOffline;
  Function(int, int, int)? onLocalVideoStats;
  Function(int, ErrorCodeType)? onError;

  AgoraService(this.appId);

  Future<void> initialize() async {
    _engine = createAgoraRtcEngine();
    await _engine!.initialize(RtcEngineContext(appId: appId));

    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {},
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          onUserJoined?.call(remoteUid);
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          onUserOffline?.call(remoteUid);
        },
        onError: (ErrorCodeType err, String msg) {
          onError?.call(0, err);
        },
      ),
    );
  }

  Future<String?> fetchToken(String channelName, int uid) async {
    if (AppConfig.agoraTokenServerUrl.isEmpty) return null;
    
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.agoraTokenServerUrl}/fetch_rtc_token'),
        body: jsonEncode({
          'channelName': channelName,
          'uid': uid,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['token'];
      }
    } catch (e) {
      // Handle error
    }
    return null;
  }

  Future<void> joinChannel({
    required String channelName,
    required String token,
    required int uid,
    required bool withVideo,
  }) async {
    if (_engine == null) return;

    if (withVideo) {
      await _engine!.enableVideo();
    } else {
      await _engine!.disableVideo();
    }

    await _engine!.joinChannel(
      token: token,
      channelId: channelName,
      uid: uid,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );
  }

  Future<void> leaveChannel() async {
    await _engine?.leaveChannel();
    await dispose();
  }

  Future<void> toggleMute(bool mute) async {
    await _engine?.muteLocalAudioStream(mute);
  }

  Future<void> toggleVideo(bool enabled) async {
    await _engine?.muteLocalVideoStream(!enabled);
  }

  Future<void> switchCamera() async {
    await _engine?.switchCamera();
  }

  Future<void> dispose() async {
    await _engine?.release();
    _engine = null;
  }

  Widget? get localVideoView {
    if (_engine == null) return null;
    return AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: _engine!,
        canvas: const VideoCanvas(uid: 0),
      ),
    );
  }

  Widget remoteVideoView(int remoteUid) {
    if (_engine == null) return const SizedBox.shrink();
    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: _engine!,
        canvas: VideoCanvas(uid: remoteUid),
        connection: const RtcConnection(),
      ),
    );
  }
}
