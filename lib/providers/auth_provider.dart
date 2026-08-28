import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:alias/services/auth_service.dart';
import 'package:alias/models/user_model.dart';

part 'auth_provider.g.dart';

@riverpod
AuthService authService(Ref ref) {
  return AuthService(
    FirebaseAuth.instance,
    FirebaseFirestore.instance,
  );
}

@riverpod
Stream<User?> authState(Ref ref) {
  return ref.watch(authServiceProvider).authStateChanges;
}

@riverpod
Future<UserModel?> currentUserModel(Ref ref) async {
  final user = await ref.watch(authStateProvider.future);
  if (user != null) {
    return ref.watch(authServiceProvider).getUserModel(user.uid);
  }
  return null;
}

@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  FutureOr<UserModel?> build() async {
    return ref.watch(currentUserModelProvider.future);
  }

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

final authNotifierProvider = authProvider;
