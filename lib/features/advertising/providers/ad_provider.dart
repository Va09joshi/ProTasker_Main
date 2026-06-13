import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/ad_model.dart';

final adProvider = StreamProvider<List<AdModel>>((ref) {
  final firestore = FirebaseFirestore.instance;
  
  return firestore
      .collection('ads')
      .where('isActive', isEqualTo: true)
      .orderBy('createdAt', descending: true)
      .limit(10)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => AdModel.fromFirestore(doc)).toList();
  });
});
