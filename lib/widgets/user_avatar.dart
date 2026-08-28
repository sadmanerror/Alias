import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class UserAvatar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final Widget avatar = CircleAvatar(
      radius: size / 2,
      backgroundColor: const Color(0xFF8DA399),
      backgroundImage: photoUrl != null && photoUrl!.isNotEmpty
          ? CachedNetworkImageProvider(photoUrl!)
          : null,
      child: (photoUrl == null || photoUrl!.isEmpty)
          ? Text(
              username.isNotEmpty ? username[0].toUpperCase() : '?',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: size * 0.4,
              ),
            )
          : null,
    );

    if (showOnlineBadge) {
      return Stack(
        children: [
          avatar,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.3,
              height: size * 0.3,
              decoration: BoxDecoration(
                color: isOnline ? const Color(0xFF4CAF50) : const Color(0xFF6B7C74),
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
