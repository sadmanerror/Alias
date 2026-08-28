import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:alias/models/call_model.dart';
import 'package:alias/models/user_model.dart';
import 'package:alias/providers/call_provider.dart';

class IncomingCallScreen extends ConsumerStatefulWidget {
  final String callId;

  const IncomingCallScreen({super.key, required this.callId});

  @override
  ConsumerState<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends ConsumerState<IncomingCallScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription<DocumentSnapshot>? _callSubscription;
  Timer? _autoDismissTimer;

  CallModel? _call;
  UserModel? _caller;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: false);

    _initCallData();
  }

  Future<void> _initCallData() async {
    try {
      // Setup listener for call status changes
      _callSubscription = FirebaseFirestore.instance
          .collection('calls')
          .doc(widget.callId)
          .snapshots()
          .listen((snapshot) {
        if (!snapshot.exists) {
          _handleMissedCall();
          return;
        }

        final callData = snapshot.data();
        if (callData != null) {
          final call = CallModel.fromJson(callData);
          if (mounted) {
            setState(() {
              _call = call;
            });
            if (call.status == CallStatus.ended || call.status == CallStatus.missed || call.status == CallStatus.declined) {
              _handleMissedCall();
            }
          }
        }
      });

      // Initial fetch to get the caller details
      final callSnapshot = await FirebaseFirestore.instance
          .collection('calls')
          .doc(widget.callId)
          .get();
      
      if (!callSnapshot.exists) {
        _handleMissedCall();
        return;
      }
      
      final call = CallModel.fromJson(callSnapshot.data()!);
      _call = call;

      final callerSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(call.callerId)
          .get();

      if (callerSnapshot.exists && callerSnapshot.data() != null) {
        _caller = UserModel.fromJson(callerSnapshot.data()!);
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      // Play ringtone
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      // Assuming you have an asset named 'ringtone.mp3' in your assets folder
      // await _audioPlayer.play(AssetSource('audio/ringtone.mp3'));

      // Auto dismiss after 60 seconds
      _autoDismissTimer = Timer(const Duration(seconds: 60), () {
        _handleMissedCall();
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

  void _handleMissedCall() {
    _stopRingtone();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missed call')),
      );
      if (GoRouter.of(context).canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
    }
  }

  void _stopRingtone() {
    _audioPlayer.stop();
  }

  Future<void> _acceptCall() async {
    if (_call == null) return;
    _stopRingtone();
    _autoDismissTimer?.cancel();
    
    try {
      await ref.read(callNotifierProvider.notifier).acceptCall(_call!);
      if (mounted) {
        context.go('/active-call/${widget.callId}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept call: $e')),
        );
      }
    }
  }

  Future<void> _declineCall() async {
    if (_call == null) return;
    _stopRingtone();
    _autoDismissTimer?.cancel();
    
    try {
      await ref.read(callNotifierProvider.notifier).declineCall(_call!);
      if (mounted) {
        if (GoRouter.of(context).canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to decline call: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _audioPlayer.dispose();
    _callSubscription?.cancel();
    _autoDismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF2C3E35),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_errorMessage.isNotEmpty || _caller == null || _call == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF2C3E35),
        body: Center(
          child: Text(
            'Error: $_errorMessage',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final isVideo = _call!.type == CallType.video;

    return Scaffold(
      backgroundColor: const Color(0xFF2C3E35),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2C3E35), Color(0xFF1A2520)],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Avatar with pulsing rings
              Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Container(
                        width: 120 + (_animationController.value * 60),
                        height: 120 + (_animationController.value * 60),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(
                              alpha: (1 - _animationController.value) * 0.3),
                        ),
                      );
                    },
                  ),
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: const Color(0xFF8DA399),
                    backgroundImage: (_caller?.photoUrl != null && _caller!.photoUrl!.isNotEmpty)
                        ? NetworkImage(_caller!.photoUrl!)
                        : null,
                    child: (_caller?.photoUrl == null || _caller!.photoUrl!.isEmpty)
                        ? Text(
                            _caller != null && _caller!.username.isNotEmpty
                                ? _caller!.username.substring(0, 1).toUpperCase()
                                : '?',
                            style: const TextStyle(
                                fontSize: 48, color: Colors.white),
                          )
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Caller Name
              Text(
                _caller!.username,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              // Subtitle
              Text(
                isVideo ? 'Video Call' : 'Alias Call',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 32),
              // Ringing text
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Ringing',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white54,
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      final dots =
                          '.' * ((_animationController.value * 3).floor() % 4);
                      return Text(
                        dots,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white54,
                        ),
                      );
                    },
                  ),
                ],
              ),
              const Spacer(),
              // Action Buttons
              Padding(
                padding: const EdgeInsets.only(bottom: 60.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Decline
                    Column(
                      children: [
                        GestureDetector(
                          onTap: _declineCall,
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.redAccent,
                            ),
                            child: const Icon(
                              Icons.phone_disabled,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Decline',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                    // Accept
                    Column(
                      children: [
                        GestureDetector(
                          onTap: _acceptCall,
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.green,
                            ),
                            child: Icon(
                              isVideo ? Icons.videocam : Icons.call,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Accept',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
