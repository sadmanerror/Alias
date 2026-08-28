import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:alias/models/call_model.dart';
import 'package:alias/providers/chat_provider.dart';
import 'package:alias/providers/call_provider.dart';
import 'package:alias/providers/auth_provider.dart';
import 'package:alias/screens/chat/emoji_picker_sheet.dart';
import 'package:alias/screens/chat/media_picker_sheet.dart';
import 'package:alias/widgets/chat_bubble.dart';
import 'package:alias/core/utils/date_formatter.dart';
import 'package:alias/services/giphy_service.dart';
import 'package:alias/widgets/user_avatar.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;

  const ChatScreen({super.key, required this.chatId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  static const Color primarySageGreen = Color(0xFF8DA399);
  static const Color offWhite = Color(0xFFF7F7F7);
  static const Color textPrimary = Color(0xFF2C3E35);

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AudioRecorder _audioRecorder = AudioRecorder();
  
  bool _isRecording = false;
  bool _showEmojiPicker = false;
  String _messageText = '';

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() {
      setState(() {
        _messageText = _messageController.text;
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(messageNotifierProvider(widget.chatId)).markAsRead();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    ref.read(messageNotifierProvider(widget.chatId)).sendTextMessage(text);
    _messageController.clear();
    
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final tempDir = await getTemporaryDirectory();
        final path = '${tempDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder.start(const RecordConfig(), path: path);
        setState(() {
          _isRecording = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to start recording: $e')));
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
      });
      if (path != null) {
        ref.read(messageNotifierProvider(widget.chatId)).sendVoiceMessage(File(path), [], 0);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to stop recording: $e')));
      }
    }
  }

  void _showMediaPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => MediaPickerSheet(
        onFilePicked: (file, type) {
          ref.read(messageNotifierProvider(widget.chatId)).sendMediaMessage(file, type);
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _showGifPicker() async {
    final selectedGif = await context.push<dynamic>('/gif-picker/${widget.chatId}');
    if (selectedGif != null && selectedGif is GiphyGif && mounted) {
      ref.read(messageNotifierProvider(widget.chatId)).sendGif(selectedGif);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(authStateProvider).value?.uid ?? '';
    final initialPartnerAsync = ref.watch(chatPartnerProvider(widget.chatId));
    final partnerId = initialPartnerAsync.value?.uid ?? '';
    final livePartnerAsync = partnerId.isNotEmpty ? ref.watch(userProfileProvider(partnerId)) : null;
    final partner = livePartnerAsync?.value ?? initialPartnerAsync.value;
    final messagesAsyncValue = ref.watch(chatMessagesProvider(widget.chatId));

    ref.listen(chatMessagesProvider(widget.chatId), (previous, next) {
      if (next.hasValue && next.value != null && next.value!.isNotEmpty) {
        final hasUnread = next.value!.any((m) => m.senderId != currentUserId && !m.isRead);
        if (hasUnread) {
          ref.read(messageNotifierProvider(widget.chatId)).markAsRead();
        }
      }
    });

    return Scaffold(
      backgroundColor: offWhite,
      appBar: AppBar(
        backgroundColor: offWhite,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: initialPartnerAsync.when(
          data: (_) {
            if (partner == null) return const Text('Chat');
            return Row(
              children: [
                UserAvatar(
                  photoUrl: partner.photoUrl,
                  username: partner.username,
                  size: 38,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        partner.username.isNotEmpty ? partner.username : 'Chat',
                        style: const TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              color: partner.isOnline ? Colors.green : Colors.grey.shade400,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Text(
                            partner.isOnline
                                ? 'Online'
                                : (partner.lastSeen != null
                                    ? DateFormatter.formatLastSeen(partner.lastSeen!)
                                    : 'Offline'),
                            style: TextStyle(
                              color: partner.isOnline ? Colors.green.shade700 : Colors.grey,
                              fontSize: 12,
                              fontWeight: partner.isOnline ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Chat'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam, color: primarySageGreen),
            onPressed: () {
              if (partner != null) {
                ref.read(callNotifierProvider.notifier).initiateCall(
                      calleeId: partner.uid,
                      channelName: widget.chatId,
                      callType: CallType.video,
                    );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.call, color: primarySageGreen),
            onPressed: () {
              if (partner != null) {
                ref.read(callNotifierProvider.notifier).initiateCall(
                      calleeId: partner.uid,
                      channelName: widget.chatId,
                      callType: CallType.audio,
                    );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsyncValue.when(
              data: (messages) {
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return ChatBubble(
                      message: message,
                      isSender: message.senderId == currentUserId,
                      partnerPhotoUrl: partner?.photoUrl,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: primarySageGreen)),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ),
          _buildInputBar(),
          if (_showEmojiPicker)
            EmojiPickerSheet(
              controller: _messageController,
              onEmojiSelected: (emoji) {
                setState(() {
                  _messageText = _messageController.text;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    if (_isRecording) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: Row(
          children: [
            const Icon(Icons.mic, color: Colors.red),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Recording...', style: TextStyle(color: Colors.red)),
            ),
            IconButton(
              icon: const Icon(Icons.stop, color: Colors.red),
              onPressed: _stopRecording,
            ),
          ],
        ),
      );
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                _showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions_outlined,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _showEmojiPicker = !_showEmojiPicker;
                });
              },
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                maxLines: 6,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: offWhite,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.attach_file, color: Colors.grey),
              onPressed: _showMediaPicker,
            ),
            IconButton(
              icon: const Icon(Icons.gif_box_outlined, color: Colors.grey),
              onPressed: _showGifPicker,
            ),
            if (_messageText.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.send, color: Colors.blue),
                onPressed: _sendMessage,
              )
            else
              GestureDetector(
                onLongPressStart: (_) => _startRecording(),
                onLongPressEnd: (_) => _stopRecording(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: primarySageGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mic, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
