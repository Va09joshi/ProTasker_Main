import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/user_session_provider.dart';
import '../../../shared/models/models.dart';
import 'service_filter_provider.dart';

final paginatedServicesProvider = FutureProvider.autoDispose.family<List<ServiceModel>, ServiceCategory?>((ref, category) async {
  final user = ref.read(currentUserProvider).value;
  if (user == null || user.address.city.isEmpty) return [];

  final filterState = ref.watch(serviceFilterProvider);

  var query = FirebaseFirestore.instance
      .collection('services')
      .where('isActive', isEqualTo: true)
      .where('city', isEqualTo: user.address.city);

  if (filterState.category != null) {
    query = query.where('category', isEqualTo: filterState.category!.name);
  }

  if (filterState.sort == ServiceSort.topRated) {
    query = query.orderBy('rating', descending: true);
  } else if (filterState.sort == ServiceSort.priceHighToLow) {
    query = query.orderBy('basePrice', descending: true);
  } else if (filterState.sort == ServiceSort.priceLowToHigh) {
    query = query.orderBy('basePrice', descending: false);
  }

  final snapshot = await query.limit(50).get(); // Fetch up to 50 for simplicity instead of complex pagination
  
  List<ServiceModel> results = [];
  for (var doc in snapshot.docs) {
    final service = ServiceModel.fromFirestore(doc);
    if (service.basePrice >= filterState.minPrice && 
        service.basePrice <= filterState.maxPrice && 
        service.rating >= filterState.minRating) {
      results.add(service);
    }
  }

  return results;
});
