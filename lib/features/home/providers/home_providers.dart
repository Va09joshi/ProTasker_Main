import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
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
  
  final userLat = user.address.lat;
  final userLng = user.address.lng;

  return FirebaseFirestore.instance
      .collection('users')
      .where('role', isEqualTo: 'provider')
      .snapshots()
      .map((snapshot) {
        final providers = snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
        
        final filteredProviders = providers.where((provider) {
          final hasUserCoords = userLat != 0.0 && userLng != 0.0;
          final hasProviderCoords = provider.address.lat != 0.0 && provider.address.lng != 0.0;
          
          if (hasUserCoords && hasProviderCoords) {
            final distance = Geolocator.distanceBetween(
              userLat,
              userLng,
              provider.address.lat,
              provider.address.lng,
            );
            return distance <= 50000; // 50km radius
          }
          return false; // Only real location-based filtering
        }).toList();

        filteredProviders.sort((a, b) {
          final hasUserCoords = userLat != 0.0 && userLng != 0.0;
          final hasACoords = a.address.lat != 0.0 && a.address.lng != 0.0;
          final hasBCoords = b.address.lat != 0.0 && b.address.lng != 0.0;

          if (hasUserCoords && hasACoords && hasBCoords) {
            final distA = Geolocator.distanceBetween(userLat, userLng, a.address.lat, a.address.lng);
            final distB = Geolocator.distanceBetween(userLat, userLng, b.address.lat, b.address.lng);
            return distA.compareTo(distB);
          }
          return 0; // If coordinates missing, keep original order
        });

        return filteredProviders.take(10).toList();
      });
});
