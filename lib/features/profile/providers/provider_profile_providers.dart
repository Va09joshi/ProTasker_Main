import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/user_session_provider.dart';
import '../../../shared/models/models.dart';

class ProviderProfileStats {
  final double completionRate;
  final String avgResponseTime;
  
  ProviderProfileStats(this.completionRate, this.avgResponseTime);
}

final providerProfileStatsProvider = FutureProvider.autoDispose<ProviderProfileStats>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return ProviderProfileStats(100, 'N/A');

  final snapshot = await FirebaseFirestore.instance
      .collection('bookings')
      .where('providerId', isEqualTo: user.uid)
      .limit(100)
      .get();
      
  int total = snapshot.docs.length;
  if (total == 0) return ProviderProfileStats(100, 'N/A');
  
  int completed = 0;
  
  for (var doc in snapshot.docs) {
    final b = BookingModel.fromFirestore(doc);
    if (b.status == BookingStatus.completed) completed++;
  }
  
  double rate = (completed / total) * 100;
  return ProviderProfileStats(rate, '15 mins'); // Mocked avg response time
});
