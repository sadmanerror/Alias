import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/chat/chat_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/chat/gif_picker_screen.dart';
import '../../screens/call/incoming_call_screen.dart';
import '../../screens/call/active_call_screen.dart';

class RoutePaths {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const chat = '/chat/:chatId';
  static const settings = '/settings';
  static const gifPicker = '/gif-picker/:chatId';
  static const incomingCall = '/incoming-call/:callId';
  static const activeCall = '/active-call/:callId';
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final authStateAsync = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: RoutePaths.splash,
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RoutePaths.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: RoutePaths.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: RoutePaths.chat,
        builder: (context, state) {
          final chatId = state.pathParameters['chatId']!;
          return ChatScreen(chatId: chatId);
        },
      ),
      GoRoute(
        path: RoutePaths.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: RoutePaths.gifPicker,
        builder: (context, state) {
          final chatId = state.pathParameters['chatId']!;
          return GifPickerScreen(chatId: chatId);
        },
      ),
      GoRoute(
        path: RoutePaths.incomingCall,
        builder: (context, state) {
          final callId = state.pathParameters['callId']!;
          return IncomingCallScreen(callId: callId);
        },
      ),
      GoRoute(
        path: RoutePaths.activeCall,
        builder: (context, state) {
          final callId = state.pathParameters['callId']!;
          return ActiveCallScreen(callId: callId);
        },
      ),
    ],
    redirect: (context, state) {
      final isLoading = authStateAsync.isLoading;
      final isAuthenticated = authStateAsync.hasValue && authStateAsync.value != null;

      final isSplash = state.uri.toString() == RoutePaths.splash;
      final isLogin = state.uri.toString() == RoutePaths.login;
      final isRegister = state.uri.toString() == RoutePaths.register;

      if (isLoading) {
        return isSplash ? null : RoutePaths.splash;
      }

      if (!isAuthenticated) {
        return (isLogin || isRegister) ? null : RoutePaths.login;
      }

      if (isAuthenticated && (isLogin || isRegister || isSplash)) {
        return RoutePaths.home;
      }

      return null;
    },
  );
});

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0E8D8), // warm cream
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo mark
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Image.asset(
                'assets/images/logo.png',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Alias',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 40,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Private. Simple. Yours.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              valueColor:
                  AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              strokeWidth: 2.5,
            ),
          ],
        ),
      ),
    );
  }
}
