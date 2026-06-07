import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/user_session_provider.dart';
import '../../../shared/models/models.dart';

final providerRequestsStreamProvider = StreamProvider.autoDispose<List<BookingModel>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('bookings')
      .where('providerId', isEqualTo: user.uid)
      .where('status', whereIn: [BookingStatus.pending.name, BookingStatus.proposal.name])
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => BookingModel.fromFirestore(doc)).toList());
});

final providerUpcomingStreamProvider = StreamProvider.autoDispose<List<BookingModel>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('bookings')
      .where('providerId', isEqualTo: user.uid)
      .where('status', isEqualTo: BookingStatus.accepted.name)
      .orderBy('scheduledAt', descending: false)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => BookingModel.fromFirestore(doc)).toList());
});

final providerActiveStreamProvider = StreamProvider.autoDispose<List<BookingModel>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('bookings')
      .where('providerId', isEqualTo: user.uid)
      .where('status', whereIn: [BookingStatus.onTheWay.name, BookingStatus.inProgress.name])
      .orderBy('updatedAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => BookingModel.fromFirestore(doc)).toList());
});

class ProviderHistoryNotifier extends AsyncNotifier<List<BookingModel>> {
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;

  @override
  Future<List<BookingModel>> build() async {
    _lastDoc = null;
    _hasMore = true;
    return _fetchPage();
  }

  Future<List<BookingModel>> _fetchPage() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return [];

    var query = FirebaseFirestore.instance
        .collection('bookings')
        .where('providerId', isEqualTo: user.uid)
        .where('status', whereIn: [BookingStatus.completed.name, BookingStatus.cancelled.name, BookingStatus.rejected.name])
        .orderBy('updatedAt', descending: true)
        .limit(10);

    if (_lastDoc != null) {
      query = query.startAfterDocument(_lastDoc!);
    }

    final snapshot = await query.get();
    
    if (snapshot.docs.length < 10) _hasMore = false;
    if (snapshot.docs.isNotEmpty) _lastDoc = snapshot.docs.last;

    return snapshot.docs.map((doc) => BookingModel.fromFirestore(doc)).toList();
  }

  Future<void> loadMore() async {
    if (state.isLoading || !_hasMore) return;
    final currentList = state.value ?? [];
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final newItems = await _fetchPage();
      return [...currentList, ...newItems];
    });
  }
}

final providerHistoryProvider = AsyncNotifierProvider.autoDispose<ProviderHistoryNotifier, List<BookingModel>>(() {
  return ProviderHistoryNotifier();
});
