import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:alias/models/chat_model.dart';
import 'package:alias/models/user_model.dart';
import 'package:alias/models/call_model.dart';
import 'package:alias/models/message_model.dart';
import 'package:alias/providers/chat_provider.dart';
import 'package:alias/providers/call_provider.dart';
import 'package:alias/providers/auth_provider.dart';
import 'package:alias/core/utils/date_formatter.dart';
import 'package:alias/widgets/user_avatar.dart';
import 'package:alias/services/notification_service.dart';

// ─── Palette (matches AppTheme warm-cream tokens) ──────────────────────────
const _kCream = Color(0xFFF0E8D8);
const _kParchment = Color(0xFFE8DCC4);
const _kDivider = Color(0xFFE0D8C8);
const _kSage = Color(0xFF8DA399);
const _kDarkText = Color(0xFF2C3E35);
const _kMutedText = Color(0xFF8A9080);
const _kWhite = Color(0xFFFFFFFF);

// ─── HomeScreen ─────────────────────────────────────────────────────────────

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markAllChatsAsDelivered();
      NotificationService.instance.promptPermissionIfNeeded(context);
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
    final currentUser = ref.watch(authStateProvider).value;

    // Ensure all incoming messages are marked delivered
    ref.listen<AsyncValue<List<ChatModel>>>(userChatsProvider, (previous, next) {
      if (next.hasValue && next.value != null) {
        _markAllChatsAsDelivered();
      }
    });

    return Scaffold(
      backgroundColor: _kCream,
      appBar: _buildAppBar(currentUser?.uid ?? ''),
      body: Column(
        children: [
          if (incomingCall != null) _buildIncomingCallBanner(incomingCall),
          // Active Group Call Banners
          for (final group in chatsAsyncValue.value?.where((c) => c.isGroup) ?? <ChatModel>[])
            _ActiveGroupCallBanner(
              group: group,
              currentUserId: currentUser?.uid ?? '',
            ),
          // ── Inline Search Bar ──────────────────────────────────────────
          _buildSearchBar(),
          // ── Chat List ─────────────────────────────────────────────────
          Expanded(
            child: chatsAsyncValue.when(
              data: (chats) {
                if (chats.isEmpty) return _buildEmptyState();
                final currentUserId = currentUser?.uid ?? '';
                final dmChats =
                    chats.where((c) => !c.isGroup).toList();
                final groupChats =
                    chats.where((c) => c.isGroup).toList();
                return CustomScrollView(
                  slivers: [
                    if (dmChats.isNotEmpty) ...[
                      _sectionHeader('Friends'),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) => ChatTile(
                            chat: dmChats[i],
                            currentUserId: currentUserId,
                          ),
                          childCount: dmChats.length,
                        ),
                      ),
                    ],
                    if (groupChats.isNotEmpty) ...[
                      _sectionHeader('Groups'),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) => ChatTile(
                            chat: groupChats[i],
                            currentUserId: currentUserId,
                          ),
                          childCount: groupChats.length,
                        ),
                      ),
                    ],
                    // Bottom padding for FAB
                    const SliverToBoxAdapter(child: SizedBox(height: 80)),
                  ],
                );
              },
              loading: () => _buildLoadingState(),
              error: (error, _) => Center(
                child: Text('Error: $error',
                    style: const TextStyle(color: Colors.red)),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _kSage,
        elevation: 2,
        onPressed: _showNewChatMenu,
        child: const Icon(Icons.chat_bubble_rounded, color: _kWhite),
      ),
    );
  }

  // ─── AppBar ─────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(String currentUserId) {
    return AppBar(
      backgroundColor: _kCream,
      elevation: 0,
      titleSpacing: 20,
      title: const Text(
        'Messages',
        style: TextStyle(
          color: _kDarkText,
          fontWeight: FontWeight.w800,
          fontSize: 22,
          letterSpacing: -0.3,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: _kDarkText, size: 24),
          onPressed: () => context.push('/settings'),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ─── Search Bar ─────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: GestureDetector(
        onTap: _showSearchDialog,
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            color: _kWhite,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _kDivider),
          ),
          child: const Row(
            children: [
              SizedBox(width: 14),
              Icon(Icons.search, color: _kMutedText, size: 20),
              SizedBox(width: 10),
              Text(
                'Search',
                style: TextStyle(color: _kMutedText, fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Section Header ──────────────────────────────────────────────────────

  SliverToBoxAdapter _sectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
        child: Text(
          title,
          style: const TextStyle(
            color: _kDarkText,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  // ─── Empty / Loading States ───────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _kParchment,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.chat_bubble_outline_rounded,
                size: 40, color: _kSage),
          ),
          const SizedBox(height: 20),
          const Text(
            'No conversations yet',
            style: TextStyle(
                fontSize: 18, color: _kDarkText, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the  button to start chatting',
            style: TextStyle(color: _kMutedText, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      itemCount: 6,
      padding: const EdgeInsets.only(top: 4),
      itemBuilder: (_, __) => const _ShimmerTile(),
    );
  }

  // ─── Incoming Call Banner ────────────────────────────────────────────────

  Widget _buildIncomingCallBanner(CallModel call) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      decoration: BoxDecoration(
        color: _kDarkText,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/incoming-call/${call.callId}'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _kSage.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    call.type == CallType.video ? Icons.videocam : Icons.call,
                    color: _kWhite,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FutureBuilder<UserModel?>(
                    future: (call.callerName != null &&
                            call.callerName!.isNotEmpty &&
                            call.callerName != call.callerId)
                        ? null
                        : ref.read(firestoreServiceProvider).getUserById(call.callerId),
                    builder: (context, snapshot) {
                      final name = (call.callerName != null &&
                              call.callerName!.isNotEmpty &&
                              call.callerName != call.callerId)
                          ? call.callerName!
                          : (snapshot.data?.username ?? 'Someone');
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: _kWhite,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Incoming ${call.type == CallType.video ? "video" : "audio"} call...',
                            style: TextStyle(
                              color: _kWhite.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Reject button
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () async {
                    await ref.read(callNotifierProvider.notifier).declineCall(call);
                  },
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.call_end, color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(width: 10),
                // Accept button
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () async {
                    await ref.read(callNotifierProvider.notifier).acceptCall(call);
                    if (mounted) {
                      context.push('/active-call/${call.callId}');
                    }
                  },
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.call, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Search / New Chat ───────────────────────────────────────────────────

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _kWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Search User',
            style: TextStyle(color: _kDarkText, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter username',
            prefixIcon: const Icon(Icons.search, color: _kMutedText),
            filled: true,
            fillColor: _kParchment,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
          onSubmitted: (value) {
            Navigator.pop(context);
            _performSearch(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: _kMutedText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kSage,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _performSearch(_searchController.text);
            },
            child: const Text('Search',
                style: TextStyle(color: _kWhite)),
          ),
        ],
      ),
    );
  }

  void _performSearch(String username) async {
    if (username.trim().isEmpty) return;
    try {
      final user = await ref
          .read(firestoreServiceProvider)
          .getUserByUsername(username.trim());
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
      final chatId = await ref
          .read(firestoreServiceProvider)
          .createOrGetChatId(currentUser.uid, targetUser.uid);
      if (mounted) context.push('/chat/$chatId');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start chat: $e')),
        );
      }
    }
  }

  // ─── FAB Menu ───────────────────────────────────────────────────────────

  void _showNewChatMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _kWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: _kDivider,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _kParchment,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person_add_outlined, color: _kSage),
              ),
              title: const Text('New Message',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: _kDarkText)),
              subtitle: const Text('Start a 1-on-1 conversation',
                  style: TextStyle(color: _kMutedText, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _showNewDMSheet();
              },
            ),
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _kParchment,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.group_add_outlined, color: _kSage),
              ),
              title: const Text('New Group',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: _kDarkText)),
              subtitle: const Text('Create a group chat',
                  style: TextStyle(color: _kMutedText, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _showCreateGroupSheet();
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ─── New DM Bottom Sheet ─────────────────────────────────────────────────

  void _showNewDMSheet() {
    final searchCtrl = TextEditingController();
    UserModel? foundUser;
    bool isSearching = false;
    String? searchError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          Future<void> executeSearch(String rawQuery) async {
            final query = rawQuery.trim();
            if (query.isEmpty) {
              setModalState(() {
                foundUser = null;
                searchError = null;
                isSearching = false;
              });
              return;
            }

            setModalState(() {
              isSearching = true;
              searchError = null;
              foundUser = null;
            });

            try {
              final user = await ref
                  .read(firestoreServiceProvider)
                  .getUserByUsername(query);

              setModalState(() {
                isSearching = false;
                if (user != null) {
                  foundUser = user;
                  searchError = null;
                } else {
                  foundUser = null;
                  searchError = 'User "@$query" not found';
                }
              });
            } catch (e) {
              setModalState(() {
                isSearching = false;
                foundUser = null;
                searchError = 'Search error: $e';
              });
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'New Message',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _kDarkText),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: _kMutedText),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: searchCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search by username...',
                    prefixIcon:
                        const Icon(Icons.alternate_email, color: _kMutedText),
                    suffixIcon: isSearching
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _kSage,
                              ),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.arrow_forward, color: _kSage),
                            onPressed: () => executeSearch(searchCtrl.text),
                          ),
                    filled: true,
                    fillColor: _kParchment,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (val) => executeSearch(val),
                ),
                const SizedBox(height: 14),
                if (foundUser != null)
                  Container(
                    decoration: BoxDecoration(
                      color: _kParchment.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      leading: UserAvatar(
                        photoUrl: foundUser!.photoUrl,
                        username: foundUser!.username,
                        size: 44,
                      ),
                      title: Text(
                        foundUser!.username,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: _kDarkText),
                      ),
                      subtitle: foundUser!.email.isNotEmpty
                          ? Text(
                              foundUser!.email,
                              style: const TextStyle(
                                  color: _kMutedText, fontSize: 12),
                            )
                          : null,
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: _kSage,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                        onPressed: () {
                          Navigator.pop(context);
                          _startChat(foundUser!);
                        },
                        child: const Text('Chat',
                            style: TextStyle(color: _kWhite)),
                      ),
                    ),
                  )
                else if (searchError != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Center(
                      child: Text(
                        searchError!,
                        style: const TextStyle(
                            color: Colors.redAccent, fontSize: 13),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── Create Group Bottom Sheet ───────────────────────────────────────────

  void _showCreateGroupSheet() {
    final nameCtrl = TextEditingController();
    final memberSearchCtrl = TextEditingController();
    final List<UserModel> selectedMembers = [];
    var searchResults = <UserModel>[];
    bool isSearching = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          Future<void> searchUsers(String query) async {
            if (query.trim().isEmpty) {
              setModalState(() => searchResults = []);
              return;
            }
            setModalState(() => isSearching = true);
            try {
              final currentUserId = ref.read(authStateProvider).value?.uid;
              final results = await ref
                  .read(firestoreServiceProvider)
                  .searchUsersByPrefix(query,
                      excludeUid: currentUserId);
              setModalState(() {
                searchResults = results
                    .where((u) =>
                        !selectedMembers.any((m) => m.uid == u.uid))
                    .toList();
              });
            } catch (e) {
              debugPrint('Search error: $e');
            } finally {
              setModalState(() => isSearching = false);
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    const Text(
                      'New Group',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _kDarkText),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: _kMutedText),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Group name field
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    hintText: 'Group name',
                    prefixIcon:
                        const Icon(Icons.group_outlined, color: _kMutedText),
                    filled: true,
                    fillColor: _kParchment,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Member search field
                TextField(
                  controller: memberSearchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Add members by username...',
                    prefixIcon:
                        const Icon(Icons.person_search, color: _kMutedText),
                    filled: true,
                    fillColor: _kParchment,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) => searchUsers(val),
                ),

                // Search results
                if (isSearching)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                        child: CircularProgressIndicator(color: _kSage)),
                  )
                else if (searchResults.isNotEmpty)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 160),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: searchResults.length,
                      itemBuilder: (_, i) {
                        final u = searchResults[i];
                        return ListTile(
                          dense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 4),
                          leading: UserAvatar(
                              photoUrl: u.photoUrl,
                              username: u.username,
                              size: 36),
                          title: Text(u.username,
                              style: const TextStyle(
                                  color: _kDarkText,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14)),
                          trailing: IconButton(
                            icon: const Icon(Icons.add_circle,
                                color: _kSage),
                            onPressed: () {
                              setModalState(() {
                                selectedMembers.add(u);
                                searchResults.remove(u);
                                memberSearchCtrl.clear();
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),

                // Selected members chips
                if (selectedMembers.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: selectedMembers.map((m) {
                      return Chip(
                        backgroundColor: _kParchment,
                        avatar: UserAvatar(
                            photoUrl: m.photoUrl,
                            username: m.username,
                            size: 24),
                        label: Text(m.username,
                            style: const TextStyle(
                                color: _kDarkText, fontSize: 12)),
                        deleteIconColor: _kMutedText,
                        onDeleted: () {
                          setModalState(
                              () => selectedMembers.remove(m));
                        },
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 16),

                // Create button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kSage,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.check_rounded, color: _kWhite),
                    label: const Text('Create Group',
                        style: TextStyle(
                            color: _kWhite,
                            fontWeight: FontWeight.w600,
                            fontSize: 16)),
                    onPressed: selectedMembers.isEmpty ||
                            nameCtrl.text.trim().isEmpty
                        ? null
                        : () async {
                            final currentUser =
                                ref.read(authStateProvider).value;
                            if (currentUser == null) return;

                            try {
                              final chatId = await ref
                                  .read(firestoreServiceProvider)
                                  .createGroupChat(
                                    adminId: currentUser.uid,
                                    groupName: nameCtrl.text.trim(),
                                    memberIds: selectedMembers
                                        .map((m) => m.uid)
                                        .toList(),
                                  );
                              if (context.mounted) {
                                Navigator.pop(context);
                                context.push('/chat/$chatId');
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Failed to create group: $e')),
                                );
                              }
                            }
                          },
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── ChatTile ───────────────────────────────────────────────────────────────

class ChatTile extends ConsumerWidget {
  final ChatModel chat;
  final String currentUserId;

  const ChatTile({
    super.key,
    required this.chat,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // For groups, there's no single "partner" — we show group info directly.
    if (chat.isGroup) {
      return _buildGroupTile(context, ref);
    }
    return _buildDMTile(context, ref);
  }

  // ── DM Tile ────────────────────────────────────────────────────────────

  Widget _buildDMTile(BuildContext context, WidgetRef ref) {
    final partnerId = chat.getOtherParticipantId(currentUserId);
    final livePartner = ref.watch(userProfileProvider(partnerId)).value;
    final cachedPartner = ref.watch(userProfileFutureProvider(partnerId)).value;
    final partner = livePartner ?? cachedPartner;
    final rawUsername = partner != null && partner.username.isNotEmpty
        ? partner.username
        : (partnerId.isNotEmpty ? partnerId : 'Chat');
    final displayName = chat.displayName(rawUsername, partnerId);
    final isMuted = chat.isMutedFor(currentUserId);

    final messagesAsync = ref.watch(chatMessagesProvider(chat.chatId));
    final unreadCount = messagesAsync.value
            ?.where((m) => m.senderId != currentUserId && !m.isRead)
            .length ??
        chat.unreadCount;

    ref.listen(chatMessagesProvider(chat.chatId), (previous, next) {
      if (next.hasValue && next.value != null && next.value!.isNotEmpty) {
        final hasUndelivered = next.value!
            .any((m) => m.senderId != currentUserId && !m.isDelivered);
        if (hasUndelivered) {
          ref
              .read(firestoreServiceProvider)
              .markMessagesAsDelivered(chat.chatId, currentUserId);
        }
      }
    });

    return _TileLayout(
      onTap: () => context.go('/chat/${chat.chatId}'),
      avatar: UserAvatar(
        photoUrl: partner?.photoUrl,
        username: displayName,
        size: 50,
        showOnlineBadge: true,
        isOnline: partner?.isOnline == true,
      ),
      name: displayName,
      preview: _previewText(chat),
      lastMessageType: chat.lastMessageType,
      time: chat.lastMessageTime != null
          ? DateFormatter.formatChatListTime(chat.lastMessageTime!)
          : null,
      unreadCount: unreadCount,
      isSentByMe: chat.lastMessageSenderId == currentUserId,
      isMuted: isMuted,
    );
  }

  // ── Group Tile ─────────────────────────────────────────────────────────

  Widget _buildGroupTile(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(chatMessagesProvider(chat.chatId));
    final unreadCount = messagesAsync.value
            ?.where((m) => m.senderId != currentUserId && !m.isRead)
            .length ??
        chat.unreadCount;

    return _TileLayout(
      onTap: () => context.go('/chat/${chat.chatId}'),
      avatar: UserAvatar(
        photoUrl: chat.groupPhotoUrl,
        username: chat.groupName ?? 'G',
        size: 50,
        showOnlineBadge: false,
      ),
      name: chat.groupName ?? 'Group',
      preview: _previewText(chat),
      lastMessageType: chat.lastMessageType,
      time: chat.lastMessageTime != null
          ? DateFormatter.formatChatListTime(chat.lastMessageTime!)
          : null,
      unreadCount: unreadCount,
      isSentByMe: chat.lastMessageSenderId == currentUserId,
      isMuted: chat.isMutedFor(currentUserId),
    );
  }

  // ── Helper: preview text ───────────────────────────────────────────────

  String _previewText(ChatModel chat) {
    if (chat.lastMessage != null && chat.lastMessage!.isNotEmpty) {
      return chat.lastMessage!;
    }
    if (chat.lastMessageType != null) {
      switch (chat.lastMessageType!) {
        case MessageType.image:
          return '📷 Photo';
        case MessageType.video:
          return '🎬 Video';
        case MessageType.audio:
          return '🎤 Voice message';
        case MessageType.file:
          return '📄 File';
        case MessageType.gif:
          return 'GIF';
        case MessageType.text:
          return '';
      }
    }
    return 'No messages yet';
  }
}

// ─── Reusable tile layout ───────────────────────────────────────────────────

class _TileLayout extends StatelessWidget {
  final VoidCallback onTap;
  final Widget avatar;
  final String name;
  final String preview;
  final MessageType? lastMessageType;
  final String? time;
  final int unreadCount;
  final bool isSentByMe;
  final bool isMuted;

  const _TileLayout({
    required this.onTap,
    required this.avatar,
    required this.name,
    required this.preview,
    required this.lastMessageType,
    required this.time,
    required this.unreadCount,
    required this.isSentByMe,
    this.isMuted = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasUnread = unreadCount > 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(0),
      child: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Avatar
                avatar,
                const SizedBox(width: 12),

                // Name + Preview
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _kDarkText,
                                fontWeight: hasUnread
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          if (isMuted) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.notifications_off_outlined,
                              size: 13,
                              color: _kMutedText,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: hasUnread ? _kDarkText : _kMutedText,
                          fontWeight: hasUnread
                              ? FontWeight.w600
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Time + Badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (time != null)
                      Text(
                        time!,
                        style: TextStyle(
                          color: hasUnread ? _kSage : _kMutedText,
                          fontSize: 11,
                          fontWeight: hasUnread
                              ? FontWeight.w700
                              : FontWeight.normal,
                        ),
                      ),
                    if (hasUnread) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: _kSage,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : '$unreadCount',
                          style: const TextStyle(
                            color: _kWhite,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Indented divider — aligns with text, not avatar
          const Padding(
            padding: EdgeInsets.only(left: 78),
            child: Divider(height: 1, color: _kDivider),
          ),
        ],
      ),
    );
  }
}

// ─── Shimmer Loading Tile ────────────────────────────────────────────────────

class _ShimmerTile extends StatelessWidget {
  const _ShimmerTile();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _shimmerBox(50, 50, radius: 25),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmerBox(14, 120, radius: 7),
                const SizedBox(height: 8),
                _shimmerBox(12, 180, radius: 6),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _shimmerBox(10, 36, radius: 5),
        ],
      ),
    );
  }

  Widget _shimmerBox(double h, double w, {double radius = 4}) {
    return Container(
      height: h,
      width: w,
      decoration: BoxDecoration(
        color: _kParchment,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ─── Active Group Call Banner ────────────────────────────────────────────────

class _ActiveGroupCallBanner extends ConsumerWidget {
  final ChatModel group;
  final String currentUserId;

  const _ActiveGroupCallBanner({
    required this.group,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final callAsync = ref.watch(groupCallProvider(group.chatId));
    final callData = callAsync.value;
    if (callData == null || callData['status'] != 'active') {
      return const SizedBox.shrink();
    }

    final participants = List<String>.from(callData['participants'] ?? []);
    final isInCall = participants.contains(currentUserId);
    final groupName = group.groupName ?? 'Group';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _kDarkText,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.group, color: Colors.greenAccent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$groupName Call',
                  style: const TextStyle(
                    color: _kWhite,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  isInCall
                      ? 'You are in this call (${participants.length} connected)'
                      : '${participants.length} member(s) talking',
                  style: TextStyle(
                    color: _kWhite.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isInCall ? _kSage : const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              NotificationService.instance.cancelCallNotification();
              context.push(
                '/group-call/${group.chatId}?name=${Uri.encodeComponent(groupName)}',
              );
            },
            child: Text(isInCall ? 'Return' : 'Join Call',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
