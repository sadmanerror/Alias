import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:alias/models/chat_model.dart';
import 'package:alias/models/user_model.dart';
import 'package:alias/providers/chat_provider.dart';
import 'package:alias/providers/auth_provider.dart';
import 'package:alias/widgets/user_avatar.dart';

const _kCream = Color(0xFFF0E8D8);
const _kParchment = Color(0xFFE8DCC4);
const _kSage = Color(0xFF8DA399);
const _kDarkText = Color(0xFF2C3E35);
const _kMutedText = Color(0xFF8A9080);
const _kWhite = Color(0xFFFFFFFF);

class GroupSettingsSheet extends ConsumerStatefulWidget {
  final ChatModel chat;

  const GroupSettingsSheet({super.key, required this.chat});

  @override
  ConsumerState<GroupSettingsSheet> createState() => _GroupSettingsSheetState();
}

class _GroupSettingsSheetState extends ConsumerState<GroupSettingsSheet> {
  bool _isUploadingPhoto = false;

  void _showChangeGroupNameDialog() {
    final nameController = TextEditingController(text: widget.chat.groupName ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Change Group Name',
          style: TextStyle(color: _kDarkText, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter new group name',
            filled: true,
            fillColor: _kParchment,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: _kMutedText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kSage,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isEmpty) return;
              Navigator.pop(ctx);
              try {
                await ref
                    .read(firestoreServiceProvider)
                    .updateGroupInfo(widget.chat.chatId, groupName: newName);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Group name updated')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating name: $e')),
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

  Future<void> _pickGroupPhoto() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (picked != null) {
        setState(() => _isUploadingPhoto = true);
        final bytes = await picked.readAsBytes();
        final url = await ref
            .read(storageServiceProvider)
            .uploadProfilePhotoBytes(bytes, 'group_${widget.chat.chatId}.jpg');

        await ref
            .read(firestoreServiceProvider)
            .updateGroupInfo(widget.chat.chatId, groupPhotoUrl: url);

        if (mounted) {
          setState(() => _isUploadingPhoto = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Group photo updated')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update photo: $e')),
        );
      }
    }
  }

  void _showAddMemberSheet() {
    final searchCtrl = TextEditingController();
    List<UserModel> searchResults = [];
    bool isSearching = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          Future<void> searchUsers(String query) async {
            final clean = query.trim();
            if (clean.isEmpty) {
              setModalState(() => searchResults = []);
              return;
            }
            setModalState(() => isSearching = true);
            try {
              final results = await ref
                  .read(firestoreServiceProvider)
                  .searchUsersByPrefix(clean);
              setModalState(() {
                searchResults = results
                    .where((u) => !widget.chat.participants.contains(u.uid))
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
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
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
                      'Add Member',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _kDarkText,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: _kMutedText),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: searchCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search username...',
                    prefixIcon: const Icon(Icons.person_search, color: _kMutedText),
                    filled: true,
                    fillColor: _kParchment,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) => searchUsers(val),
                ),
                const SizedBox(height: 12),
                if (isSearching)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator(color: _kSage)),
                  )
                else if (searchResults.isEmpty && searchCtrl.text.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: Text('No new users found', style: TextStyle(color: _kMutedText)),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: searchResults.length,
                      itemBuilder: (_, i) {
                        final u = searchResults[i];
                        return ListTile(
                          leading: UserAvatar(
                            photoUrl: u.photoUrl,
                            username: u.username,
                            size: 40,
                          ),
                          title: Text(
                            u.username,
                            style: const TextStyle(fontWeight: FontWeight.w600, color: _kDarkText),
                          ),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kSage,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                            onPressed: () async {
                              Navigator.pop(ctx);
                              try {
                                await ref
                                    .read(firestoreServiceProvider)
                                    .addMemberToGroup(widget.chat.chatId, u.uid);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Added ${u.username} to group')),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to add member: $e')),
                                  );
                                }
                              }
                            },
                            child: const Text('Add', style: TextStyle(color: _kWhite)),
                          ),
                        );
                      },
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

  void _kickMember(UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove Member', style: TextStyle(color: _kDarkText, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to remove ${user.username} from this group?',
          style: const TextStyle(color: _kDarkText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: _kMutedText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(firestoreServiceProvider)
                    .removeMemberFromGroup(widget.chat.chatId, user.uid);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Removed ${user.username}')),
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
            child: const Text('Remove', style: TextStyle(color: _kWhite)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Stream real-time chat data for accurate member counts and updates
    final chatStream = ref.watch(singleChatProvider(widget.chat.chatId));
    final liveChat = chatStream.value ?? widget.chat;
    final currentUserId = ref.watch(authStateProvider).value?.uid ?? '';
    final isAdmin = liveChat.adminId == null || liveChat.adminId == currentUserId;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: _kCream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
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

            // ── Group Photo & Edit ──────────────────────────────────────
            Center(
              child: Stack(
                children: [
                  UserAvatar(
                    photoUrl: liveChat.groupPhotoUrl,
                    username: liveChat.groupName ?? 'G',
                    size: 88,
                    showOnlineBadge: false,
                  ),
                  if (_isUploadingPhoto)
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black26,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(color: _kWhite, strokeWidth: 2),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickGroupPhoto,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: _kSage,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, color: _kWhite, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Group Name with Edit Button ─────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    liveChat.groupName ?? 'Group',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _kDarkText,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18, color: _kSage),
                  onPressed: _showChangeGroupNameDialog,
                ),
              ],
            ),
            Center(
              child: Text(
                '${liveChat.participants.length} members',
                style: const TextStyle(color: _kMutedText, fontSize: 13),
              ),
            ),
            const SizedBox(height: 24),

            // ── Actions ────────────────────────────────────────────────
            Card(
              color: _kWhite,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_add_alt_1, color: _kSage),
                    title: const Text(
                      'Add Member',
                      style: TextStyle(fontWeight: FontWeight.w600, color: _kDarkText),
                    ),
                    onTap: _showAddMemberSheet,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Members Section Header ─────────────────────────────────
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(
                'Members',
                style: TextStyle(
                  color: _kDarkText,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),

            // ── Member List ────────────────────────────────────────────
            Card(
              color: _kWhite,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: liveChat.participants.length,
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 64),
                itemBuilder: (context, index) {
                  final uid = liveChat.participants[index];
                  final isGroupAdmin = uid == liveChat.adminId;
                  final isMe = uid == currentUserId;

                  return _MemberTile(
                    uid: uid,
                    isAdmin: isGroupAdmin,
                    canKick: isAdmin && !isMe,
                    onKick: _kickMember,
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _MemberTile extends ConsumerWidget {
  final String uid;
  final bool isAdmin;
  final bool canKick;
  final Function(UserModel user) onKick;

  const _MemberTile({
    required this.uid,
    required this.isAdmin,
    required this.canKick,
    required this.onKick,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider(uid));

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const ListTile(title: Text('Unknown user'));
        }
        return ListTile(
          leading: UserAvatar(
            photoUrl: user.photoUrl,
            username: user.username,
            size: 40,
            showOnlineBadge: true,
            isOnline: user.isOnline,
          ),
          title: Text(
            user.username,
            style: const TextStyle(fontWeight: FontWeight.w600, color: _kDarkText),
          ),
          subtitle: isAdmin
              ? const Text(
                  'Admin',
                  style: TextStyle(color: _kSage, fontWeight: FontWeight.bold, fontSize: 12),
                )
              : null,
          trailing: canKick
              ? IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                  onPressed: () => onKick(user),
                )
              : null,
        );
      },
      loading: () => const ListTile(
        leading: CircleAvatar(radius: 20, backgroundColor: _kParchment),
        title: Text('Loading...'),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

