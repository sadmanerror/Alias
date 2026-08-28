import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:alias/models/message_model.dart';
import 'audio_player_bubble.dart';
import 'gif_bubble.dart';

class ChatBubble extends StatefulWidget {
  final MessageModel message;
  final bool isSender;
  final String? partnerPhotoUrl;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isSender,
    this.partnerPhotoUrl,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  bool _showDetails = false;

  String _formatTime(DateTime? dt) {
    if (dt == null) return '--:--';
    return DateFormat('HH:mm').format(dt);
  }

  String _formatFullTime(DateTime? dt) {
    if (dt == null) return 'Pending';
    return DateFormat('hh:mm:ss a, dd MMM').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final isSender = widget.isSender;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Column(
        crossAxisAlignment: isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isSender ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isSender) ...[
                CircleAvatar(
                  radius: 14,
                  backgroundColor: const Color(0xFF8DA399),
                  backgroundImage: widget.partnerPhotoUrl != null
                      ? CachedNetworkImageProvider(widget.partnerPhotoUrl!)
                      : null,
                  child: widget.partnerPhotoUrl == null
                      ? const Icon(Icons.person, size: 16, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _showDetails = !_showDetails;
                    });
                  },
                  onLongPress: () => _showContextMenu(context),
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    padding: message.type == MessageType.image || message.type == MessageType.gif
                        ? EdgeInsets.zero
                        : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: message.type == MessageType.gif
                        ? null
                        : BoxDecoration(
                            color: isSender ? const Color(0xFF8DA399) : const Color(0xFFE8DCC4),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isSender ? 16 : 4),
                              bottomRight: Radius.circular(isSender ? 4 : 16),
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                offset: Offset(0, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildContent(context),
                        if (message.type != MessageType.gif) const SizedBox(height: 4),
                        if (message.type != MessageType.gif)
                          Wrap(
                            alignment: WrapAlignment.end,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                _formatTime(message.timestamp),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isSender ? Colors.white70 : const Color(0xFF6B7C74),
                                ),
                              ),
                              if (isSender) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  message.isRead
                                      ? Icons.done_all
                                      : (message.isDelivered ? Icons.done_all : Icons.done),
                                  size: 14,
                                  color: message.isRead
                                      ? Colors.blue.shade700
                                      : (isSender ? Colors.white70 : const Color(0xFF6B7C74)),
                                ),
                              ],
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (isSender) const SizedBox(width: 8),
            ],
          ),
          
          // Delivered & Seen Time Info Bar (WhatsApp style)
          if (isSender && (message.isDelivered || message.isRead))
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 12, bottom: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (message.isDelivered) ...[
                    Icon(Icons.done_all, size: 11, color: message.isRead ? Colors.grey.shade500 : Colors.grey.shade600),
                    const SizedBox(width: 2),
                    Text(
                      'Delivered: ${_formatTime(message.deliveredAt ?? message.timestamp)}',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                    ),
                  ],
                  if (message.isRead) ...[
                    if (message.isDelivered)
                      Text(
                        '  |  ',
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                      ),
                    Icon(Icons.done_all, size: 11, color: Colors.blue.shade700),
                    const SizedBox(width: 2),
                    Text(
                      'Seen: ${_formatTime(message.readAt ?? message.timestamp)}',
                      style: TextStyle(fontSize: 10, color: Colors.blue.shade800, fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final message = widget.message;
    final isSender = widget.isSender;

    switch (message.type) {
      case MessageType.text:
        return Text(
          message.content ?? '',
          style: TextStyle(
            color: isSender ? const Color(0xFFFFFFFF) : const Color(0xFF2C3E35),
            fontSize: 15,
          ),
        );
      case MessageType.image:
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CachedNetworkImage(
            imageUrl: message.mediaUrl ?? '',
            fit: BoxFit.cover,
            placeholder: (context, url) => const SizedBox(
              width: 200,
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => const Icon(Icons.broken_image),
          ),
        );
      case MessageType.video:
        return Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: message.thumbnailUrl ?? '',
                fit: BoxFit.cover,
                placeholder: (context, url) => const SizedBox(
                  width: 200,
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) =>
                    Container(width: 200, height: 200, color: Colors.black12),
              ),
            ),
            const Icon(Icons.play_circle_fill, size: 50, color: Colors.white),
          ],
        );
      case MessageType.audio:
        return AudioPlayerBubble(
          audioUrl: message.mediaUrl ?? '',
          durationSeconds: message.duration,
          isSender: isSender,
        );
      case MessageType.gif:
        return GifBubble(
          gifUrl: message.gifUrl ?? message.mediaUrl ?? '',
          isSender: isSender,
          timestamp: message.timestamp,
        );
      case MessageType.file:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insert_drive_file, color: isSender ? Colors.white : const Color(0xFF2C3E35)),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message.fileName ?? 'Unknown file',
                    style: TextStyle(
                      color: isSender ? Colors.white : const Color(0xFF2C3E35),
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${((message.fileSize ?? 0) / 1024).toStringAsFixed(1)} KB',
                    style: TextStyle(
                      color: isSender ? Colors.white70 : const Color(0xFF6B7C74),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
    }
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline, color: Color(0xFF8DA399)),
                title: const Text('Message Info'),
                subtitle: const Text('View sent, delivered, and seen timestamps'),
                onTap: () {
                  Navigator.pop(context);
                  _showMessageInfoDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMessageInfoDialog(BuildContext context) {
    final message = widget.message;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Message Info', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(
              icon: Icons.access_time,
              label: 'Sent',
              time: _formatFullTime(message.timestamp),
              color: Colors.black87,
            ),
            const Divider(),
            _buildInfoRow(
              icon: Icons.done_all,
              label: 'Delivered',
              time: message.isDelivered
                  ? _formatFullTime(message.deliveredAt ?? message.timestamp)
                  : 'Pending',
              color: message.isDelivered ? Colors.black87 : Colors.grey,
            ),
            const Divider(),
            _buildInfoRow(
              icon: Icons.done_all,
              label: 'Seen',
              time: message.isRead
                  ? _formatFullTime(message.readAt ?? message.timestamp)
                  : 'Not seen yet',
              color: message.isRead ? Colors.blue.shade700 : Colors.grey,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String time,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(time, style: TextStyle(color: color, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
