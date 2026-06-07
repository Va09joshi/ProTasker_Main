import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../shared/models/models.dart';
import '../../../shared/providers/user_session_provider.dart';

final categoryProvidersProvider = StreamProvider.autoDispose.family<List<UserModel>, String>((ref, categoryName) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value([]);
  
  final userLat = user.address.lat;
  final userLng = user.address.lng;

  return FirebaseFirestore.instance
      .collection('users')
      .where('role', isEqualTo: 'provider')
      .where('offeredServices', arrayContains: categoryName)
      .snapshots()
      .map((snapshot) {
        final providers = snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
        
        final filteredProviders = providers.where((provider) {
          final hasUserCoords = userLat != 0.0 && userLng != 0.0;
          final hasProviderCoords = provider.address.lat != 0.0 && provider.address.lng != 0.0;
          if (!hasUserCoords || !hasProviderCoords) return false;

          final distance = Geolocator.distanceBetween(
            userLat,
            userLng,
            provider.address.lat,
            provider.address.lng,
          );
          return distance <= 50000; // 50km radius
        }).toList();

        filteredProviders.sort((a, b) {
          final distA = Geolocator.distanceBetween(userLat, userLng, a.address.lat, a.address.lng);
          final distB = Geolocator.distanceBetween(userLat, userLng, b.address.lat, b.address.lng);
          return distA.compareTo(distB);
        });

        return filteredProviders;
      });
});
