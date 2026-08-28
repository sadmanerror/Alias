import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:alias/models/chat_model.dart';
import 'package:alias/models/user_model.dart';
import 'package:alias/models/call_model.dart';
import 'package:alias/providers/chat_provider.dart';
import 'package:alias/providers/call_provider.dart';
import 'package:alias/providers/auth_provider.dart';
import 'package:alias/core/utils/date_formatter.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const Color primarySageGreen = Color(0xFF8DA399);
  static const Color warmSand = Color(0xFFE8DCC4);
  static const Color offWhite = Color(0xFFF7F7F7);
  static const Color textSecondary = Color(0xFF6B7C74);

  final TextEditingController _searchController = TextEditingController();
  UserModel? _searchedUser;
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Mark all messages as delivered when user opens the app (WhatsApp style)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markAllChatsAsDelivered();
    });
  }

  Future<void> _markAllChatsAsDelivered() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    final firestoreService = ref.read(firestoreServiceProvider);
    try {
      final chats = await firestoreService.getUserChats(user.uid).first;
      for (final chat in chats) {
        await firestoreService.markMessagesAsDelivered(chat.chatId, user.uid);
      }
    } catch (e) {
      debugPrint('Error marking messages as delivered: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatsAsyncValue = ref.watch(userChatsProvider);
    final incomingCall = ref.watch(incomingCallProvider).value;

    // Continuously mark all chats as delivered whenever chats list updates
    ref.listen(userChatsProvider, (previous, next) {
      if (next.hasValue && next.value != null) {
        _markAllChatsAsDelivered();
      }
    });

    return Scaffold(
      backgroundColor: offWhite,
      appBar: AppBar(
        backgroundColor: offWhite,
        elevation: 0,
        title: const Text(
          'Alias',
          style: TextStyle(
            color: primarySageGreen,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: primarySageGreen),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: primarySageGreen),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          if (incomingCall != null) _buildIncomingCallBanner(incomingCall),
          Expanded(
            child: chatsAsyncValue.when(
              data: (chats) {
                if (chats.isEmpty) {
                  return _buildEmptyState();
                }
                return ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    return ChatTile(chat: chats[index]);
                  },
                );
              },
              loading: () => _buildLoadingState(),
              error: (error, stackTrace) => Center(
                child: Text('Error: $error', style: const TextStyle(color: Colors.red)),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primarySageGreen,
        onPressed: _showNewChatBottomSheet,
        child: const Icon(Icons.chat_bubble, color: Colors.white),
      ),
    );
  }

  Widget _buildIncomingCallBanner(CallModel call) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: primarySageGreen,
      child: Row(
        children: [
          const Icon(Icons.call, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${call.callerName} is calling...',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.call_end, color: Colors.red),
            onPressed: () => ref.read(callNotifierProvider.notifier).declineCall(call),
          ),
          IconButton(
            icon: const Icon(Icons.call, color: Colors.green),
            onPressed: () => ref.read(callNotifierProvider.notifier).acceptCall(call),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'No conversations yet',
            style: TextStyle(fontSize: 18, color: textSecondary, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the message button to start chatting',
            style: TextStyle(color: textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        return ListTile(
          leading: const CircleAvatar(backgroundColor: warmSand),
          title: Container(height: 16, width: 100, color: warmSand),
          subtitle: Container(height: 12, width: double.infinity, color: warmSand),
        );
      },
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search User'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Enter username',
            prefixIcon: Icon(Icons.search),
          ),
          onSubmitted: (value) {
            Navigator.pop(context);
            _performSearch(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performSearch(_searchController.text);
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _performSearch(String username) async {
    if (username.trim().isEmpty) return;

    try {
      final user = await ref.read(firestoreServiceProvider).getUserByUsername(username.trim());
      if (user != null && mounted) {
        _startChat(user);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _startChat(UserModel targetUser) async {
    final currentUser = ref.read(authStateProvider).value;
    if (currentUser == null) return;

    if (currentUser.uid == targetUser.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot chat with yourself')),
      );
      return;
    }

    try {
      final chatId = await ref.read(firestoreServiceProvider).createOrGetChatId(
            currentUser.uid,
            targetUser.uid,
          );
      if (mounted) {
        context.push('/chat/$chatId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start chat: $e')),
        );
      }
    }
  }

  Future<void> _searchUserInBottomSheet(String username) async {
    setState(() => _isSearching = true);
    try {
      final user = await ref.read(firestoreServiceProvider).getUserByUsername(username.trim());
      setState(() => _searchedUser = user);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _showNewChatBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'New Message',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Enter username...',
                prefixIcon: const Icon(Icons.alternate_email),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () {
                    final username = _searchController.text.trim();
                    if (username.isNotEmpty) {
                      _searchUserInBottomSheet(username);
                    }
                  },
                ),
              ),
              onSubmitted: _searchUserInBottomSheet,
            ),
            if (_isSearching)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator(color: primarySageGreen)),
              ),
            if (_searchedUser != null)
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: warmSand,
                  backgroundImage: _searchedUser!.photoUrl != null
                      ? NetworkImage(_searchedUser!.photoUrl!)
                      : null,
                  child: _searchedUser!.photoUrl == null
                      ? Text(_searchedUser!.username[0].toUpperCase())
                      : null,
                ),
                title: Text(_searchedUser!.username, style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8DA399)),
                  onPressed: () => _startChat(_searchedUser!),
                  child: const Text('Start Chat', style: TextStyle(color: Colors.white)),
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class ChatTile extends ConsumerWidget {
  final ChatModel chat;

  const ChatTile({super.key, required this.chat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(authStateProvider).value?.uid ?? '';
    final partnerId = chat.getOtherParticipantId(currentUserId);
    final partnerAsync = ref.watch(userProfileProvider(partnerId));
    final partner = partnerAsync.value;
    final displayName = partner != null && partner.username.isNotEmpty
        ? partner.username
        : (partnerId.isNotEmpty ? partnerId : 'Chat');

    final messagesAsync = ref.watch(chatMessagesProvider(chat.chatId));
    final unreadCount = messagesAsync.value?.where((m) => m.senderId != currentUserId && !m.isRead).length ?? chat.unreadCount;
    final bool hasUnread = unreadCount > 0;

    // Real-time listener: if new messages arrive in this chat, mark them delivered immediately
    ref.listen(chatMessagesProvider(chat.chatId), (previous, next) {
      if (next.hasValue && next.value != null && next.value!.isNotEmpty) {
        final hasUndelivered = next.value!.any((m) => m.senderId != currentUserId && !m.isDelivered);
        if (hasUndelivered) {
          ref.read(firestoreServiceProvider).markMessagesAsDelivered(chat.chatId, currentUserId);
        }
      }
    });

    return ListTile(
      onTap: () => context.go('/chat/${chat.chatId}'),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFE8DCC4),
            backgroundImage: partner?.photoUrl != null ? NetworkImage(partner!.photoUrl!) : null,
            child: partner?.photoUrl == null
                ? Text(
                    displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : '?',
                    style: const TextStyle(color: Color(0xFF2C3E35), fontWeight: FontWeight.bold, fontSize: 18),
                  )
                : null,
          ),
          // Single status indicator on chat head: Green if online, Dark if offline
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: (partner?.isOnline == true) ? const Color(0xFF4CAF50) : const Color(0xFF6B7C74),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ],
      ),
      title: Text(
        displayName,
        style: TextStyle(
          fontWeight: hasUnread ? FontWeight.w800 : FontWeight.bold,
          color: const Color(0xFF2C3E35),
          fontSize: 16,
        ),
      ),
      subtitle: Row(
        children: [
          if (hasUnread) ...[
            const Icon(Icons.mark_chat_unread, size: 14, color: Color(0xFF8DA399)),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              chat.lastMessage ?? 'No messages yet',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: hasUnread ? const Color(0xFF2C3E35) : const Color(0xFF6B7C74),
                fontWeight: hasUnread ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (chat.lastMessageTime != null)
            Text(
              DateFormatter.formatChatListTime(chat.lastMessageTime!),
              style: TextStyle(
                color: hasUnread ? const Color(0xFF8DA399) : const Color(0xFF6B7C74),
                fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          if (hasUnread)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF8DA399),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
