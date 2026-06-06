import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/models.dart';

final serviceDetailProvider = FutureProvider.autoDispose.family<ServiceModel?, String>((ref, serviceId) async {
  final doc = await FirebaseFirestore.instance.collection('services').doc(serviceId).get();
  if (doc.exists) {
    return ServiceModel.fromFirestore(doc);
  }
  return null;
});

final serviceReviewsProvider = StreamProvider.autoDispose.family<List<ReviewModel>, String>((ref, serviceId) {
  return FirebaseFirestore.instance
      .collection('reviews')
      .where('serviceId', isEqualTo: serviceId)
      .orderBy('createdAt', descending: true)
      .limit(5)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => ReviewModel.fromFirestore(doc)).toList());
});

final similarServicesProvider = FutureProvider.autoDispose.family<List<ServiceModel>, ServiceModel>((ref, service) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('services')
      .where('isActive', isEqualTo: true)
      .where('city', isEqualTo: service.city)
      .where('category', isEqualTo: service.category.name)
      .where(FieldPath.documentId, isNotEqualTo: service.id)
      .limit(5)
      .get();
      
  return snapshot.docs.map((doc) => ServiceModel.fromFirestore(doc)).toList();
});

final providerProfileProvider = FutureProvider.autoDispose.family<UserModel?, String>((ref, providerId) async {
  final doc = await FirebaseFirestore.instance.collection('users').doc(providerId).get();
  if (doc.exists) return UserModel.fromFirestore(doc);
  return null;
});
