import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/user_session_provider.dart';
import '../../../shared/models/models.dart';

final clientActiveBookingsStreamProvider = StreamProvider.autoDispose<List<BookingModel>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('bookings')
      .where('clientId', isEqualTo: user.uid)
      .where('status', whereIn: [
        BookingStatus.pending.name,
        BookingStatus.accepted.name,
        BookingStatus.onTheWay.name,
        BookingStatus.inProgress.name,
      ])
      .orderBy('scheduledAt', descending: true)
      .limit(20)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => BookingModel.fromFirestore(doc)).toList());
});

class PaginatedBookingsNotifier extends AsyncNotifier<List<BookingModel>> {
  final List<String> statuses;
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;

  PaginatedBookingsNotifier(this.statuses);

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
        .where('clientId', isEqualTo: user.uid)
        .where('status', whereIn: statuses)
        .orderBy('scheduledAt', descending: true)
        .limit(10);

    if (_lastDoc != null) {
      query = query.startAfterDocument(_lastDoc!);
    }

    final snapshot = await query.get();
    
    if (snapshot.docs.length < 10) {
      _hasMore = false;
    }
    
    if (snapshot.docs.isNotEmpty) {
      _lastDoc = snapshot.docs.last;
    }

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

final clientCompletedBookingsProvider = AsyncNotifierProvider.autoDispose<PaginatedBookingsNotifier, List<BookingModel>>(() {
  return PaginatedBookingsNotifier([BookingStatus.completed.name]);
});

final clientCancelledBookingsProvider = AsyncNotifierProvider.autoDispose<PaginatedBookingsNotifier, List<BookingModel>>(() {
  return PaginatedBookingsNotifier([BookingStatus.rejected.name, BookingStatus.cancelled.name]);
});
