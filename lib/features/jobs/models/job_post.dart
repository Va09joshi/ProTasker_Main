import 'package:cloud_firestore/cloud_firestore.dart';

class JobPost {
  final String id;
  final String clientId;
  final String title;
  final String description;
  final String category;
  final double latitude;
  final double longitude;
  final String status; // 'open', 'in_progress', 'completed'
  final DateTime createdAt;
  final List<String> imageUrls; // Optional images describing the problem
  final double? budget;

  JobPost({
    required this.id,
    required this.clientId,
    required this.title,
    required this.description,
    required this.category,
    required this.latitude,
    required this.longitude,
    this.status = 'open',
    required this.createdAt,
    this.imageUrls = const [],
    this.budget,
  });

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'title': title,
      'description': description,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'imageUrls': imageUrls,
      if (budget != null) 'budget': budget,
    };
  }

  factory JobPost.fromMap(Map<String, dynamic> map, String documentId) {
    return JobPost(
      id: documentId,
      clientId: map['clientId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'open',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      budget: (map['budget'] as num?)?.toDouble(),
    );
  }
}
