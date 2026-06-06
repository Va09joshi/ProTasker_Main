import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/user_session_provider.dart';
import '../../../shared/models/models.dart';

// Badge provider for new job requests (Jobs tab)
final providerPendingRequestsBadgeProvider = StreamProvider<int>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value(0);

  return FirebaseFirestore.instance
      .collection('bookings')
      .where('providerId', isEqualTo: user.uid)
      .where('status', isEqualTo: BookingStatus.pending.name)
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
});

// Pending Requests (Stream)
final providerPendingRequestsProvider = StreamProvider.autoDispose<List<BookingModel>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('bookings')
      .where('providerId', isEqualTo: user.uid)
      .where('status', isEqualTo: BookingStatus.pending.name)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => BookingModel.fromFirestore(doc)).toList());
});

// Active Job (Stream) - only one active job at a time usually
final providerActiveJobProvider = StreamProvider.autoDispose<BookingModel?>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('bookings')
      .where('providerId', isEqualTo: user.uid)
      .where('status', whereIn: [BookingStatus.onTheWay.name, BookingStatus.inProgress.name])
      .limit(1)
      .snapshots()
      .map((snapshot) {
        if (snapshot.docs.isEmpty) return null;
        return BookingModel.fromFirestore(snapshot.docs.first);
      });
});

// Upcoming Jobs (Future/Stream)
final providerUpcomingJobsProvider = StreamProvider.autoDispose<List<BookingModel>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('bookings')
      .where('providerId', isEqualTo: user.uid)
      .where('status', isEqualTo: BookingStatus.accepted.name)
      .orderBy('scheduledAt', descending: false)
      .limit(3)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => BookingModel.fromFirestore(doc)).toList());
});

class ProviderStats {
  final double todayEarnings;
  final int weekJobs;
  final double avgRating;
  final double completionRate;

  ProviderStats({
    required this.todayEarnings,
    required this.weekJobs,
    required this.avgRating,
    required this.completionRate,
  });
}

// Stats Provider
final providerStatsProvider = FutureProvider.autoDispose<ProviderStats>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return ProviderStats(todayEarnings: 0, weekJobs: 0, avgRating: 0, completionRate: 0);

  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final startOfWeek = startOfDay.subtract(Duration(days: now.weekday - 1));

  final snapshot = await FirebaseFirestore.instance
      .collection('bookings')
      .where('providerId', isEqualTo: user.uid)
      .orderBy('createdAt', descending: true)
      .limit(100)
      .get();

  double todayEarnings = 0;
  int weekJobs = 0;
  int completedCount = 0;
  int totalCount = snapshot.docs.length;

  for (var doc in snapshot.docs) {
    final b = BookingModel.fromFirestore(doc);
    if (b.status == BookingStatus.completed) {
      completedCount++;
      if (b.updatedAt.isAfter(startOfDay)) {
        todayEarnings += b.netPrice;
      }
      if (b.updatedAt.isAfter(startOfWeek)) {
        weekJobs++;
      }
    }
  }

  double completionRate = totalCount == 0 ? 100.0 : (completedCount / totalCount) * 100;
  
  return ProviderStats(
    todayEarnings: todayEarnings,
    weekJobs: weekJobs,
    avgRating: user.rating,
    completionRate: completionRate,
  );
});
