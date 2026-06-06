import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/booking_model.dart';

final bookingRepositoryProvider = Provider((ref) => BookingRepository());

class BookingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'bookings';

  Future<void> createBooking(BookingModel booking) async {
    await _firestore.collection(_collection).doc(booking.id).set(booking.toMap());
  }

  Future<void> updateBookingStatus(String bookingId, BookingStatus status) async {
    await _firestore.collection(_collection).doc(bookingId).update({'status': status.name});
  }

  Stream<BookingModel?> getBookingById(String bookingId) {
    return _firestore.collection(_collection).doc(bookingId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return BookingModel.fromFirestore(snapshot);
    });
  }

  Future<void> acceptProposal(String acceptedBookingId, String jobId) async {
    final batch = _firestore.batch();

    // Fetch all pending bookings for this job
    final pendingBookings = await _firestore.collection(_collection)
        .where('serviceId', isEqualTo: jobId)
        .where('status', isEqualTo: BookingStatus.pending.name)
        .get();

    for (var doc in pendingBookings.docs) {
      if (doc.id == acceptedBookingId) {
        batch.update(doc.reference, {'status': BookingStatus.accepted.name});
      } else {
        batch.update(doc.reference, {'status': BookingStatus.rejected.name});
      }
    }

    // Update job status to 'in_progress'
    final jobRef = _firestore.collection('jobs').doc(jobId);
    batch.update(jobRef, {'status': 'in_progress'});

    await batch.commit();
  }
}
