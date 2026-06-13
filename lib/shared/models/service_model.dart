import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore path: services/{serviceId}

enum ServiceCategory {
  cleaning,
  plumbing,
  electrical,
  painting,
  carpentry,
  appliance,
  shifting,
  gardening,
  salon,
  hardware,
  mechanic,
  other,
}

extension ServiceCategoryExtension on ServiceCategory {
  String get displayName {
    switch (this) {
      case ServiceCategory.cleaning: return 'Cleaning';
      case ServiceCategory.plumbing: return 'Plumbing';
      case ServiceCategory.electrical: return 'Electrical';
      case ServiceCategory.painting: return 'Painting';
      case ServiceCategory.carpentry: return 'Carpentry';
      case ServiceCategory.appliance: return 'Appliance Repair';
      case ServiceCategory.shifting: return 'Moving';
      case ServiceCategory.gardening: return 'Gardening';
      case ServiceCategory.salon: return 'Salon';
      case ServiceCategory.hardware: return 'Hardware';
      case ServiceCategory.mechanic: return 'Mechanic';
      case ServiceCategory.other: return 'Other';
    }
  }
}

class ServiceModel {
  final String id;
  final String title;
  final String description;
  final ServiceCategory category;
  final double basePrice;
  final List<String> images;
  final String providerId;
  final String providerName;
  final String? providerPhoto;
  final double rating;
  final int totalReviews;
  final bool isActive;
  final String city;
  final String state;
  final DateTime createdAt;
  final DateTime updatedAt;

  ServiceModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.basePrice,
    required this.images,
    required this.providerId,
    required this.providerName,
    this.providerPhoto,
    this.rating = 0.0,
    this.totalReviews = 0,
    this.isActive = true,
    required this.city,
    required this.state,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ServiceModel.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};

    ServiceCategory parsedCategory;
    try {
      parsedCategory = ServiceCategory.values.byName(map['category'] as String? ?? 'other');
    } catch (_) {
      parsedCategory = ServiceCategory.other;
    }

    return ServiceModel(
      id: doc.id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: parsedCategory,
      basePrice: (map['basePrice'] as num?)?.toDouble() ?? 0.0,
      images: (map['images'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      providerId: map['providerId'] as String? ?? '',
      providerName: map['providerName'] as String? ?? '',
      providerPhoto: map['providerPhoto'] as String?,
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: map['totalReviews'] as int? ?? 0,
      isActive: map['isActive'] as bool? ?? true,
      city: map['city'] as String? ?? '',
      state: map['state'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.name,
      'basePrice': basePrice,
      'images': images,
      'providerId': providerId,
      'providerName': providerName,
      'providerPhoto': providerPhoto,
      'rating': rating,
      'totalReviews': totalReviews,
      'isActive': isActive,
      'city': city,
      'state': state,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  ServiceModel copyWith({
    String? id,
    String? title,
    String? description,
    ServiceCategory? category,
    double? basePrice,
    List<String>? images,
    String? providerId,
    String? providerName,
    String? providerPhoto,
    double? rating,
    int? totalReviews,
    bool? isActive,
    String? city,
    String? state,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      basePrice: basePrice ?? this.basePrice,
      images: images ?? this.images,
      providerId: providerId ?? this.providerId,
      providerName: providerName ?? this.providerName,
      providerPhoto: providerPhoto ?? this.providerPhoto,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      isActive: isActive ?? this.isActive,
      city: city ?? this.city,
      state: state ?? this.state,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
