import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';
import 'service_model.dart';

/// Firestore path: bookings/{bookingId}

enum BookingStatus {
  pending,
  proposal,
  accepted,
  rejected,
  onTheWay,
  inProgress,
  completed,
  cancelled,
}

class BookingModel {
  final String id;
  final String clientId;
  final String clientName;
  final String clientPhone;
  final String? clientPhoto;
  final String providerId;
  final String providerName;
  final String providerPhone;
  final String? providerPhoto;
  final String serviceId;
  final String serviceTitle;
  final ServiceCategory serviceCategory;
  final DateTime scheduledAt;
  final String timeSlot;
  final BookingStatus status;
  final Address address;
  final double grossPrice;
  final double platformFee;
  final double netPrice;
  final String? notes;
  final List<String> proofImages;
  final bool clientReviewed;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? otp;
  final bool isEmergency;
  final double priorityFee;

  BookingModel({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.clientPhone,
    this.clientPhoto,
    required this.providerId,
    required this.providerName,
    required this.providerPhone,
    this.providerPhoto,
    required this.serviceId,
    required this.serviceTitle,
    required this.serviceCategory,
    required this.scheduledAt,
    required this.timeSlot,
    required this.status,
    required this.address,
    required this.grossPrice,
    required this.platformFee,
    required this.netPrice,
    this.notes,
    required this.proofImages,
    this.clientReviewed = false,
    required this.createdAt,
    required this.updatedAt,
    this.otp,
    this.isEmergency = false,
    this.priorityFee = 0.0,
  });

  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};

    ServiceCategory parsedCategory;
    try {
      parsedCategory = ServiceCategory.values.byName(map['serviceCategory'] as String? ?? 'other');
    } catch (_) {
      parsedCategory = ServiceCategory.other;
    }

    BookingStatus parsedStatus;
    try {
      parsedStatus = BookingStatus.values.byName(map['status'] as String? ?? 'pending');
    } catch (_) {
      parsedStatus = BookingStatus.pending;
    }

    return BookingModel(
      id: doc.id,
      clientId: map['clientId'] as String? ?? '',
      clientName: map['clientName'] as String? ?? '',
      clientPhone: map['clientPhone'] as String? ?? '',
      clientPhoto: map['clientPhoto'] as String?,
      providerId: map['providerId'] as String? ?? '',
      providerName: map['providerName'] as String? ?? '',
      providerPhone: map['providerPhone'] as String? ?? '',
      providerPhoto: map['providerPhoto'] as String?,
      serviceId: map['serviceId'] as String? ?? '',
      serviceTitle: map['serviceTitle'] as String? ?? '',
      serviceCategory: parsedCategory,
      scheduledAt: (map['scheduledAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      timeSlot: map['timeSlot'] as String? ?? '',
      status: parsedStatus,
      address: Address.fromMap(map['address'] as Map<String, dynamic>? ?? {}),
      grossPrice: (map['grossPrice'] as num?)?.toDouble() ?? 0.0,
      platformFee: (map['platformFee'] as num?)?.toDouble() ?? 0.0,
      netPrice: (map['netPrice'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'] as String?,
      proofImages: (map['proofImages'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      clientReviewed: map['clientReviewed'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      otp: map['otp'] as String?,
      isEmergency: map['isEmergency'] as bool? ?? false,
      priorityFee: (map['priorityFee'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'clientName': clientName,
      'clientPhone': clientPhone,
      'clientPhoto': clientPhoto,
      'providerId': providerId,
      'providerName': providerName,
      'providerPhone': providerPhone,
      if (providerPhoto != null) 'providerPhoto': providerPhoto,
      'serviceId': serviceId,
      'serviceTitle': serviceTitle,
      'serviceCategory': serviceCategory.name,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'timeSlot': timeSlot,
      'status': status.name,
      'address': address.toMap(),
      'grossPrice': grossPrice,
      'platformFee': platformFee,
      'netPrice': netPrice,
      'notes': notes,
      'proofImages': proofImages,
      'clientReviewed': clientReviewed,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'otp': otp,
      'isEmergency': isEmergency,
      'priorityFee': priorityFee,
    };
  }

  BookingModel copyWith({
    String? id,
    String? clientId,
    String? clientName,
    String? clientPhone,
    String? clientPhoto,
    String? providerId,
    String? providerName,
    String? providerPhone,
    String? providerPhoto,
    String? serviceId,
    String? serviceTitle,
    ServiceCategory? serviceCategory,
    DateTime? scheduledAt,
    String? timeSlot,
    BookingStatus? status,
    Address? address,
    double? grossPrice,
    double? platformFee,
    double? netPrice,
    String? notes,
    List<String>? proofImages,
    bool? clientReviewed,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? otp,
    bool? isEmergency,
    double? priorityFee,
  }) {
    return BookingModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      clientPhoto: clientPhoto ?? this.clientPhoto,
      providerId: providerId ?? this.providerId,
      providerName: providerName ?? this.providerName,
      providerPhone: providerPhone ?? this.providerPhone,
      providerPhoto: providerPhoto ?? this.providerPhoto,
      serviceId: serviceId ?? this.serviceId,
      serviceTitle: serviceTitle ?? this.serviceTitle,
      serviceCategory: serviceCategory ?? this.serviceCategory,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      timeSlot: timeSlot ?? this.timeSlot,
      status: status ?? this.status,
      address: address ?? this.address,
      grossPrice: grossPrice ?? this.grossPrice,
      platformFee: platformFee ?? this.platformFee,
      netPrice: netPrice ?? this.netPrice,
      notes: notes ?? this.notes,
      proofImages: proofImages ?? this.proofImages,
      clientReviewed: clientReviewed ?? this.clientReviewed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      otp: otp ?? this.otp,
      isEmergency: isEmergency ?? this.isEmergency,
      priorityFee: priorityFee ?? this.priorityFee,
    );
  }
}
