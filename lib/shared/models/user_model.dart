import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore path: users/{uid}

enum UserRole {
  client,
  provider,
}

class Address {
  final String street;
  final String city;
  final String state;
  final String pincode;
  final double lat;
  final double lng;

  Address({
    required this.street,
    required this.city,
    required this.state,
    required this.pincode,
    required this.lat,
    required this.lng,
  });

  factory Address.fromMap(Map<String, dynamic> map) {
    return Address(
      street: map['street'] as String? ?? '',
      city: map['city'] as String? ?? '',
      state: map['state'] as String? ?? '',
      pincode: map['pincode'] as String? ?? '',
      lat: (map['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'street': street,
      'city': city,
      'state': state,
      'pincode': pincode,
      'lat': lat,
      'lng': lng,
    };
  }
}

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String? profilePhoto;
  final UserRole role;
  final Address address;
  final double rating;
  final int totalJobs;
  final int totalReviews;
  final bool isVerified;
  final bool isOnline;
  final bool profileComplete;
  final String? fcmToken;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String>? interestedServices;
  final List<String>? offeredServices;
  final String? experienceYears;
  final String? bio;
  final String? idProof;
  final List<String>? serviceAreas;
  final List<String>? portfolioImages;
  final Map<String, dynamic>? availabilitySchedule;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    this.profilePhoto,
    required this.role,
    required this.address,
    this.rating = 0.0,
    this.totalJobs = 0,
    this.totalReviews = 0,
    this.isVerified = false,
    this.isOnline = false,
    this.profileComplete = false,
    this.fcmToken,
    required this.createdAt,
    required this.updatedAt,
    this.interestedServices,
    this.offeredServices,
    this.experienceYears,
    this.bio,
    this.idProof,
    this.serviceAreas,
    this.portfolioImages,
    this.availabilitySchedule,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};

    return UserModel(
      uid: doc.id,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      profilePhoto: map['profilePhoto'] as String?,
      role: map['role'] == 'provider' ? UserRole.provider : UserRole.client,
      address: Address.fromMap(map['address'] as Map<String, dynamic>? ?? {}),
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      totalJobs: map['totalJobs'] as int? ?? 0,
      totalReviews: map['totalReviews'] as int? ?? 0,
      isVerified: map['isVerified'] as bool? ?? false,
      isOnline: map['isOnline'] as bool? ?? false,
      profileComplete: map['profileComplete'] as bool? ?? false,
      fcmToken: map['fcmToken'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      interestedServices: (map['interestedServices'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      offeredServices: (map['offeredServices'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      experienceYears: map['experienceYears'] as String?,
      bio: map['bio'] as String?,
      idProof: map['idProof'] as String?,
      serviceAreas: (map['serviceAreas'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      portfolioImages: (map['portfolioImages'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      availabilitySchedule: map['availabilitySchedule'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'profilePhoto': profilePhoto,
      'role': role == UserRole.provider ? 'provider' : 'client',
      'address': address.toMap(),
      'rating': rating,
      'totalJobs': totalJobs,
      'totalReviews': totalReviews,
      'isVerified': isVerified,
      'isOnline': isOnline,
      'profileComplete': profileComplete,
      'fcmToken': fcmToken,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (interestedServices != null) 'interestedServices': interestedServices,
      if (offeredServices != null) 'offeredServices': offeredServices,
      if (experienceYears != null) 'experienceYears': experienceYears,
      if (bio != null) 'bio': bio,
      if (idProof != null) 'idProof': idProof,
      if (serviceAreas != null) 'serviceAreas': serviceAreas,
      if (portfolioImages != null) 'portfolioImages': portfolioImages,
      if (availabilitySchedule != null) 'availabilitySchedule': availabilitySchedule,
    };
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? profilePhoto,
    UserRole? role,
    Address? address,
    double? rating,
    int? totalJobs,
    int? totalReviews,
    bool? isVerified,
    bool? isOnline,
    bool? profileComplete,
    String? fcmToken,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? interestedServices,
    List<String>? offeredServices,
    String? experienceYears,
    String? bio,
    String? idProof,
    List<String>? serviceAreas,
    List<String>? portfolioImages,
    Map<String, dynamic>? availabilitySchedule,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      role: role ?? this.role,
      address: address ?? this.address,
      rating: rating ?? this.rating,
      totalJobs: totalJobs ?? this.totalJobs,
      totalReviews: totalReviews ?? this.totalReviews,
      isVerified: isVerified ?? this.isVerified,
      isOnline: isOnline ?? this.isOnline,
      profileComplete: profileComplete ?? this.profileComplete,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      interestedServices: interestedServices ?? this.interestedServices,
      offeredServices: offeredServices ?? this.offeredServices,
      experienceYears: experienceYears ?? this.experienceYears,
      bio: bio ?? this.bio,
      idProof: idProof ?? this.idProof,
      serviceAreas: serviceAreas ?? this.serviceAreas,
      portfolioImages: portfolioImages ?? this.portfolioImages,
      availabilitySchedule: availabilitySchedule ?? this.availabilitySchedule,
    );
  }
}
