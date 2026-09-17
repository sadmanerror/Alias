import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/widgets.dart';
import 'package:alias/core/config/app_config.dart';
import 'package:permission_handler/permission_handler.dart';

class AgoraService {
  final String appId;
  RtcEngine? _engine;
  bool _isInitialized = false;
  
  Function(int)? onUserJoined;
  Function(int)? onUserOffline;
  Function(int, int, int)? onLocalVideoStats;
  Function(int, ErrorCodeType)? onError;

  AgoraService(this.appId);

  RtcEngine? get engine => _engine;
  bool get isInitialized => _isInitialized && _engine != null;

  Future<void> initialize() async {
    if (appId.isEmpty || appId == 'YOUR_AGORA_APP_ID') {
      debugPrint('Agora App ID is not configured in AppConfig.agoraAppId!');
      return;
    }
    if (_isInitialized && _engine != null) return;

    try {
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint('Agora onJoinChannelSuccess: channel=${connection.channelId}, uid=${connection.localUid}');
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            debugPrint('Agora onUserJoined: remoteUid=$remoteUid');
            onUserJoined?.call(remoteUid);
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            debugPrint('Agora onUserOffline: remoteUid=$remoteUid');
            onUserOffline?.call(remoteUid);
          },
          onError: (ErrorCodeType err, String msg) {
            debugPrint('Agora onError: $err, msg: $msg');
            onError?.call(0, err);
          },
        ),
      );

      await _engine!.enableAudio();
      await _engine!.enableLocalAudio(true);
      await _engine!.setDefaultAudioRouteToSpeakerphone(true);
      _isInitialized = true;
    } catch (e) {
      debugPrint('Agora initialize error: $e');
      _engine = null;
      _isInitialized = false;
    }
  }

  Future<String?> fetchToken(String channelName, int uid) async {
    if (AppConfig.agoraTokenServerUrl.isEmpty ||
        AppConfig.agoraTokenServerUrl == 'YOUR_TOKEN_SERVER_URL') {
      return null;
    }
    
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
      debugPrint('Fetch token error: $e');
    }
    return null;
  }

  Future<void> joinChannel({
    required String channelName,
    required String token,
    required int uid,
    required bool withVideo,
  }) async {
    // Request permissions on native platforms
    if (!kIsWeb) {
      try {
        await Permission.microphone.request();
        if (withVideo) {
          await Permission.camera.request();
        }
      } catch (e) {
        debugPrint('Permission request error: $e');
      }
    }

    if (!_isInitialized || _engine == null) {
      await initialize();
    }
    if (_engine == null) {
      debugPrint('Agora engine is not available. Skipping joinChannel.');
      return;
    }

    try {
      if (withVideo) {
        await _engine!.enableVideo();
      } else {
        await _engine!.disableVideo();
      }

      await _engine!.joinChannel(
        token: token,
        channelId: channelName,
        uid: uid,
        options: ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
          publishMicrophoneTrack: true,
          publishCameraTrack: withVideo,
          autoSubscribeAudio: true,
          autoSubscribeVideo: withVideo,
        ),
      );
    } catch (e) {
      debugPrint('Agora joinChannel error: $e');
    }
  }

  Future<void> leaveChannel() async {
    try {
      await _engine?.leaveChannel();
    } catch (e) {
      debugPrint('Agora leaveChannel error: $e');
    }
  }

  Future<void> toggleMute(bool mute) async {
    try {
      await _engine?.muteLocalAudioStream(mute);
    } catch (e) {
      debugPrint('Agora toggleMute error: $e');
    }
  }

  Future<void> toggleSpeaker(bool speaker) async {
    try {
      await _engine?.setEnableSpeakerphone(speaker);
    } catch (e) {
      debugPrint('Agora toggleSpeaker error: $e');
    }
  }

  Future<void> toggleVideo(bool enabled) async {
    try {
      await _engine?.muteLocalVideoStream(!enabled);
    } catch (e) {
      debugPrint('Agora toggleVideo error: $e');
    }
  }

  Future<void> switchCamera() async {
    try {
      await _engine?.switchCamera();
    } catch (e) {
      debugPrint('Agora switchCamera error: $e');
    }
  }

  Future<void> dispose() async {
    try {
      await _engine?.release();
    } catch (e) {
      debugPrint('Agora dispose error: $e');
    }
    _engine = null;
    _isInitialized = false;
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
