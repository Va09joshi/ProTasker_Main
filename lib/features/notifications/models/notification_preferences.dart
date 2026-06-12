import 'dart:convert';

class NotificationPreferences {
  final bool globalEnabled;
  final bool chat;
  final bool bookings;
  final bool providerAccepted;
  final bool providerArrived;
  final bool serviceStarted;
  final bool serviceCompleted;
  final bool payments;
  final bool promotions;
  final bool announcements;
  final bool marketing;
  
  // Advanced
  final bool quietHoursEnabled;
  final String quietHoursStart;
  final String quietHoursEnd;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool badgeCountEnabled;
  final String deliveryMode; // 'instant' or 'summary'

  const NotificationPreferences({
    this.globalEnabled = true,
    this.chat = true,
    this.bookings = true,
    this.providerAccepted = true,
    this.providerArrived = true,
    this.serviceStarted = true,
    this.serviceCompleted = true,
    this.payments = true,
    this.promotions = false,
    this.announcements = true,
    this.marketing = false,
    this.quietHoursEnabled = false,
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '07:00',
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.badgeCountEnabled = true,
    this.deliveryMode = 'instant',
  });

  NotificationPreferences copyWith({
    bool? globalEnabled,
    bool? chat,
    bool? bookings,
    bool? providerAccepted,
    bool? providerArrived,
    bool? serviceStarted,
    bool? serviceCompleted,
    bool? payments,
    bool? promotions,
    bool? announcements,
    bool? marketing,
    bool? quietHoursEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? badgeCountEnabled,
    String? deliveryMode,
  }) {
    return NotificationPreferences(
      globalEnabled: globalEnabled ?? this.globalEnabled,
      chat: chat ?? this.chat,
      bookings: bookings ?? this.bookings,
      providerAccepted: providerAccepted ?? this.providerAccepted,
      providerArrived: providerArrived ?? this.providerArrived,
      serviceStarted: serviceStarted ?? this.serviceStarted,
      serviceCompleted: serviceCompleted ?? this.serviceCompleted,
      payments: payments ?? this.payments,
      promotions: promotions ?? this.promotions,
      announcements: announcements ?? this.announcements,
      marketing: marketing ?? this.marketing,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      badgeCountEnabled: badgeCountEnabled ?? this.badgeCountEnabled,
      deliveryMode: deliveryMode ?? this.deliveryMode,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'globalEnabled': globalEnabled,
      'chat': chat,
      'bookings': bookings,
      'providerAccepted': providerAccepted,
      'providerArrived': providerArrived,
      'serviceStarted': serviceStarted,
      'serviceCompleted': serviceCompleted,
      'payments': payments,
      'promotions': promotions,
      'announcements': announcements,
      'marketing': marketing,
      'quietHoursEnabled': quietHoursEnabled,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'badgeCountEnabled': badgeCountEnabled,
      'deliveryMode': deliveryMode,
    };
  }

  factory NotificationPreferences.fromMap(Map<String, dynamic> map) {
    return NotificationPreferences(
      globalEnabled: map['globalEnabled'] ?? true,
      chat: map['chat'] ?? true,
      bookings: map['bookings'] ?? true,
      providerAccepted: map['providerAccepted'] ?? true,
      providerArrived: map['providerArrived'] ?? true,
      serviceStarted: map['serviceStarted'] ?? true,
      serviceCompleted: map['serviceCompleted'] ?? true,
      payments: map['payments'] ?? true,
      promotions: map['promotions'] ?? false,
      announcements: map['announcements'] ?? true,
      marketing: map['marketing'] ?? false,
      quietHoursEnabled: map['quietHoursEnabled'] ?? false,
      quietHoursStart: map['quietHoursStart'] ?? '22:00',
      quietHoursEnd: map['quietHoursEnd'] ?? '07:00',
      soundEnabled: map['soundEnabled'] ?? true,
      vibrationEnabled: map['vibrationEnabled'] ?? true,
      badgeCountEnabled: map['badgeCountEnabled'] ?? true,
      deliveryMode: map['deliveryMode'] ?? 'instant',
    );
  }

  String toJson() => json.encode(toMap());

  factory NotificationPreferences.fromJson(String source) => NotificationPreferences.fromMap(json.decode(source));
}
