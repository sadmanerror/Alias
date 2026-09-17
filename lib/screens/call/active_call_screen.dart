import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:alias/models/call_model.dart';
import 'package:alias/models/user_model.dart';
import 'package:alias/providers/call_provider.dart';
import 'package:alias/providers/auth_provider.dart';
import 'package:alias/providers/chat_provider.dart';
import 'package:alias/core/config/app_config.dart';

class ActiveCallScreen extends ConsumerStatefulWidget {
  final String callId;

  const ActiveCallScreen({super.key, required this.callId});

  @override
  ConsumerState<ActiveCallScreen> createState() => _ActiveCallScreenState();
}

class _ActiveCallScreenState extends ConsumerState<ActiveCallScreen> {
  CallModel? _call;
  UserModel? _remoteUser;
  bool _isLoading = true;
  String _errorMessage = '';

  int? _remoteUid;
  bool _isMuted = false;
  bool _isVideoOn = true;
  bool _isSpeakerOn = false;
  
  Timer? _callTimer;
  int _elapsedSeconds = 0;
  StreamSubscription<DocumentSnapshot>? _callSubscription;

  Offset _pipPosition = const Offset(16, 100); // Initial PiP position

  @override
  void initState() {
    super.initState();
    _initCallData();
  }

  Future<void> _initCallData() async {
    try {
      final callSnapshot = await FirebaseFirestore.instance
          .collection('calls')
          .doc(widget.callId)
          .get();
      
      if (!callSnapshot.exists) {
        _endCallAndPop('Call ended unexpectedly.');
        return;
      }
      
      final call = CallModel.fromJson(callSnapshot.data()!, widget.callId);
      _call = call;
      _isVideoOn = call.type == CallType.video;

      final currentUserId = ref.read(authStateProvider).value?.uid;
      final remoteUserId = call.callerId == currentUserId ? call.calleeId : call.callerId;

      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(remoteUserId)
          .get();

      if (userSnapshot.exists && userSnapshot.data() != null) {
        _remoteUser = UserModel.fromJson(userSnapshot.data()!);
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      // Start timer if already active
      if (call.status == CallStatus.active && _callTimer == null) {
        _startCallTimer();
      }

      // Listen for remote end/decline/active events in Firestore
      _callSubscription = FirebaseFirestore.instance
          .collection('calls')
          .doc(widget.callId)
          .snapshots()
          .listen((snapshot) {
        if (!snapshot.exists) {
          _endCallAndPop('Call ended.');
          return;
        }
        final data = snapshot.data();
        if (data != null) {
          final updated = CallModel.fromJson(data, snapshot.id);
          if (updated.status == CallStatus.declined) {
            _endCallAndPop('Call was declined');
          } else if (updated.status == CallStatus.ended ||
              updated.status == CallStatus.missed) {
            _endCallAndPop('Call ended');
          } else if (updated.status == CallStatus.active) {
            if (mounted && _callTimer == null) {
              _startCallTimer();
            }
          }
        }
      });

      // Hook up Agora real-time events
      final agora = ref.read(agoraServiceProvider);
      agora.onUserJoined = (uid) {
        debugPrint('Agora remote user joined: $uid');
        if (mounted) {
          setState(() {
            _remoteUid = uid;
            if (_callTimer == null) _startCallTimer();
          });
        }
      };
      agora.onUserOffline = (uid) {
        debugPrint('Agora remote user offline: $uid');
        if (mounted) {
          setState(() {
            _remoteUid = null;
          });
        }
      };

      // Ensure Agora is joined to channel
      await agora.joinChannel(
        channelName: call.channelName,
        token: call.agoraToken ?? '',
        uid: 0,
        withVideo: call.type == CallType.video,
      );

    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }
  
  void _startCallTimer() {
    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });
  }

