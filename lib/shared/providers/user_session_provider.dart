import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.userChanges();
});

final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((doc) {
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    
    // Automatically repair broken accounts that failed during creation
    final repairedUser = UserModel(
      uid: user.uid,
      name: user.displayName ?? 'Unknown',
      email: user.email ?? '',
      phone: user.phoneNumber ?? '',
      role: UserRole.client, // Default to client
      address: Address(street: '', city: '', state: '', pincode: '', lat: 0, lng: 0),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    // Fire and forget repair
    FirebaseFirestore.instance.collection('users').doc(user.uid).set(repairedUser.toMap());
    
    return repairedUser;
  });
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
