import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Conditional import for web
import 'presence_service_stub.dart'
    if (dart.library.html) 'presence_service_web.dart' as platform;

/// Manages user online/offline presence in Firestore.
/// 
/// Sets isOnline=true when user is authenticated and connected.
/// Keeps user online while tab is open; sets offline only on actual internet drop, tab close, or sign out.
class PresenceService with WidgetsBindingObserver {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  StreamSubscription<User?>? _authSub;
  Timer? _heartbeatTimer;
  bool _isInitialized = false;

  PresenceService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Initialize the presence service - call once at app startup
  void initialize() {
    if (_isInitialized) return;
    _isInitialized = true;

    if (!kIsWeb) {
      WidgetsBinding.instance.addObserver(this);
    }

    // Register web online/offline and tab close events
    platform.registerWebPresence(
      onOnline: () => _setOnline(),
      onOffline: () => _setOfflineSync(),
    );

    // Listen to auth changes - go online when signed in, offline when signed out
    _authSub = _auth.authStateChanges().listen((user) {
      if (user != null) {
        _setOnline();
        _startHeartbeat();
      } else {
        _stopHeartbeat();
        _setOffline();
      }
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    // Heartbeat every 45s to maintain active presence and check connection
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      if (platform.isBrowserOnline()) {
        _setOnline();
      } else {
        _setOffline();
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// Clean up
  void dispose() {
    if (!kIsWeb) {
      WidgetsBinding.instance.removeObserver(this);
    }
    _stopHeartbeat();
    _authSub?.cancel();
    _setOffline();
    _isInitialized = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (kIsWeb) return; // On Web, blur/window switch must not turn user offline

    switch (state) {
      case AppLifecycleState.resumed:
        _setOnline();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _setOffline();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // Do not set offline for temporary inactivity / shade pull
        break;
    }
  }

  Future<void> _setOnline() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _firestore.collection('users').doc(user.uid).update({
        'isOnline': true,
        'lastSeen': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('PresenceService: Error setting online: $e');
    }
  }

  Future<void> _setOffline() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _firestore.collection('users').doc(user.uid).update({
        'isOnline': false,
        'lastSeen': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('PresenceService: Error setting offline: $e');
    }
  }

  /// Synchronous version for web beforeunload (sends the request, doesn't await)
  void _setOfflineSync() {
    final user = _auth.currentUser;
    if (user == null) return;
    _firestore.collection('users').doc(user.uid).update({
      'isOnline': false,
      'lastSeen': Timestamp.fromDate(DateTime.now()),
    });
  }
}
