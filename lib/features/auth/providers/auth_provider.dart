import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/models.dart';
import '../repositories/auth_repository.dart';
import '../../../features/notifications/services/notification_service.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

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
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = await _repository.signUpWithEmail(name, email, phone, password, role);
      await FcmNotificationService.initialize();
      await FcmNotificationService.syncToken();
    });
  }

  Future<void> loginWithGoogle() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = await _repository.signInWithGoogle();
      await FcmNotificationService.initialize();
      await FcmNotificationService.syncToken();
    });
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
}

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, void>(() {
  return AuthNotifier();
});
