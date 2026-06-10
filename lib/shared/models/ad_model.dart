import 'package:cloud_firestore/cloud_firestore.dart';

class AdModel {
  final String id;
  final String businessName;
  final String? imageUrl;
  final String? targetUrl;
  final String? description;
  final String category; // e.g., 'hardware', 'paint', 'appliances'
  final bool isActive;
  final DateTime createdAt;

  AdModel({
    required this.id,
    required this.businessName,
    this.imageUrl,
    this.targetUrl,
    this.description,
    required this.category,
    this.isActive = true,
    required this.createdAt,
  });

  factory AdModel.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};
    return AdModel(
      id: doc.id,
      businessName: map['businessName'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
      targetUrl: map['targetUrl'] as String?,
      description: map['description'] as String?,
      category: map['category'] as String? ?? 'other',
      isActive: map['isActive'] as bool? ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'businessName': businessName,
      'imageUrl': imageUrl,
      'targetUrl': targetUrl,
      'description': description,
      'category': category,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  AdModel copyWith({
    String? id,
    String? businessName,
    String? imageUrl,
    String? targetUrl,
    String? description,
    String? category,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return AdModel(
      id: id ?? this.id,
      businessName: businessName ?? this.businessName,
      imageUrl: imageUrl ?? this.imageUrl,
      targetUrl: targetUrl ?? this.targetUrl,
      description: description ?? this.description,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
