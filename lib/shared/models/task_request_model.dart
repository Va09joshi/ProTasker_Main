import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskRequestStatus {
  open,
  assigned,
  completed,
  cancelled,
}

class TaskRequestModel {
  final String id;
  final String clientId;
  final String clientName;
  final String title;
  final String description;
  final double latitude;
  final double longitude;
  final TaskRequestStatus status;
  final String? assignedProviderId;
  final DateTime createdAt;
  final DateTime updatedAt;

  TaskRequestModel({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.title,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.status,
    this.assignedProviderId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TaskRequestModel.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};

    TaskRequestStatus parsedStatus;
    try {
      parsedStatus = TaskRequestStatus.values.byName(map['status'] as String? ?? 'open');
    } catch (_) {
      parsedStatus = TaskRequestStatus.open;
    }

    return TaskRequestModel(
      id: doc.id,
      clientId: map['clientId'] as String? ?? '',
      clientName: map['clientName'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      status: parsedStatus,
      assignedProviderId: map['assignedProviderId'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'clientName': clientName,
      'title': title,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'status': status.name,
      if (assignedProviderId != null) 'assignedProviderId': assignedProviderId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  TaskRequestModel copyWith({
    String? id,
    String? clientId,
    String? clientName,
    String? title,
    String? description,
    double? latitude,
    double? longitude,
    TaskRequestStatus? status,
    String? assignedProviderId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskRequestModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      title: title ?? this.title,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      assignedProviderId: assignedProviderId ?? this.assignedProviderId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
