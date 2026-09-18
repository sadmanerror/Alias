import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:alias/models/message_model.dart';

/// Messenger-style media preview screen shown before sending image/video.
/// User can add an optional caption and confirm or cancel.
class MediaPreviewSheet extends StatefulWidget {
  final File file;
  final MessageType type;
  final void Function(File file, MessageType type, String? caption) onSend;

  const MediaPreviewSheet({
    super.key,
    required this.file,
    required this.type,
    required this.onSend,
  });

  @override
  State<MediaPreviewSheet> createState() => _MediaPreviewSheetState();
}

class _MediaPreviewSheetState extends State<MediaPreviewSheet> {
  static const Color _sage = Color(0xFF8DA399);

  final TextEditingController _captionController = TextEditingController();
  VideoPlayerController? _videoController;
  bool _videoInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.type == MessageType.video) {
      _videoController = VideoPlayerController.file(widget.file)
        ..initialize().then((_) {
          if (mounted) setState(() => _videoInitialized = true);
        });
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _send() {
    final caption = _captionController.text.trim();
    widget.onSend(widget.file, widget.type, caption.isNotEmpty ? caption : null);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.type == MessageType.video ? 'Video Preview' : 'Photo Preview',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Media Preview ───────────────────────────────────────────────
          Expanded(
            child: Center(
              child: widget.type == MessageType.image
                  ? _buildImagePreview()
                  : _buildVideoPreview(),
            ),
          ),

          // ── Caption + Send Bar ──────────────────────────────────────────
          Container(
            color: const Color(0xFF1A1A1A),
            padding: EdgeInsets.only(
              left: 16,
              right: 8,
              top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 8,
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _captionController,
                      maxLines: 4,
                      minLines: 1,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Add a caption...',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: const Color(0xFF2C2C2C),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _send,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: _sage,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return InteractiveViewer(
      child: Image.file(
        widget.file,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white54, size: 64),
      ),
    );
  }

  Widget _buildVideoPreview() {
    if (!_videoInitialized || _videoController == null) {
      return const CircularProgressIndicator(color: _sage);
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: VideoPlayer(_videoController!),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              if (_videoController!.value.isPlaying) {
                _videoController!.pause();
              } else {
                _videoController!.play();
              }
            });
          },
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.black38,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(12),
            child: Icon(
              _videoController!.value.isPlaying
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
        ),
      ],
    );
  }
}

