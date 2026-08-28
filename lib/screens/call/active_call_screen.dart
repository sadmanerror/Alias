import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:alias/models/call_model.dart';
import 'package:alias/models/user_model.dart';
import 'package:alias/providers/call_provider.dart';

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
  bool _showControls = true;
  Timer? _controlsTimer;

  Offset _pipPosition = const Offset(16, 100); // Initial PiP position

  @override
  void initState() {
    super.initState();
    _initCallData();
    _startControlsTimer();
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
      
      final call = CallModel.fromJson(callSnapshot.data()!);
      _call = call;
      _isVideoOn = call.type == CallType.video;

      final remoteUserId = call.callerId == call.callerId ? call.calleeId : call.callerId;

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

      // Simulate Agora callbacks for the sake of UI
      // In a real app, you would listen to AgoraRtcEngineEventHandler
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _remoteUid = 12345; // Dummy remote uid
            _startCallTimer();
          });
        }
      });

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

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    if (mounted) {
      setState(() => _showControls = true);
    }
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    if (_showControls) {
      _controlsTimer?.cancel();
      setState(() => _showControls = false);
    } else {
      _startControlsTimer();
    }
  }

  Future<void> _endCall() async {
    try {
      if (_call != null) {
        await ref.read(callNotifierProvider.notifier).endCall();
      }
      _endCallAndPop('Call ended');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to end call: $e')),
        );
      }
    }
  }
  
  void _endCallAndPop(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
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
    ref.read(callNotifierProvider.notifier).toggleMute();
  }

  void _toggleVideo() {
    setState(() {
      _isVideoOn = !_isVideoOn;
    });
    ref.read(callNotifierProvider.notifier).toggleCamera();
  }
  
  void _switchCamera() {
    // ref.read(callNotifierProvider.notifier).switchCamera();
  }
  
  void _toggleSpeaker() {
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
    });
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _controlsTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_errorMessage.isNotEmpty || _call == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Error: $_errorMessage',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final isVideoCall = _call!.type == CallType.video;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: SafeArea(
          child: Stack(
            children: [
              // Main View
              if (isVideoCall)
                _buildVideoLayout()
              else
                _buildAudioLayout(),
                
              // Top Bar (Timer)
              if (_remoteUid != null && _showControls)
                Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _formatDuration(_elapsedSeconds),
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ),

              // Bottom Control Bar
              if (_showControls)
                Positioned(
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: _buildControlBar(isVideoCall),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoLayout() {
    return Stack(
      children: [
        // Remote Video
        if (_remoteUid != null)
          const Center(
            child: Text('Remote Video View Placeholder', style: TextStyle(color: Colors.white)),
            // In real code: AgoraVideoView(controller: VideoViewController.remote(...))
          )
        else
          const Center(
            child: Text('Waiting for user to join...', style: TextStyle(color: Colors.white)),
          ),
          
        // Local Video (PiP)
        if (_isVideoOn)
          Positioned(
            left: _pipPosition.dx,
            top: _pipPosition.dy,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _pipPosition += details.delta;
                });
              },
              child: Container(
                width: 100,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24, width: 2),
                ),
                child: const Center(
                  child: Text('Local', style: TextStyle(color: Colors.white)),
                  // In real code: AgoraVideoView(controller: VideoViewController(...))
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAudioLayout() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 80,
            backgroundColor: const Color(0xFF8DA399),
            backgroundImage: (_remoteUser?.photoUrl != null && _remoteUser!.photoUrl!.isNotEmpty)
                ? NetworkImage(_remoteUser!.photoUrl!)
                : null,
            child: (_remoteUser?.photoUrl == null || _remoteUser!.photoUrl!.isEmpty)
                ? Text(
                    _remoteUser != null && _remoteUser!.username.isNotEmpty
                        ? _remoteUser!.username.substring(0, 1).toUpperCase()
                        : '?',
                    style: const TextStyle(fontSize: 64, color: Colors.white),
                  )
                : null,
          ),
          const SizedBox(height: 32),
          Text(
            _remoteUser?.username ?? 'Unknown',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _remoteUid != null ? 'Connected' : 'Connecting...',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlBar(bool isVideo) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      color: Colors.black45,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: _isMuted ? Icons.mic_off : Icons.mic,
            isActive: !_isMuted,
            onTap: _toggleMute,
          ),
          if (isVideo) ...[
            _buildControlButton(
              icon: _isVideoOn ? Icons.videocam : Icons.videocam_off,
              isActive: _isVideoOn,
              onTap: _toggleVideo,
            ),
            _buildControlButton(
              icon: Icons.flip_camera_ios,
              isActive: true,
              onTap: _switchCamera,
            ),
          ],
          if (!isVideo)
            _buildControlButton(
              icon: _isSpeakerOn ? Icons.volume_up : Icons.hearing,
              isActive: _isSpeakerOn,
              onTap: _toggleSpeaker,
            ),
          GestureDetector(
            onTap: _endCall,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.redAccent,
              ),
              child: const Icon(
                Icons.call_end,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? Colors.white24 : Colors.white,
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : Colors.black,
          size: 28,
        ),
      ),
    );
  }
}
