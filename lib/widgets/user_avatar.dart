import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class UserAvatar extends StatefulWidget {
  final String? photoUrl;
  final String username;
  final double size;
  final bool showOnlineBadge;
  final bool isOnline;

  const UserAvatar({
    super.key,
    this.photoUrl,
    required this.username,
    this.size = 40.0,
    this.showOnlineBadge = false,
    this.isOnline = false,
  });

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  bool _hasError = false;

  @override
  void didUpdateWidget(covariant UserAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photoUrl != widget.photoUrl) {
      _hasError = false;
    }
  }

  ImageProvider? _getImageProvider() {
    final photo = widget.photoUrl;
    if (_hasError || photo == null || photo.trim().isEmpty) return null;
    if (photo.startsWith('data:image')) {
      try {
        final base64Str = photo.split(',').last;
        return MemoryImage(base64Decode(base64Str));
      } catch (_) {
        return null;
      }
    }
    return CachedNetworkImageProvider(photo);
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = _getImageProvider();
    final Widget avatar = CircleAvatar(
      radius: widget.size / 2,
      backgroundColor: const Color(0xFF8DA399),
      backgroundImage: imageProvider,
      onBackgroundImageError: imageProvider != null
          ? (_, __) {
              if (mounted && !_hasError) {
                setState(() {
                  _hasError = true;
                });
              }
            }
          : null,
      child: (imageProvider == null)
          ? Text(
              widget.username.isNotEmpty ? widget.username[0].toUpperCase() : '?',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: widget.size * 0.4,
              ),
            )
          : null,
    );

    if (widget.showOnlineBadge) {
      return Stack(
        children: [
          avatar,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: widget.size * 0.3,
              height: widget.size * 0.3,
              decoration: BoxDecoration(
                color: widget.isOnline ? const Color(0xFF4CAF50) : const Color(0xFF6B7C74),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ],
      );
    }

    return avatar;
  }
}

class ShimmerChatTile extends StatelessWidget {
  const ShimmerChatTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.white,
        ),
        title: Container(
          width: 100,
          height: 16,
          color: Colors.white,
        ),
        subtitle: Container(
          width: 200,
          height: 12,
          color: Colors.white,
          margin: const EdgeInsets.only(top: 8),
        ),
      ),
    );
  }
}
