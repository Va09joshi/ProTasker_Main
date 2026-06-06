import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return null;

  final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
  if (doc.exists) {
    return UserModel.fromFirestore(doc);
  }
  return null;
});

final publicProviderProfileProvider = FutureProvider.family<UserModel?, String>((ref, uid) async {
  final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
  if (doc.exists) {
    return UserModel.fromFirestore(doc);
  }
  return null;
});

final isClientProvider = Provider<bool>((ref) {
  final userModel = ref.watch(currentUserProvider).value;
  return userModel?.role == UserRole.client;
});

final isProviderProvider = Provider<bool>((ref) {
  final userModel = ref.watch(currentUserProvider).value;
  return userModel?.role == UserRole.provider;
});

final isVerifiedProviderProvider = Provider<bool>((ref) {
  final userModel = ref.watch(currentUserProvider).value;
  if (userModel == null) return false;
  return userModel.role == UserRole.provider && userModel.isVerified;
});
