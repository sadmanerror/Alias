import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:audio_waveforms/audio_waveforms.dart';

class AudioPlayerBubble extends StatefulWidget {
  final String audioUrl;
  final List<double>? waveformData;
  final int? durationSeconds;
  final bool isSender;

  const AudioPlayerBubble({
    super.key,
    required this.audioUrl,
    this.waveformData,
    this.durationSeconds,
    required this.isSender,
  });

  @override
  State<AudioPlayerBubble> createState() => _AudioPlayerBubbleState();
}

class _AudioPlayerBubbleState extends State<AudioPlayerBubble> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  late StreamSubscription _positionSubscription;
  late StreamSubscription _durationSubscription;
  late StreamSubscription _playerCompleteSubscription;
  late PlayerController _waveformController;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _waveformController = PlayerController();

    _positionSubscription = _audioPlayer.onPositionChanged.listen((p) {
      setState(() => _currentPosition = p);
    });
    
    _durationSubscription = _audioPlayer.onDurationChanged.listen((d) {
      setState(() => _totalDuration = d);
    });

    _playerCompleteSubscription = _audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        _isPlaying = false;
        _currentPosition = Duration.zero;
      });
    });
  }

  @override
  void dispose() {
    _positionSubscription.cancel();
    _durationSubscription.cancel();
    _playerCompleteSubscription.cancel();
    _audioPlayer.dispose();
    _waveformController.dispose();
    super.dispose();
  }

  void _togglePlay() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(UrlSource(widget.audioUrl));
    }
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = widget.isSender ? const Color(0xFF8DA399) : Colors.white;
    final buttonBg = widget.isSender ? Colors.white : const Color(0xFF8DA399);
    final waveColor = widget.isSender ? Colors.white : const Color(0xFF8DA399);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _togglePlay,
          child: CircleAvatar(
            radius: 16,
            backgroundColor: buttonBg,
            child: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: iconColor,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 100,
          height: 30,
          child: widget.waveformData != null
              ? AudioFileWaveforms(
                  size: const Size(100, 30),
                  playerController: _waveformController,
                  playerWaveStyle: PlayerWaveStyle(
                    fixedWaveColor: waveColor.withValues(alpha: 0.5),
                    liveWaveColor: waveColor,
                    spacing: 4,
                  ),
                )
              : Row(
                  children: List.generate(20, (index) {
                    final height = 10 + (index % 5) * 4.0;
                    return Container(
                      width: 3,
                      height: height,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: waveColor.withValues(alpha: _currentPosition.inSeconds > 0 ? 1 : 0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ),
        ),
        const SizedBox(width: 8),
        Text(
          _formatDuration(_totalDuration.inSeconds > 0 ? _currentPosition : Duration(seconds: widget.durationSeconds ?? 0)),
          style: TextStyle(
            color: widget.isSender ? Colors.white : const Color(0xFF2C3E35),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
