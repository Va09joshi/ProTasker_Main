import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/user_session_provider.dart';
import '../models/job_post.dart';
import '../repositories/job_repository.dart';
import '../../../core/services/location_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/models/user_model.dart';
import '../../../core/services/cloudinary_service.dart';
import '../../../shared/models/booking_model.dart';

final jobProvider = AsyncNotifierProvider<JobNotifier, void>(() {
  return JobNotifier();
});

class JobNotifier extends AsyncNotifier<void> {
  JobRepository get _repository => ref.read(jobRepositoryProvider);

  @override
  Future<void> build() async {
    return;
  }

  Future<bool> postJob(String title, String description, String category, {List<File>? images}) async {
    state = const AsyncLoading();
    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) throw Exception('User not logged in');

      final position = await LocationService.getCurrentLocation();
      if (position == null) {
        throw Exception('Location permission is required to post a problem');
      }

      List<String> imageUrls = [];
      if (images != null && images.isNotEmpty) {
        for (var image in images) {
          final url = await CloudinaryService.uploadFile(image);
          if (url != null) {
            imageUrls.add(url);
          }
        }
      }

      final job = JobPost(
        id: '', // Firestore auto-generates
        clientId: user.uid,
        title: title,
        description: description,
        category: category,
        latitude: position.latitude,
        longitude: position.longitude,
        createdAt: DateTime.now(),
        imageUrls: imageUrls,
      );

      await _repository.createJob(job);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

// Feed provider for providers to see open jobs
final jobFeedProvider = StreamProvider<List<JobPost>>((ref) {
  final repo = ref.read(jobRepositoryProvider);
  return repo.getOpenJobs();
});

// Calculate distance provider
final distanceProvider = Provider.family<AsyncValue<double>, JobPost>((ref, job) {
  // We can fetch user location and compute distance
  // But doing async operations in a family provider like this can be tricky.
  // Instead, we can expose a FutureProvider
  return const AsyncValue.loading();
});

final jobDistanceProvider = FutureProvider.family<double?, JobPost>((ref, job) async {
  final position = await LocationService.getCurrentLocation();
  if (position == null) return null;
  
  return LocationService.calculateDistanceInKm(
    position.latitude, 
    position.longitude, 
    job.latitude, 
    job.longitude
  );
});

final jobDetailProvider = StreamProvider.family<JobPost?, String>((ref, jobId) {
  final repo = ref.read(jobRepositoryProvider);
  return repo.getJobById(jobId);
});

final jobClientProvider = StreamProvider.family<UserModel?, String>((ref, clientId) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(clientId)
      .snapshots()
      .map((snapshot) => snapshot.exists ? UserModel.fromFirestore(snapshot) : null);
});

final jobProposalsProvider = StreamProvider.family<List<BookingModel>, String>((ref, jobId) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('bookings')
      .where('clientId', isEqualTo: user.uid)
      .where('serviceId', isEqualTo: jobId)
      .where('status', isEqualTo: BookingStatus.proposal.name)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => BookingModel.fromFirestore(doc)).toList());
});

final jobAcceptedBookingProvider = StreamProvider.family<BookingModel?, String>((ref, jobId) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('bookings')
      .where('clientId', isEqualTo: user.uid)
      .where('serviceId', isEqualTo: jobId)
      .where('status', whereIn: [
        BookingStatus.accepted.name,
        BookingStatus.onTheWay.name,
        BookingStatus.inProgress.name,
        BookingStatus.completed.name,
      ])
      .limit(1)
      .snapshots()
      .map((snapshot) => snapshot.docs.isNotEmpty ? BookingModel.fromFirestore(snapshot.docs.first) : null);
});
