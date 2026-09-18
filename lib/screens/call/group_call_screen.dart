import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:alias/models/user_model.dart';
import 'package:alias/providers/call_provider.dart';
import 'package:alias/providers/auth_provider.dart';
import 'package:alias/services/notification_service.dart';

// ── Group Call Screen ─────────────────────────────────────────────────────────
class GroupCallScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String groupName;

  const GroupCallScreen({
    super.key,
    required this.chatId,
    required this.groupName,
  });

  @override
  ConsumerState<GroupCallScreen> createState() => _GroupCallScreenState();
}

class _GroupCallScreenState extends ConsumerState<GroupCallScreen> {
  static const Color _sage = Color(0xFF8DA399);
  static const Color _bg = Color(0xFF1B231E);

  bool _isMuted = false;
  bool _isSpeakerOn = true;
  bool _isLoading = true;

  Timer? _callTimer;
  int _elapsedSeconds = 0;

  List<UserModel> _participants = [];
  StreamSubscription<DocumentSnapshot>? _callSub;

  // Ringtone for incoming group call
  final AudioPlayer _ringtonePlayer = AudioPlayer();
  bool _isRinging = false;

  @override
  void initState() {
    super.initState();
    _initGroupCall();
  }

  String get _callDocId => '${widget.chatId}_group';

  Future<void> _initGroupCall() async {
    final currentUid = ref.read(authStateProvider).value?.uid ?? '';
    final docRef = FirebaseFirestore.instance.collection('calls').doc(_callDocId);
    final snap = await docRef.get();

    if (!snap.exists) {
      // We are the initiator — create the call doc
      await docRef.set({
        'chatId': widget.chatId,
        'groupName': widget.groupName,
        'status': 'active',
        'participants': [currentUid],
        'startedAt': FieldValue.serverTimestamp(),
      });
    } else {
      // We are joining — add ourselves
      await docRef.update({
        'participants': FieldValue.arrayUnion([currentUid]),
      });

      final data = snap.data();
      if (data?['status'] == 'ringing') {
        _startRingtone();
      }
    }

    // Load participant profiles
    await _loadParticipants(snap.data()?['participants'] ?? [currentUid]);

    // Start call timer
    _startTimer();

    // Initialize Agora
    final agora = ref.read(agoraServiceProvider);
    await agora.joinChannel(
      channelName: widget.chatId,
      token: '',
      uid: 0,
      withVideo: false,
    );

    // Listen to Firestore for participants & status changes
    _callSub = docRef.snapshots().listen((s) async {
      if (!s.exists) {
        _stopRingtone();
        _leaveAndPop();
        return;
      }
      final data = s.data()!;
      if (data['status'] == 'ended') {
        _stopRingtone();
        _leaveAndPop();
        return;
      }
      if (data['status'] == 'active') {
        _stopRingtone();
      }
      final uids = List<String>.from(data['participants'] ?? []);
      await _loadParticipants(uids);
    });

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadParticipants(List<dynamic> uids) async {
    final users = <UserModel>[];
    for (final uid in uids) {
      final snap = await FirebaseFirestore.instance.collection('users').doc(uid.toString()).get();
      if (snap.exists && snap.data() != null) {
        users.add(UserModel.fromJson(snap.data()!));
      }
    }
    if (mounted) setState(() => _participants = users);
  }

  void _startTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  Future<void> _startRingtone() async {
    if (_isRinging) return;
    _isRinging = true;
    try {
      await _ringtonePlayer.setReleaseMode(ReleaseMode.loop);
      await _ringtonePlayer.play(AssetSource('audio/iphone_ringtone.mp3'));
    } catch (e) {
      debugPrint('Group ringtone error: $e');
    }
  }

  Future<void> _stopRingtone() async {
    if (!_isRinging) return;
    _isRinging = false;
    try {
      await _ringtonePlayer.stop();
    } catch (_) {}
  }

  Future<void> _leaveCall() async {
    _stopRingtone();
    final currentUid = ref.read(authStateProvider).value?.uid ?? '';
    final docRef = FirebaseFirestore.instance.collection('calls').doc(_callDocId);
    try {
      await docRef.update({
        'participants': FieldValue.arrayRemove([currentUid]),
      });
      // Check if anyone is left; if not, end the call
      final snap = await docRef.get();
      final remaining = List.from(snap.data()?['participants'] ?? []);
      if (remaining.isEmpty) {
        await docRef.update({'status': 'ended'});
      }
    } catch (_) {}

    await ref.read(agoraServiceProvider).leaveChannel();
    NotificationService.instance.cancelCallNotification();
    _leaveAndPop();
  }

  void _leaveAndPop() {
    if (mounted) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
    }
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    ref.read(agoraServiceProvider).toggleMute(_isMuted);
  }

  void _toggleSpeaker() {
    setState(() => _isSpeakerOn = !_isSpeakerOn);
    ref.read(agoraServiceProvider).toggleSpeaker(_isSpeakerOn);
  }

  String _formatDuration(int s) {
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _callSub?.cancel();
    _callTimer?.cancel();
    _ringtonePlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            Text(
              widget.groupName,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
            ),
            if (_elapsedSeconds > 0)
              Text(
                _formatDuration(_elapsedSeconds),
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _leaveCall,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _sage))
          : Column(
              children: [
                // ── Participants Grid ────────────────────────────────────
                Expanded(
                  child: _participants.isEmpty
                      ? const Center(
                          child: Text('Connecting...', style: TextStyle(color: Colors.white54)),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(24),
                          child: GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: _participants.length,
                            itemBuilder: (_, i) => _buildParticipantTile(_participants[i]),
                          ),
                        ),
                ),

                // ── Control Bar ──────────────────────────────────────────
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF242E28),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildBtn(
                        icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                        label: _isMuted ? 'Unmute' : 'Mute',
                        color: _isMuted ? Colors.redAccent : const Color(0xFF333E37),
                        onTap: _toggleMute,
                      ),
                      _buildBtn(
                        icon: _isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                        label: 'Speaker',
                        color: _isSpeakerOn ? _sage : const Color(0xFF333E37),
                        onTap: _toggleSpeaker,
                      ),
                      _buildBtn(
                        icon: Icons.call_end_rounded,
                        label: 'Leave',
                        color: const Color(0xFFE53935),
                        onTap: _leaveCall,
                        size: 56,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildParticipantTile(UserModel user) {
    final currentUid = ref.read(authStateProvider).value?.uid;
    final isMe = user.uid == currentUid;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF242E28),
        borderRadius: BorderRadius.circular(16),
        border: isMe
            ? Border.all(color: _sage, width: 2)
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: _sage,
            backgroundImage: (user.photoUrl != null && user.photoUrl!.isNotEmpty)
                ? NetworkImage(user.photoUrl!)
                : null,
            child: (user.photoUrl == null || user.photoUrl!.isEmpty)
                ? Text(
                    user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 24, color: Colors.white),
                  )
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            isMe ? 'You' : user.username,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
          ),
          if (_isMuted && isMe)
            const Icon(Icons.mic_off, color: Colors.red, size: 14),
        ],
      ),
    );
  }

  Widget _buildBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    double size = 50,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: size * 0.5),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}

