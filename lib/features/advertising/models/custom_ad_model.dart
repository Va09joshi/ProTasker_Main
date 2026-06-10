import 'package:cloud_firestore/cloud_firestore.dart';

class CustomAdModel {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String targetUrl;
  final bool isActive;
  final int priority;
  final DateTime startDate;
  final DateTime endDate;
  final int impressions;
  final int clicks;

  CustomAdModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.targetUrl,
    this.isActive = true,
    this.priority = 0,
    required this.startDate,
    required this.endDate,
    this.impressions = 0,
    this.clicks = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'targetUrl': targetUrl,
      'isActive': isActive,
      'priority': priority,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'impressions': impressions,
      'clicks': clicks,
    };
  }

  factory CustomAdModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return CustomAdModel(
      id: data['id'] ?? doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      targetUrl: data['targetUrl'] ?? '',
      isActive: data['isActive'] ?? false,
      priority: data['priority'] ?? 0,
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 30)),
      impressions: data['impressions'] ?? 0,
      clicks: data['clicks'] ?? 0,
    );
  }

  CustomAdModel copyWith({
    String? title,
    String? description,
    String? imageUrl,
    String? targetUrl,
    bool? isActive,
    int? priority,
    DateTime? startDate,
    DateTime? endDate,
    int? impressions,
    int? clicks,
  }) {
    return CustomAdModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      targetUrl: targetUrl ?? this.targetUrl,
      isActive: isActive ?? this.isActive,
      priority: priority ?? this.priority,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      impressions: impressions ?? this.impressions,
      clicks: clicks ?? this.clicks,
    );
  }
}
