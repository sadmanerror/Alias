import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:alias/services/auth_service.dart';
import 'package:alias/models/user_model.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    FirebaseAuth.instance,
    FirebaseFirestore.instance,
  );
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final currentUserModelProvider = FutureProvider<UserModel?>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user != null) {
    return ref.watch(authServiceProvider).getUserModel(user.uid);
  }
  return null;
});

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final Ref ref;
  AuthNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<void> register(String email, String password, String username) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(authServiceProvider).registerWithEmailAndPassword(
            email,
            password,
            username,
          );
      return ref.read(currentUserModelProvider.future);
    });
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(authServiceProvider).signInWithEmailAndPassword(
            email,
            password,
          );
      return ref.read(currentUserModelProvider.future);
    });
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(authServiceProvider).signOut();
      return null;
    });
  }

  String? get errorMessage => state.error?.toString();
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  return AuthNotifier(ref);
});
