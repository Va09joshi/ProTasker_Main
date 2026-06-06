import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/user_session_provider.dart';
import '../../../shared/models/models.dart';
import '../../jobs/repositories/job_repository.dart';
import '../../jobs/models/job_post.dart';

final clientUnreadChatsProvider = StreamProvider<int>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value(0);

  return FirebaseFirestore.instance
      .collection('chats')
      .where('clientId', isEqualTo: user.uid)
      .where('clientUnread', isGreaterThan: 0)
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
});

final clientActiveBookingsProvider = StreamProvider<int>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value(0);

  return FirebaseFirestore.instance
      .collection('bookings')
      .where('clientId', isEqualTo: user.uid)
      .where('status', whereIn: [
        BookingStatus.pending.name,
        BookingStatus.accepted.name,
        BookingStatus.onTheWay.name,
        BookingStatus.inProgress.name,
      ])
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
});

final popularServicesProvider = StreamProvider.autoDispose<List<ServiceModel>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value([]);
  
  final city = user.address.city;
  if (city.isEmpty) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('services')
      .where('city', isEqualTo: city)
      .where('isActive', isEqualTo: true)
      .orderBy('rating', descending: true)
      .limit(8)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => ServiceModel.fromFirestore(doc)).toList());
});

final bookAgainProvider = FutureProvider.autoDispose<List<BookingModel>>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return [];

  final snapshot = await FirebaseFirestore.instance
      .collection('bookings')
      .where('clientId', isEqualTo: user.uid)
      .where('status', isEqualTo: BookingStatus.completed.name)
      .orderBy('updatedAt', descending: true)
      .limit(3)
      .get();
      
  return snapshot.docs.map((doc) => BookingModel.fromFirestore(doc)).toList();
});

final myJobPostsProvider = StreamProvider.autoDispose<List<JobPost>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value([]);
  
  final repo = ref.read(jobRepositoryProvider);
  return repo.getClientJobs(user.uid);
});

final nearbyProvidersProvider = StreamProvider.autoDispose<List<UserModel>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value([]);
  
  final city = user.address.city;
  if (city.isEmpty) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('users')
      .where('role', isEqualTo: 'provider')
      // .where('address.city', isEqualTo: city)
      // .where('profileComplete', isEqualTo: true)
      .limit(10)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList());
});
