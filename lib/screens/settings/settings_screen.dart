import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alias/models/user_model.dart';
import 'package:alias/providers/settings_provider.dart';
import 'package:alias/providers/auth_provider.dart';
import 'package:alias/providers/chat_provider.dart';

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
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Starting backup...')),
      );
      await ref.read(settingsNotifierProvider.notifier).backupToGoogle();
      
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().toString();
      await prefs.setString('lastBackupTime', now);
      if (mounted) {
        setState(() => _lastBackupTime = now);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup successful')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e')),
        );
      }
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
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restoring backup...')),
      );
      await ref.read(settingsNotifierProvider.notifier).restoreFromGoogle();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Restore successful')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: $e')),
        );
      }
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
              Navigator.of(context).pop();
              try {
                await ref.read(authNotifierProvider.notifier).logout();
                if (mounted) {
                  context.go('/login');
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Sign out failed: $e')),
                  );
                }
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
    final photoController = TextEditingController(text: user.photoUrl ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  prefixText: '@',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: photoController,
                decoration: const InputDecoration(
                  labelText: 'Profile Photo URL',
                  hintText: 'https://...',
                  border: OutlineInputBorder(),
                ),
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
              final newPhoto = photoController.text.trim();
              if (newUsername.isEmpty) return;

              Navigator.pop(context);
              try {
                if (newUsername.toLowerCase() != user.username.toLowerCase()) {
                  final existing = await ref.read(firestoreServiceProvider).getUserByUsername(newUsername);
                  if (existing != null && existing.uid != user.uid) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Username already taken!')),
                      );
                    }
                    return;
                  }
                }

                await ref.read(firestoreServiceProvider).updateUserProfile(user.uid, {
                  'username': newUsername,
                  'photoUrl': newPhoto.isNotEmpty ? newPhoto : null,
                });

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile updated successfully!')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update profile: $e')),
                  );
                }
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
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
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: primaryColor,
                        backgroundImage: currentUser?.photoUrl != null
                            ? NetworkImage(currentUser!.photoUrl!)
                            : null,
                        child: currentUser?.photoUrl == null
                            ? Text(
                                currentUser != null && currentUser.username.isNotEmpty
                                    ? currentUser.username.substring(0, 1).toUpperCase()
                                    : '?',
                                style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                              )
                            : null,
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
            margin: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Chat Backup',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('Last backed up: $_lastBackupTime', style: const TextStyle(color: Colors.grey)),
                ),
                ListTile(
                  leading: const Icon(Icons.cloud_upload, color: primaryColor),
                  title: const Text('Backup to Google Drive'),
                  subtitle: const Text('Securely backup your chat history'),
                  trailing: ElevatedButton(
                    onPressed: _backupToDrive,
                    style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                    child: const Text('Backup Now', style: TextStyle(color: Colors.white)),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.restore, color: primaryColor),
                  title: const Text('Restore from Drive'),
                  onTap: _restoreFromDrive,
                ),
              ],
            ),
          ),

          // Notifications Section
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
            child: Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          SwitchListTile(
            title: const Text('Enable notifications'),
            value: _notificationsEnabled,
            activeThumbColor: primaryColor,
            onChanged: (val) => _updateSetting('notificationsEnabled', val),
          ),
          SwitchListTile(
            title: const Text('Message preview'),
            value: _messagePreviewEnabled,
            activeThumbColor: primaryColor,
            onChanged: (val) => _updateSetting('messagePreviewEnabled', val),
          ),

          // Calls Section
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
            child: Text('Calls', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          SwitchListTile(
            title: const Text('Auto-accept calls from contacts only'),
            value: _autoAcceptCalls,
            activeThumbColor: primaryColor,
            onChanged: (val) => _updateSetting('autoAcceptCalls', val),
          ),

          // Account Section
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
            child: Text('Account', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
            onTap: _signOut,
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
            onTap: () {
              // Delete account logic
            },
          ),
          
          const SizedBox(height: 32),
          
          // App Info
          const Center(
            child: Column(
              children: [
                Text('Alias', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text('Version 1.0.0', style: TextStyle(color: Colors.grey)),
                SizedBox(height: 8),
                Text('Secure and seamless messaging.', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
