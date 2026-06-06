import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/user_session_provider.dart';
import '../../../shared/models/models.dart';

class ClientStats {
  final int totalBookings;
  final double totalSpent;
  ClientStats(this.totalBookings, this.totalSpent);
}

final clientStatsProvider = FutureProvider.autoDispose<ClientStats>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return ClientStats(0, 0);

  final snapshot = await FirebaseFirestore.instance
      .collection('bookings')
      .where('clientId', isEqualTo: user.uid)
      .where('status', isEqualTo: 'completed')
      .get();
      
  int count = snapshot.docs.length;
  double spent = 0;
  for (var doc in snapshot.docs) {
    spent += (doc.data()['netPrice'] as num?)?.toDouble() ?? 0.0;
  }
  return ClientStats(count, spent);
});

class NotificationsEnabledNotifier extends Notifier<bool> {
  @override
  bool build() => true;
  void toggle(bool value) => state = value;
}
final notificationsEnabledProvider = NotifierProvider<NotificationsEnabledNotifier, bool>(NotificationsEnabledNotifier.new);

class IsDarkModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void toggle(bool value) => state = value;
}
final isDarkModeProvider = NotifierProvider<IsDarkModeNotifier, bool>(IsDarkModeNotifier.new);

final providerReviewsProvider = StreamProvider.autoDispose.family<List<ReviewModel>, String>((ref, providerId) {
  return FirebaseFirestore.instance
      .collection('reviews')
      .where('providerId', isEqualTo: providerId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => ReviewModel.fromFirestore(doc)).toList());
});
