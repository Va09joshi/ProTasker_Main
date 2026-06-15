import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/models.dart';
import '../repositories/auth_repository.dart';
import '../../../features/notifications/services/notification_service.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});
class IsSigningUpNotifier extends Notifier<bool> {
  @override
  bool build() => false;
}

final isSigningUpProvider = NotifierProvider<IsSigningUpNotifier, bool>(IsSigningUpNotifier.new);

class AuthNotifier extends AsyncNotifier<void> {
  late AuthRepository _repository;

  @override
  FutureOr<void> build() {
    _repository = ref.watch(authRepositoryProvider);
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = await _repository.signInWithEmail(email, password);
      await FcmNotificationService.initialize();
      await FcmNotificationService.syncToken();
    });
  }

  Future<void> signup({
    required String name,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
  }) async {
    ref.read(isSigningUpProvider.notifier).state = true;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = await _repository.signUpWithEmail(name, email, phone, password, role);
      await FcmNotificationService.initialize();
      await FcmNotificationService.syncToken();
    });
    ref.read(isSigningUpProvider.notifier).state = false;
  }

  Future<void> loginWithGoogle() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = await _repository.signInWithGoogle();
      // user could be null if they need to select a role. If so, they'll be redirected to roleSelect.
      if (user != null) {
        await FcmNotificationService.initialize();
        await FcmNotificationService.syncToken();
      }
    });
  }

  Future<void> completeGoogleSignup(UserRole role) async {
    ref.read(isSigningUpProvider.notifier).state = true;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.completeGoogleSignup(role: role);
      await FcmNotificationService.initialize();
      await FcmNotificationService.syncToken();
    });
    ref.read(isSigningUpProvider.notifier).state = false;
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await FcmNotificationService.removeTokenFromFirestore();
      await _repository.signOut();
    });
  }

  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.updateProfile(uid, data);
    });
  }

  Future<void> resetPassword(String email) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.sendPasswordResetEmail(email);
    });
  }

  Future<void> sendEmailVerification() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.sendEmailVerification();
    });
  }
}

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, void>(() {
  return AuthNotifier();
});
