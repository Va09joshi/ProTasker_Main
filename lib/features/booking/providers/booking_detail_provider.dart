import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/models.dart';

final bookingDetailStreamProvider = StreamProvider.autoDispose.family<BookingModel?, String>((ref, bookingId) {
  return FirebaseFirestore.instance
      .collection('bookings')
      .doc(bookingId)
      .snapshots()
      .map((doc) => doc.exists ? BookingModel.fromFirestore(doc) : null);
});

final bookingReviewProvider = FutureProvider.autoDispose.family<ReviewModel?, String>((ref, bookingId) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('reviews')
      .where('bookingId', isEqualTo: bookingId)
      .limit(1)
      .get();
  
  if (snapshot.docs.isNotEmpty) {
    return ReviewModel.fromFirestore(snapshot.docs.first);
  }
  return null;
});
