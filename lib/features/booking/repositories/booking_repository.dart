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

  Future<void> acceptProposal(String acceptedBookingId, String jobId, String clientId) async {
    final jobRef = _firestore.collection('jobs').doc(jobId);
    
    // Query pending bookings before transaction to get their references
    final pendingBookingsQuery = await _firestore.collection(_collection)
        .where('clientId', isEqualTo: clientId)
        .where('serviceId', isEqualTo: jobId)
        .where('status', isEqualTo: BookingStatus.proposal.name)
        .get();

    await _firestore.runTransaction((transaction) async {
      final jobDoc = await transaction.get(jobRef);
      if (!jobDoc.exists) throw Exception('Job not found');
      if (jobDoc.data()?['status'] != 'open') {
        throw Exception('This job is no longer open or has already been assigned.');
      }

      // Find the accepted booking doc to extract provider info if needed
      // (For now just updating status)
      
      for (var doc in pendingBookingsQuery.docs) {
        if (doc.id == acceptedBookingId) {
          transaction.update(doc.reference, {'status': BookingStatus.accepted.name});
        } else {
          transaction.delete(doc.reference);
        }
      }

      // Update job status
      transaction.update(jobRef, {
        'status': 'in_progress',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
