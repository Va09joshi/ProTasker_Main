import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../shared/providers/user_session_provider.dart';
import '../../../shared/models/models.dart';

enum EarningsPeriod { thisWeek, thisMonth, allTime }

class EarningsPeriodNotifier extends Notifier<EarningsPeriod> {
  @override
  EarningsPeriod build() => EarningsPeriod.thisWeek;
  void updatePeriod(EarningsPeriod period) => state = period;
}
final earningsPeriodProvider = NotifierProvider<EarningsPeriodNotifier, EarningsPeriod>(EarningsPeriodNotifier.new);

class EarningsSummary {
  final double grossEarnings;
  final double platformFee;
  final double netEarnings;
  final int jobsCompleted;

  EarningsSummary({
    required this.grossEarnings,
    required this.platformFee,
    required this.netEarnings,
    required this.jobsCompleted,
  });
}

class ChartData {
  final String label;
  final double value;
  ChartData(this.label, this.value);
}

class EarningsData {
  final EarningsSummary summary;
  final List<ChartData> chartData;
  EarningsData(this.summary, this.chartData);
}

final providerEarningsDataProvider = FutureProvider.autoDispose<EarningsData>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) {
    return EarningsData(EarningsSummary(grossEarnings: 0, platformFee: 0, netEarnings: 0, jobsCompleted: 0), []);
  }

  final period = ref.watch(earningsPeriodProvider);
  final now = DateTime.now();

  var query = FirebaseFirestore.instance
      .collection('bookings')
      .where('providerId', isEqualTo: user.uid)
      .where('status', isEqualTo: BookingStatus.completed.name)
      .orderBy('updatedAt', descending: true);

  final snapshot = await query.get();

  double gross = 0;
  double net = 0;
  double fee = 0;
  int count = 0;

  List<BookingModel> filtered = [];

  for (var doc in snapshot.docs) {
    final b = BookingModel.fromFirestore(doc);
    if (period == EarningsPeriod.thisWeek) {
      final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
      if (b.updatedAt.isAfter(startOfWeek)) filtered.add(b);
    } else if (period == EarningsPeriod.thisMonth) {
      final startOfMonth = DateTime(now.year, now.month, 1);
      if (b.updatedAt.isAfter(startOfMonth)) filtered.add(b);
    } else {
      filtered.add(b);
    }
  }

  for (var b in filtered) {
    gross += b.grossPrice;
    net += b.netPrice;
    fee += b.platformFee;
    count++;
  }

  List<ChartData> chart = [];
  if (period == EarningsPeriod.thisWeek) {
    final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    for (int i = 0; i < 7; i++) {
      final day = startOfWeek.add(Duration(days: i));
      final label = DateFormat('E').format(day);
      double dayTotal = 0;
      for (var b in filtered) {
        if (b.updatedAt.year == day.year && b.updatedAt.month == day.month && b.updatedAt.day == day.day) {
          dayTotal += b.netPrice;
        }
      }
      chart.add(ChartData(label, dayTotal));
    }
  } else if (period == EarningsPeriod.thisMonth) {
    for (int i = 0; i < 4; i++) {
      double weekTotal = 0;
      for (var b in filtered) {
        int weekOfMonth = ((b.updatedAt.day - 1) / 7).floor();
        if (weekOfMonth == i) weekTotal += b.netPrice;
      }
      chart.add(ChartData('W${i+1}', weekTotal));
    }
  } else {
    for (int i = 1; i <= 12; i++) {
      double monthTotal = 0;
      for (var b in filtered) {
        if (b.updatedAt.month == i && b.updatedAt.year == now.year) {
          monthTotal += b.netPrice;
        }
      }
      chart.add(ChartData(DateFormat('MMM').format(DateTime(now.year, i)), monthTotal));
    }
  }

  return EarningsData(
    EarningsSummary(grossEarnings: gross, platformFee: fee, netEarnings: net, jobsCompleted: count),
    chart,
  );
});

class EarningsHistoryNotifier extends AsyncNotifier<List<BookingModel>> {
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
        .where('status', isEqualTo: BookingStatus.completed.name)
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

final earningsHistoryProvider = AsyncNotifierProvider.autoDispose<EarningsHistoryNotifier, List<BookingModel>>(() {
  return EarningsHistoryNotifier();
});
