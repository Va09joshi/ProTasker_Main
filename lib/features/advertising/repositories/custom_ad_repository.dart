import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/custom_ad_model.dart';

final customAdRepositoryProvider = Provider((ref) => CustomAdRepository());

class CustomAdRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'custom_ads';

  Future<void> createAd(CustomAdModel ad) async {
    await _firestore.collection(_collection).doc(ad.id).set(ad.toMap());
  }

  Future<void> updateAd(CustomAdModel ad) async {
    await _firestore.collection(_collection).doc(ad.id).update(ad.toMap());
  }

  Future<void> deleteAd(String adId) async {
    await _firestore.collection(_collection).doc(adId).delete();
  }

  Future<void> incrementImpression(String adId) async {
    await _firestore.collection(_collection).doc(adId).update({
      'impressions': FieldValue.increment(1),
    });
  }

  Future<void> incrementClick(String adId) async {
    await _firestore.collection(_collection).doc(adId).update({
      'clicks': FieldValue.increment(1),
    });
  }

  Stream<List<CustomAdModel>> getActiveAds() {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        // Note: Firestore can only do inequality filtering on one field,
        // and we cannot easily filter where 'startDate <= now' AND 'endDate >= now' in one query.
        // So we will filter 'isActive == true' in Firestore, and do date filtering locally in the provider.
        .orderBy('priority', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CustomAdModel.fromFirestore(doc))
            .where((ad) {
              final now = DateTime.now();
              return ad.startDate.isBefore(now) && ad.endDate.isAfter(now);
            })
            .toList());
  }

  Stream<List<CustomAdModel>> getAllAds() {
    return _firestore
        .collection(_collection)
        .orderBy('priority', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => CustomAdModel.fromFirestore(doc)).toList());
  }
}
