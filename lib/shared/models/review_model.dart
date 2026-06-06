import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore path: reviews/{reviewId}

class ReviewModel {
  final String id;
  final String bookingId;
  final String serviceId;
  final String reviewerId;
  final String reviewerName;
  final String? reviewerPhoto;
  final String providerId;
  final double rating;
  final String comment;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.bookingId,
    required this.serviceId,
    required this.reviewerId,
    required this.reviewerName,
    this.reviewerPhoto,
    required this.providerId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};

    return ReviewModel(
      id: doc.id,
      bookingId: map['bookingId'] as String? ?? '',
      serviceId: map['serviceId'] as String? ?? '',
      reviewerId: map['reviewerId'] as String? ?? '',
      reviewerName: map['reviewerName'] as String? ?? '',
      reviewerPhoto: map['reviewerPhoto'] as String?,
      providerId: map['providerId'] as String? ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      comment: map['comment'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookingId': bookingId,
      'serviceId': serviceId,
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'reviewerPhoto': reviewerPhoto,
      'providerId': providerId,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  ReviewModel copyWith({
    String? id,
    String? bookingId,
    String? serviceId,
    String? reviewerId,
    String? reviewerName,
    String? reviewerPhoto,
    String? providerId,
    double? rating,
    String? comment,
    DateTime? createdAt,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      serviceId: serviceId ?? this.serviceId,
      reviewerId: reviewerId ?? this.reviewerId,
      reviewerName: reviewerName ?? this.reviewerName,
      reviewerPhoto: reviewerPhoto ?? this.reviewerPhoto,
      providerId: providerId ?? this.providerId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
