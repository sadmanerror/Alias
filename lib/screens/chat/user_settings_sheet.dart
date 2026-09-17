import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alias/models/chat_model.dart';
import 'package:alias/models/user_model.dart';
import 'package:alias/providers/auth_provider.dart';
import 'package:alias/providers/chat_provider.dart';
import 'package:alias/widgets/user_avatar.dart';

const _kCream = Color(0xFFF0E8D8);
const _kParchment = Color(0xFFE8DCC4);
const _kSage = Color(0xFF8DA399);
const _kDarkText = Color(0xFF2C3E35);
const _kMutedText = Color(0xFF8A9080);
const _kWhite = Color(0xFFFFFFFF);
const _kRed = Color(0xFFD9534F);

class UserSettingsSheet extends ConsumerStatefulWidget {
  final ChatModel chat;
  final UserModel partner;

  const UserSettingsSheet({
    super.key,
    required this.chat,
    required this.partner,
  });

  @override
  ConsumerState<UserSettingsSheet> createState() => _UserSettingsSheetState();
}

class _UserSettingsSheetState extends ConsumerState<UserSettingsSheet> {
  void _showChangeNicknameDialog(String currentNickname) {
    final controller = TextEditingController(text: currentNickname);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Change Nickname',
          style: TextStyle(
            color: _kDarkText,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set a custom name for ${widget.partner.username}. Only you will see this name.',
              style: const TextStyle(color: _kMutedText, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'e.g. Best Friend, Alex',
                filled: true,
                fillColor: _kParchment,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (currentNickname.isNotEmpty)
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await ref.read(firestoreServiceProvider).updateChatNickname(
                        widget.chat.chatId,
                        widget.partner.uid,
                        '',
                      );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nickname cleared')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Reset', style: TextStyle(color: _kRed)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: _kMutedText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kSage,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              final newNickname = controller.text.trim();
              Navigator.pop(ctx);
              try {
                await ref.read(firestoreServiceProvider).updateChatNickname(
                      widget.chat.chatId,
                      widget.partner.uid,
                      newNickname,
                    );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        newNickname.isEmpty
                            ? 'Nickname reset'
                            : 'Nickname set to "$newNickname"',
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating nickname: $e')),
                  );
                }
              }
            },
            child: const Text('Save', style: TextStyle(color: _kWhite)),
          ),
        ],
      ),
    );
  }

  void _copyUsername() {
    Clipboard.setData(ClipboardData(text: '@${widget.partner.username}'));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('@${widget.partner.username} copied to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _confirmClearChat() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Clear Chat History?',
          style: TextStyle(
            color: _kDarkText,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'All messages in this conversation will be permanently deleted for both participants. This cannot be undone.',
          style: TextStyle(color: _kDarkText, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: _kMutedText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(firestoreServiceProvider)
                    .clearChatHistory(widget.chat.chatId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Chat history cleared')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to clear chat: $e')),
                  );
                }
              }
            },
            child: const Text('Clear All', style: TextStyle(color: _kWhite)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(authStateProvider).value?.uid ?? '';

    return StreamBuilder<ChatModel?>(
      stream: ref.watch(firestoreServiceProvider).streamChat(widget.chat.chatId),
      initialData: widget.chat,
      builder: (context, snapshot) {
        final liveChat = snapshot.data ?? widget.chat;
        final currentNickname = liveChat.getNicknameFor(widget.partner.uid) ?? '';
        final isMuted = liveChat.isMutedFor(currentUserId);
        final displayName = liveChat.displayName(widget.partner.username, widget.partner.uid);

        return Container(
          decoration: const BoxDecoration(
            color: _kCream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: _kParchment,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Avatar
                  Center(
                    child: UserAvatar(
                      photoUrl: widget.partner.photoUrl,
                      username: widget.partner.username,
                      size: 92,
                      isOnline: widget.partner.isOnline,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Display Name (Nickname or Username)
                  Center(
                    child: Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _kDarkText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Username / Nickname note
                  Center(
                    child: GestureDetector(
                      onTap: _copyUsername,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '@${widget.partner.username}',
                              style: const TextStyle(
                                color: _kMutedText,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.copy_rounded, size: 14, color: _kMutedText),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Quick Settings Card
                  Card(
                    color: _kWhite,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        // Change Nickname
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _kSage.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.badge_outlined, color: _kSage),
                          ),
                          title: const Text(
                            'Change Nickname',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _kDarkText,
                            ),
                          ),
                          subtitle: Text(
                            currentNickname.isNotEmpty
                                ? currentNickname
                                : 'Set a custom nickname',
                            style: TextStyle(
                              color: currentNickname.isNotEmpty
                                  ? _kSage
                                  : _kMutedText,
                              fontSize: 13,
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right, color: _kMutedText),
                          onTap: () => _showChangeNicknameDialog(currentNickname),
                        ),
                        const Divider(height: 1, indent: 64),

                        // Mute / Unmute User
                        SwitchListTile(
                          secondary: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (isMuted ? _kRed : _kSage).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isMuted
                                  ? Icons.notifications_off_outlined
                                  : Icons.notifications_active_outlined,
                              color: isMuted ? _kRed : _kSage,
                            ),
                          ),
                          title: Text(
                            isMuted ? 'Muted' : 'Mute Notifications',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _kDarkText,
                            ),
                          ),
                          subtitle: Text(
                            isMuted
                                ? 'You will not receive notifications from this user'
                                : 'Receive sound and alert notifications',
                            style: const TextStyle(color: _kMutedText, fontSize: 13),
                          ),
                          value: isMuted,
                          activeThumbColor: _kSage,
                          activeTrackColor: _kSage.withValues(alpha: 0.5),
                          onChanged: (val) async {
                            try {
                              await ref
                                  .read(firestoreServiceProvider)
                                  .toggleMuteChat(
                                    liveChat.chatId,
                                    currentUserId,
                                    val,
                                  );
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Additional Actions Card
                  Card(
                    color: _kWhite,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        // Copy Username Action
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _kSage.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.copy_rounded, color: _kSage),
                          ),
                          title: const Text(
                            'Copy Username',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _kDarkText,
                            ),
                          ),
                          subtitle: Text(
                            '@${widget.partner.username}',
                            style: const TextStyle(color: _kMutedText, fontSize: 13),
                          ),
                          onTap: _copyUsername,
                        ),
                        const Divider(height: 1, indent: 64),

                        // Clear Chat History
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _kRed.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.delete_sweep_outlined, color: _kRed),
                          ),
                          title: const Text(
                            'Clear Chat History',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _kRed,
                            ),
                          ),
                          subtitle: const Text(
                            'Delete all messages permanently',
                            style: TextStyle(color: _kMutedText, fontSize: 13),
                          ),
                          onTap: _confirmClearChat,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
