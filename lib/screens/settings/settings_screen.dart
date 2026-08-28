import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:alias/models/user_model.dart';
import 'package:alias/providers/settings_provider.dart';
import 'package:alias/providers/auth_provider.dart';
import 'package:alias/providers/chat_provider.dart';
import 'package:alias/widgets/user_avatar.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _messagePreviewEnabled = true;
  bool _autoAcceptCalls = false;
  String _lastBackupTime = 'Never';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      _messagePreviewEnabled = prefs.getBool('messagePreviewEnabled') ?? true;
      _autoAcceptCalls = prefs.getBool('autoAcceptCalls') ?? false;
      _lastBackupTime = prefs.getString('lastBackupTime') ?? 'Never';
    });
  }

  Future<void> _updateSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    if (key == 'notificationsEnabled') setState(() => _notificationsEnabled = value);
    if (key == 'messagePreviewEnabled') setState(() => _messagePreviewEnabled = value);
    if (key == 'autoAcceptCalls') setState(() => _autoAcceptCalls = value);
  }

  Future<void> _backupToDrive() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      messenger.showSnackBar(
        const SnackBar(content: Text('Starting backup...')),
      );
      await ref.read(settingsNotifierProvider.notifier).backupToGoogle();
      
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().toString();
      await prefs.setString('lastBackupTime', now);
      if (mounted) {
        setState(() => _lastBackupTime = now);
        messenger.showSnackBar(
          const SnackBar(content: Text('Backup successful')),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Backup failed: $e')),
      );
    }
  }

  Future<void> _restoreFromDrive() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Backup'),
        content: const Text('This will replace your current local data. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      messenger.showSnackBar(
        const SnackBar(content: Text('Restoring backup...')),
      );
      await ref.read(settingsNotifierProvider.notifier).restoreFromGoogle();
      messenger.showSnackBar(
        const SnackBar(content: Text('Restore successful')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Restore failed: $e')),
      );
    }
  }

  void _signOut() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final router = GoRouter.of(context);
              Navigator.of(context).pop();
              try {
                await ref.read(authNotifierProvider.notifier).logout();
                router.go('/login');
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Sign out failed: $e')),
                );
              }
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditProfileDialog(UserModel user) async {
    final usernameController = TextEditingController(text: user.username);
    String currentPhoto = user.photoUrl ?? '';
    bool isUploadingPhoto = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> pickPhoto(ImageSource source) async {
            try {
              final picker = ImagePicker();
              final picked = await picker.pickImage(
                source: source,
                maxWidth: 512,
                maxHeight: 512,
                imageQuality: 75,
              );
              if (picked != null) {
                setDialogState(() => isUploadingPhoto = true);
                final bytes = await picked.readAsBytes();
                final url = await ref
                    .read(storageServiceProvider)
                    .uploadProfilePhotoBytes(bytes, 'profile_${user.uid}.jpg');
                setDialogState(() {
                  currentPhoto = url;
                  isUploadingPhoto = false;
                });
              }
            } catch (e) {
              setDialogState(() => isUploadingPhoto = false);
            }
          }

          return AlertDialog(
            title: const Text('Edit Profile'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      UserAvatar(
                        photoUrl: currentPhoto,
                        username: usernameController.text.isNotEmpty ? usernameController.text : user.username,
                        size: 80,
                      ),
                      if (isUploadingPhoto)
                        const CircularProgressIndicator(color: Color(0xFF8DA399)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.photo_library, size: 18),
                        label: const Text('Gallery'),
                        onPressed: () => pickPhoto(ImageSource.gallery),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.camera_alt, size: 18),
                        label: const Text('Camera'),
                        onPressed: () => pickPhoto(ImageSource.camera),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixText: '@',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8DA399)),
                onPressed: () async {
                  final newUsername = usernameController.text.trim();
                  if (newUsername.isEmpty) return;

                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(context);
                  try {
                    if (newUsername.toLowerCase() != user.username.toLowerCase()) {
                      final existing = await ref.read(firestoreServiceProvider).getUserByUsername(newUsername);
                      if (existing != null && existing.uid != user.uid) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Username already taken!')),
                        );
                        return;
                      }
                    }

                    await ref.read(firestoreServiceProvider).updateUserProfile(user.uid, {
                      'username': newUsername,
                      'photoUrl': currentPhoto.isNotEmpty ? currentPhoto : null,
                    });

                    messenger.showSnackBar(
                      const SnackBar(content: Text('Profile updated successfully!')),
                    );
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Failed to update profile: $e')),
                    );
                  }
                },
                child: const Text('Save', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF8DA399);
    const backgroundColor = Color(0xFFF7F7F7);

    final currentUserId = ref.watch(authStateProvider).value?.uid ?? '';
    final userProfileAsync = ref.watch(userProfileProvider(currentUserId));
    final currentUser = userProfileAsync.value;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: const Text('Settings'),
        backgroundColor: backgroundColor,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: ListView(
        children: [
          // Profile Section
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    if (currentUser != null) _showEditProfileDialog(currentUser);
                  },
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      UserAvatar(
                        photoUrl: currentUser?.photoUrl,
                        username: currentUser?.username ?? '?',
                        size: 80,
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit, size: 16, color: primaryColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  currentUser != null ? '@${currentUser.username}' : 'Loading...',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                if (currentUser?.email != null)
                  Text(
                    currentUser!.email,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                TextButton(
                  onPressed: () {
                    if (currentUser != null) _showEditProfileDialog(currentUser);
                  },
                  child: const Text('Edit Profile', style: TextStyle(color: primaryColor)),
                ),
              ],
            ),
          ),
          
          const Divider(),

          // Backup Section
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.cloud_upload_outlined, color: primaryColor),
                      SizedBox(width: 8),
                      Text(
                        'Google Drive Backup',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Last Backup: $_lastBackupTime',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _backupToDrive,
                          icon: const Icon(Icons.backup, size: 18),
                          label: const Text('Backup Now'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _restoreFromDrive,
                          icon: const Icon(Icons.restore, size: 18),
                          label: const Text('Restore'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryColor,
                            side: const BorderSide(color: primaryColor),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Notifications Section
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Text(
              'NOTIFICATIONS',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
            color: Colors.white,
            child: Column(
              children: [
                SwitchListTile(
                  value: _notificationsEnabled,
                  onChanged: (val) => _updateSetting('notificationsEnabled', val),
                  title: const Text('Enable Notifications'),
                  activeTrackColor: primaryColor,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: _messagePreviewEnabled,
                  onChanged: (val) => _updateSetting('messagePreviewEnabled', val),
                  title: const Text('Message Preview'),
                  subtitle: const Text('Show message text in notifications'),
                  activeTrackColor: primaryColor,
                ),
              ],
            ),
          ),

          // Calls Section
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Text(
              'CALLS',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
            color: Colors.white,
            child: SwitchListTile(
              value: _autoAcceptCalls,
              onChanged: (val) => _updateSetting('autoAcceptCalls', val),
              title: const Text('Auto-accept Calls'),
              subtitle: const Text('Automatically accept incoming calls from contacts'),
              activeTrackColor: primaryColor,
            ),
          ),

          // About Section
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Text(
              'ABOUT',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
            color: Colors.white,
            child: const Column(
              children: [
                ListTile(
                  title: Text('Version'),
                  trailing: Text('1.0.0', style: TextStyle(color: Colors.grey)),
                ),
                Divider(height: 1),
                ListTile(
                  title: Text('Privacy Policy'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Sign Out Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextButton.icon(
              onPressed: _signOut,
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Sign Out', style: TextStyle(color: Colors.red)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