  String _formatDuration(int seconds) {
    final int hours = seconds ~/ 3600;
    final int minutes = (seconds % 3600) ~/ 60;
    final int remainingSeconds = seconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _endCall() async {
    try {
      // Mark as ended in Firestore directly so the other party exits immediately
      await ref.read(firestoreServiceProvider).updateCallStatus(widget.callId, 'ended');
      await ref.read(callNotifierProvider.notifier).endCall();
    } catch (e) {
      debugPrint('Error ending call: $e');
    } finally {
      _endCallAndPop('Call ended');
    }
  }
  
  void _endCallAndPop(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
        ),
      );
      if (GoRouter.of(context).canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
    }
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    ref.read(agoraServiceProvider).toggleMute(_isMuted);
  }

  void _toggleVideo() {
    setState(() {
      _isVideoOn = !_isVideoOn;
    });
    ref.read(callNotifierProvider.notifier).toggleCamera();
  }
  
  void _switchCamera() {
    ref.read(agoraServiceProvider).switchCamera();
  }
  
  void _toggleSpeaker() {
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
    });
    ref.read(agoraServiceProvider).toggleSpeaker(_isSpeakerOn);
  }

  @override
  void dispose() {
    _callSubscription?.cancel();
    _callTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1B231E),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF8DA399)),
        ),
      );
    }

    if (_errorMessage.isNotEmpty || _call == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF1B231E),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Error: $_errorMessage',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      );
    }

    final isVideoCall = _call!.type == CallType.video;
    final isAgoraConfigured = AppConfig.agoraAppId.isNotEmpty &&
        AppConfig.agoraAppId != 'YOUR_AGORA_APP_ID';

    return Scaffold(
      backgroundColor: const Color(0xFF1B231E),
      body: SafeArea(
        child: Column(
          children: [
            // Warning Banner if Agora App ID is not set
            if (!isAgoraConfigured)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade900.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Add your Agora App ID in app_config.dart to enable live audio transmission',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Main View (Audio or Video) - Expanded fills available space
            Expanded(
              child: isVideoCall ? _buildVideoLayout() : _buildAudioLayout(),
            ),

            // Bottom Control Bar - ALWAYS VISIBLE AT BOTTOM
            Padding(
              padding: const EdgeInsets.only(bottom: 24, top: 8),
              child: _buildControlBar(isVideoCall),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoLayout() {
    final agora = ref.read(agoraServiceProvider);

    return Stack(
      children: [
        // Remote Video View
        if (_remoteUid != null && agora.isInitialized)
          Positioned.fill(child: agora.remoteVideoView(_remoteUid!))
        else
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: const Color(0xFF8DA399),
                  backgroundImage: (_remoteUser?.photoUrl != null &&
                          _remoteUser!.photoUrl!.isNotEmpty)
                      ? NetworkImage(_remoteUser!.photoUrl!)
                      : null,
                  child: (_remoteUser?.photoUrl == null ||
                          _remoteUser!.photoUrl!.isEmpty)
                      ? Text(
                          _remoteUser != null &&
                                  _remoteUser!.username.isNotEmpty
                              ? _remoteUser!.username.substring(0, 1).toUpperCase()
                              : '?',
                          style: const TextStyle(fontSize: 48, color: Colors.white),
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  _remoteUser?.username ?? 'Connecting...',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _remoteUid != null ? 'Connected' : 'Waiting for video...',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          
        // Local Video (PiP)
        if (_isVideoOn && agora.isInitialized && agora.localVideoView != null)
          Positioned(
            left: _pipPosition.dx,
            top: _pipPosition.dy,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _pipPosition += details.delta;
                });
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 110,
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF8DA399), width: 2),
                  ),
                  child: agora.localVideoView!,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAudioLayout() {
    final isConnected = _remoteUid != null || _call?.status == CallStatus.active;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
            // User Avatar
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isConnected ? const Color(0xFF8DA399) : Colors.white24,
                  width: 3,
                ),
              ),
              child: CircleAvatar(
                radius: 70,
                backgroundColor: const Color(0xFF8DA399),
                backgroundImage: (_remoteUser?.photoUrl != null &&
                        _remoteUser!.photoUrl!.isNotEmpty)
                    ? NetworkImage(_remoteUser!.photoUrl!)
                    : null,
                child: (_remoteUser?.photoUrl == null ||
                        _remoteUser!.photoUrl!.isEmpty)
                    ? Text(
                        _remoteUser != null && _remoteUser!.username.isNotEmpty
                            ? _remoteUser!.username.substring(0, 1).toUpperCase()
                            : '?',
                        style: const TextStyle(fontSize: 56, color: Colors.white),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 24),
            // Username
            Text(
              _remoteUser?.username ?? 'Unknown',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            // Status text
            Text(
              isConnected ? 'Connected' : 'Calling...',
              style: TextStyle(
                fontSize: 16,
                color: isConnected ? const Color(0xFF8DA399) : Colors.white54,
                fontWeight: FontWeight.w500,
              ),
            ),
            // Timer
            if (_elapsedSeconds > 0) ...[
              const SizedBox(height: 8),
              Text(
                _formatDuration(_elapsedSeconds),
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  letterSpacing: 1.0,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ],
        ),
      );
    }

  Widget _buildControlBar(bool isVideo) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF242E28),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mute Mic Button
          _buildActionButton(
            icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
            label: _isMuted ? 'Unmute' : 'Mute',
            isActive: _isMuted,
            activeColor: Colors.redAccent,
            defaultColor: const Color(0xFF333E37),
            onTap: _toggleMute,
          ),
          if (!isVideo)
            // Speaker Button
            _buildActionButton(
              icon: _isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_down_rounded,
              label: _isSpeakerOn ? 'Speaker' : 'Earpiece',
              isActive: _isSpeakerOn,
              activeColor: const Color(0xFF8DA399),
              defaultColor: const Color(0xFF333E37),
              onTap: _toggleSpeaker,
            ),
          if (isVideo) ...[
            // Video Toggle Button
            _buildActionButton(
              icon: _isVideoOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
              label: _isVideoOn ? 'Camera' : 'Cam Off',
              isActive: !_isVideoOn,
              activeColor: Colors.redAccent,
              defaultColor: const Color(0xFF333E37),
              onTap: _toggleVideo,
            ),
            // Switch Camera
            _buildActionButton(
              icon: Icons.flip_camera_ios_rounded,
              label: 'Flip',
              defaultColor: const Color(0xFF333E37),
              onTap: _switchCamera,
            ),
          ],
          // Call End Button
          _buildActionButton(
            icon: Icons.call_end_rounded,
            label: 'End',
            isActive: true,
            activeColor: const Color(0xFFE53935),
            size: 56,
            iconSize: 28,
            onTap: _endCall,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
    Color? activeColor,
    Color defaultColor = const Color(0xFF333E37),
    double size = 50,
    double iconSize = 24,
  }) {
    final bgColor = isActive ? (activeColor ?? Colors.redAccent) : defaultColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(size / 2),
            onTap: onTap,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: bgColor,
              ),
              child: Icon(icon, color: Colors.white, size: iconSize),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
